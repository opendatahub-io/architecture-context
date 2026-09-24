"""Agent harness launcher and model utilities."""

from __future__ import annotations

import asyncio
import hashlib
import os
import re
import shutil
import subprocess
import tempfile
import time
from collections import Counter
from functools import lru_cache
from pathlib import Path
from typing import TYPE_CHECKING

from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ClaudeSDKClient,
    HookMatcher,
    RateLimitEvent,
    ResultMessage,
)

from lib.context_telemetry import ContextTelemetryCollector, dependency_observations
from lib.strace_transport import StracedTransport, empty_async_iter

if TYPE_CHECKING:
    from lib.context_telemetry import ContextExporter
    from lib.progress import AgentProgress

_NAVIGATION_FILES = frozenset({
    "analyzer_architecture.md",
    "GENERATED_ARCHITECTURE.md",
    "ARCHITECTURE_CHANGES.md",
    "ARCHITECTURE_PATCH.json",
    "component-architecture.json",
    "analyzer_synthesis_context.md",
})

_AGENT_OUTPUT_FILES = frozenset({
    "GENERATED_ARCHITECTURE.md",
    "ARCHITECTURE_CHANGES.md",
    "ARCHITECTURE_PATCH.json",
    "INSIGHTS_ARTIFACT.json",
    "SOURCE_READ_JUSTIFICATIONS.json",
})

_PRIOR_ARCHITECTURE_DIR = "architecture"
_REPO_ROOT = Path(__file__).resolve().parent.parent
_TRUSTED_SKILL_ROOT = _REPO_ROOT / ".claude" / "skills" / "repo-to-architecture-summary"
_PARTIAL_MAX_SOURCE_READ_LINES = 400
_PARTIAL_MAX_DISCOVERY_RESULTS = 20
_AVOIDABLE_WORKFLOW_DENIAL_TOOLS = frozenset({"TodoWrite"})
_PARTIAL_TARGETED_GLOB_HINT = (
    "Use targeted patterns such as **/kustomization.yaml, "
    "charts/**/Chart.yaml, charts/**/values.yaml, "
    "charts/**/templates/**/*.yaml, components/**/kustomization.yaml, "
    "or configurations/**/kustomization.yaml."
)
_CLAUDE_AUTH_CONFIG_ENV = "CLAUDE_AUTH_CONFIG_DIR"
_CLAUDE_CREDENTIALS_FILE = ".credentials.json"


def _stage_claude_credentials(config_dir: Path) -> bool:
    """Copy only explicitly selected first-party credentials into config_dir."""
    source_config = os.environ.get(_CLAUDE_AUTH_CONFIG_ENV)
    if not source_config:
        return False
    source = Path(source_config).expanduser() / _CLAUDE_CREDENTIALS_FILE
    if not source.is_file():
        return False
    destination = config_dir / _CLAUDE_CREDENTIALS_FILE
    if source.resolve() == destination.resolve():
        destination.chmod(0o600)
        return True
    shutil.copyfile(source, destination)
    destination.chmod(0o600)
    return True


class _AgentExecutionGuard:
    """Enforce a readiness policy and collect per-agent tool telemetry."""

    def __init__(
        self,
        policy: dict | None,
        checkout_path: str | Path | None,
        *,
        analyzer_root: str | Path | None = None,
        input_paths: tuple[str | Path, ...] = (),
        output_paths: tuple[str | Path, ...] = (),
        context_exporter: ContextExporter | None = None,
    ):
        self.policy = policy or {"route": "legacy"}
        self.checkout = (
            Path(checkout_path).resolve() if checkout_path is not None else None
        )
        self.analyzer_root = (
            Path(analyzer_root).resolve() if analyzer_root is not None else None
        )
        self._direct_output_mode = bool(output_paths)
        self._allowed_input_paths = {Path(path).resolve() for path in input_paths}
        self._allowed_output_paths = {
            Path(path).resolve() for path in output_paths
        }
        self._primary_output_path = (
            Path(output_paths[0]).resolve() if output_paths else None
        )
        if not self._allowed_output_paths and self.checkout is not None:
            self._allowed_output_paths = {
                self.checkout / name for name in _AGENT_OUTPUT_FILES
            }
            self._primary_output_path = self.checkout / "GENERATED_ARCHITECTURE.md"
        # Restricted agents may read the architecture-summary skill's
        # instructions, templates, and references. This is deliberately a
        # separate read-only root: skill documentation does not become source
        # evidence, does not consume the component file budget, and cannot be
        # written through the agent guard.
        self._trusted_read_roots = (_TRUSTED_SKILL_ROOT.resolve(),)
        self.tool_calls: Counter[str] = Counter()
        self.tool_call_categories: Counter[str] = Counter()
        self.denied_calls: Counter[str] = Counter()
        self.denied_call_categories: Counter[str] = Counter()
        self.read_calls = 0
        self.source_read_operations = 0
        self.source_reads: list[str] = []
        self.source_read_ranges: list[dict[str, object]] = []
        self.search_observations: list[dict[str, object]] = []
        self.unclassified_source_commands: list[str] = []
        self._source_read_set: set[str] = set()
        self._discovery_calls: Counter[str] = Counter()
        self.source_read_budget_exceeded = 0
        self.source_read_budget_exceeded_files: list[str] = []
        self.discovery_budget_exceeded = 0
        source_files = self.policy.get("source_files", ())
        self._allowed_sources = {
            (self.checkout / path).resolve()
            for path in source_files
            if self.checkout is not None
        }
        component = str(self.policy.get("component", ""))
        self.ctx_telemetry = ContextTelemetryCollector(
            component=component or None,
            route=str(self.policy.get("route", "")),
            exporter=context_exporter,
        )

    @property
    def restricted(self) -> bool:
        return self.policy.get("route") in {'synthesis', 'partial'}

    async def pre_tool_use(self, data, _tool_use_id, _context):
        tool_name = str(data.get("tool_name", ""))
        tool_input = dict(data.get("tool_input", {}))
        self.tool_calls[tool_name] += 1
        if not self.restricted:
            if self._direct_output_mode and tool_name in {"Write", "Edit"}:
                return self._check_write(tool_name, tool_input)
            if tool_name == "Read":
                self._track_unrestricted_read(tool_input)
            elif tool_name in {"Glob", "Grep"}:
                self._record_search_observation(tool_name, tool_input)
            elif tool_name in {"Write", "Edit"}:
                # These mutate state but do not return source content. Checkout
                # mutations are independently caught by SourceRunState.
                pass
            else:
                # Unrestricted Claude tools may read source, delegate further
                # reads, or import external evidence. Unless a tool is handled
                # above, there is no complete dependency observation for it.
                command = str(tool_input.get("command") or "").strip()
                self.unclassified_source_commands.append(
                    command or tool_name or "unknown-Claude-tool"
                )
            return {}

        if tool_name == "Task":
            return self._deny(
                tool_name,
                "sub-agents are disabled for this readiness",
                category="workflow-noise",
            )
        if tool_name == "Bash":
            return self._deny(
                tool_name,
                (
                    "shell discovery is disabled; use Read for known files and "
                    "targeted Glob/Grep patterns for discovery"
                ),
                category="workflow-noise",
            )
        permitted_tools = {
            "Read",
            "Write",
            "Edit",
            "Skill",
            *self.policy.get("discovery_tools", ()),
        }
        if tool_name not in permitted_tools:
            if tool_name in _AVOIDABLE_WORKFLOW_DENIAL_TOOLS:
                return self._deny(
                    tool_name,
                    (
                        f"{tool_name} is disabled for component generation; "
                        "keep any plan in prose and write only requested artifacts"
                    ),
                    category="workflow-noise",
                )
            return self._deny(
                tool_name,
                "this tool is outside the restricted execution policy",
                category="guardrail-boundary",
            )
        if tool_name in {"Glob", "Grep"}:
            return self._check_discovery(tool_name, tool_input)
        if tool_name == "Read":
            return self._check_read(tool_name, tool_input)
        if tool_name in {"Write", "Edit"}:
            return self._check_write(tool_name, tool_input)
        if tool_name == "Skill":
            return {}
        # A policy may explicitly permit a future discovery tool. Until its
        # read/search semantics are implemented above, that execution cannot
        # support a complete dependency record.
        self.unclassified_source_commands.append(
            tool_name or "unknown-Claude-tool"
        )
        return {}

    def _check_discovery(self, tool_name: str, tool_input: dict):
        if tool_name not in set(self.policy.get("discovery_tools", ())):
            return self._deny(
                tool_name, "broad discovery is disabled for sufficient baselines"
            )
        self._discovery_calls[tool_name] += 1
        limit = (
            2
            if tool_name == "Glob"
            else max(1, len(self.policy.get("gap_categories", ())))
        )
        if self._discovery_calls[tool_name] > limit:
            self.discovery_budget_exceeded += 1
        search_path = tool_input.get("path")
        if search_path and not self._within_checkout(Path(str(search_path))):
            return self._deny(
                tool_name,
                "discovery must stay inside the checkout",
                category="guardrail-boundary",
            )
        if not search_path:
            tool_input["path"] = str(self.checkout)
        elif not Path(str(search_path)).is_absolute():
            tool_input["path"] = str(self._resolve_tool_path(Path(str(search_path))))
        if tool_name == "Grep":
            tool_input["output_mode"] = "files_with_matches"
            tool_input["head_limit"] = min(
                _PARTIAL_MAX_DISCOVERY_RESULTS,
                max(
                    1,
                    int(self.policy.get("file_budget") or 1),
                    len(self.policy.get("gap_categories", ())),
                ),
            )
            self._record_tool_activity("targeted_discovery")
            self._record_search_observation(tool_name, tool_input)
            return self._allow_with_input(tool_input)
        pattern = str(tool_input.get("pattern", "")).strip()
        if pattern in {"*", "**", "**/*", "./*", "./**/*"}:
            return self._deny(
                tool_name,
                "partial discovery requires a targeted file pattern, "
                f"not a full-checkout Glob. {_PARTIAL_TARGETED_GLOB_HINT}",
                category="broad-discovery",
            )
        self._record_tool_activity("targeted_discovery")
        self._record_search_observation(tool_name, tool_input)
        return self._allow_with_input(tool_input)

    def _record_search_observation(self, tool_name: str, tool_input: dict) -> None:
        """Record the resolved scope and every effective search option."""

        if self.checkout is None:
            self.unclassified_source_commands.append(tool_name)
            return
        raw_path = tool_input.get("path") or str(self.checkout)
        path = self._resolve_tool_path(Path(str(raw_path)))
        pattern = str(tool_input.get("pattern") or "")
        if path is None or not self._within_checkout(path) or not pattern:
            self.unclassified_source_commands.append(tool_name)
            return
        self.search_observations.append(
            {
                "tool": tool_name,
                "resolved_root": str(path),
                "pattern": pattern,
                "options": {
                    str(key): value
                    for key, value in tool_input.items()
                    if key not in {"path", "pattern"}
                },
                "outcome": "observed-pre-tool-use",
            }
        )
        # Claude's hook observes the request before execution but supplies no
        # authoritative result bytes. Subtree hashing cannot account for local
        # or ancestor ignore configuration, so preserve the real scope while
        # making this prospective dependency explicitly ineligible for reuse.
        relative = path.relative_to(self.checkout).as_posix()
        self.unclassified_source_commands.append(
            f"{tool_name}-search-result-unverified:{relative}"
        )

    def _check_read(self, tool_name: str, tool_input: dict):
        raw_path = tool_input.get("file_path") or tool_input.get("path")
        if not raw_path:
            reason = "Read requires a file path"
            self.ctx_telemetry.record_denied_read(detail=reason)
            return self._deny(tool_name, reason, category="malformed-tool-input")
        path = self._resolve_tool_path(Path(str(raw_path)))
        if path is not None and self._within_trusted_read_root(path):
            self.read_calls += 1
            self._record_tool_activity("skill_context_read")
            return self._rewrite_relative_path(tool_input, raw_path, path)
        if path is not None and self._within_analyzer_root(path):
            self.read_calls += 1
            self._record_tool_activity("analyzer_context_read")
            self.ctx_telemetry.record_navigation_read(
                self._analyzer_relative_path(path),
            )
            return self._rewrite_relative_path(tool_input, raw_path, path)
        if path is not None and path in self._allowed_input_paths:
            self.read_calls += 1
            self._record_tool_activity("planning_input_read")
            self.ctx_telemetry.record_navigation_read(str(path))
            return self._rewrite_relative_path(tool_input, raw_path, path)
        if path is not None and path in self._allowed_output_paths:
            self.read_calls += 1
            self._record_tool_activity("output_artifact_read")
            self.ctx_telemetry.record_navigation_read(str(path))
            return self._rewrite_relative_path(tool_input, raw_path, path)
        if path is None or not self._within_checkout(path):
            if self._is_prior_architecture_path(str(raw_path)):
                reason = (
                    "prior architecture documents are comparison-only "
                    "and must not be used as synthesis inputs"
                )
                self.ctx_telemetry.record_denied_read(
                    file=str(raw_path), detail=reason,
                )
                return self._deny(tool_name, reason, category="guardrail-boundary")
            reason = "reads must stay inside the checkout"
            self.ctx_telemetry.record_denied_read(
                file=str(raw_path), detail=reason,
            )
            return self._deny(tool_name, reason, category="guardrail-boundary")
        self.read_calls += 1
        if path.name in _NAVIGATION_FILES:
            self._record_tool_activity("navigation_read")
            self.ctx_telemetry.record_navigation_read(
                path.relative_to(self.checkout).as_posix()
                if self.checkout else str(path),
            )
            return self._rewrite_relative_path(tool_input, raw_path, path)
        # Partial is the bounded extend-and-improve route for every readiness
        # classification. Its file budget is the source boundary; readiness
        # must not turn targeted partial reads into analyzer-only execution.
        if (
            self.policy.get("route") != "partial"
            and self.policy.get("readiness") == "sufficient"
            and (
                path not in self._allowed_sources
            )
        ):
            reason = "synthesis policy permits only analyzer-referenced source files"
            self.ctx_telemetry.record_denied_read(
                file=path.relative_to(self.checkout).as_posix()
                if self.checkout else str(path),
                detail=reason,
            )
            return self._deny(tool_name, reason, category="guardrail-boundary")
        if self.policy.get("route") == "partial":
            bounds_decision = self._check_partial_source_read_bounds(
                tool_name, tool_input, path
            )
            if bounds_decision is not None:
                return bounds_decision
        relative = path.relative_to(self.checkout).as_posix()
        if relative not in self._source_read_set:
            budget = int(self.policy.get("file_budget") or 0)
            if budget > 0 and len(self._source_read_set) >= budget:
                self.source_read_budget_exceeded += 1
                self.source_read_budget_exceeded_files.append(relative)
            self._source_read_set.add(relative)
            self.source_reads.append(relative)
        self.source_read_operations += 1
        self.source_read_ranges.append(
            {
                "path": relative,
                "offset": tool_input.get("offset", 1),
                "limit": tool_input.get("limit"),
            }
        )
        self._record_tool_activity("targeted_source_read")
        self.ctx_telemetry.record_useful_read(relative)
        return self._rewrite_relative_path(tool_input, raw_path, path)

    def _check_partial_source_read_bounds(
        self,
        tool_name: str,
        tool_input: dict,
        path: Path,
    ):
        raw_limit = tool_input.get("limit")
        relative = (
            path.relative_to(self.checkout).as_posix()
            if self.checkout is not None
            else str(path)
        )
        if raw_limit is not None:
            try:
                limit = int(raw_limit)
            except (TypeError, ValueError):
                reason = "partial source reads require a numeric limit"
                self.ctx_telemetry.record_denied_read(file=relative, detail=reason)
                return self._deny(
                    tool_name, reason, category="malformed-tool-input",
                )
            if limit <= 0 or limit > _PARTIAL_MAX_SOURCE_READ_LINES:
                reason = (
                    "partial source reads must target at most "
                    f"{_PARTIAL_MAX_SOURCE_READ_LINES} lines; use offset/limit "
                    "around the relevant symbol, function, or manifest snippet"
                )
                self.ctx_telemetry.record_denied_read(file=relative, detail=reason)
                return self._deny(
                    tool_name, reason, category="oversized-source-read",
                )
            return None
        try:
            line_count = sum(1 for _ in path.open(encoding="utf-8", errors="ignore"))
        except OSError:
            return None
        if line_count > _PARTIAL_MAX_SOURCE_READ_LINES:
            reason = (
                "partial source reads of files larger than "
                f"{_PARTIAL_MAX_SOURCE_READ_LINES} lines require offset/limit; "
                "read the relevant symbol, function, or manifest snippet instead "
                "of the whole file. For Helm values or YAML manifests, start "
                "with a bounded top-level read such as offset=1, limit=120, then "
                "read only the specific component, dependency, gateway, auth, or "
                "TLS section needed for the routed gap."
            )
            self.ctx_telemetry.record_denied_read(file=relative, detail=reason)
            return self._deny(tool_name, reason, category="oversized-source-read")
        return None

    def _check_write(self, tool_name: str, tool_input: dict):
        raw_path = tool_input.get("file_path") or tool_input.get("path")
        if not raw_path:
            return self._deny(
                tool_name,
                f"{tool_name} requires a file path",
                category="malformed-tool-input",
            )
        path = self._resolve_tool_path(Path(str(raw_path)))
        if (
            path is None
            or path not in self._allowed_output_paths
        ):
            return self._deny(
                tool_name,
                "constrained agents may write only architecture output artifacts",
                category="guardrail-boundary",
            )
        if (
            tool_name == "Write"
            and path == self._primary_output_path
            and self.policy.get("output_preseeded")
        ):
            return self._deny(
                tool_name,
                (
                    "the orchestrator pre-seeded the analyzer baseline; use "
                    "targeted Edit on the existing output file and reserve Write "
                    "for sidecar artifacts"
                ),
                category="workflow-noise",
            )
        if path == self._primary_output_path:
            self._record_tool_activity("architecture_output_edit")
        else:
            self._record_tool_activity("sidecar_write")
        return self._rewrite_relative_path(tool_input, raw_path, path)

    def _track_unrestricted_read(self, tool_input: dict) -> None:
        """Record legacy reads without changing or rejecting the tool call."""

        self.read_calls += 1
        raw_path = tool_input.get("file_path") or tool_input.get("path")
        if not raw_path or self.checkout is None:
            self.unclassified_source_commands.append("Read")
            return
        path = self._resolve_tool_path(Path(str(raw_path)))
        if path is None or not self._within_checkout(path):
            self.unclassified_source_commands.append("Read")
            return
        relative = path.relative_to(self.checkout).as_posix()
        if path.name in _NAVIGATION_FILES:
            self._record_tool_activity("navigation_read")
            self.ctx_telemetry.record_navigation_read(relative)
            return
        if relative not in self._source_read_set:
            self._source_read_set.add(relative)
            self.source_reads.append(relative)
        self.source_read_operations += 1
        self.source_read_ranges.append(
            {
                "path": relative,
                "offset": tool_input.get("offset", 1),
                "limit": tool_input.get("limit"),
            }
        )
        self._record_tool_activity("targeted_source_read")
        self.ctx_telemetry.record_useful_read(relative)

    def _record_tool_activity(self, category: str) -> None:
        self.tool_call_categories[category] += 1

    def _resolve_tool_path(self, path: Path) -> Path | None:
        if path.is_absolute():
            return path.resolve()
        if self.checkout is None:
            return None
        return (self.checkout / path).resolve()

    def _within_checkout(self, path: Path) -> bool:
        if self.checkout is None:
            return False
        resolved = self._resolve_tool_path(path)
        return resolved == self.checkout or self.checkout in resolved.parents

    def _within_analyzer_root(self, path: Path) -> bool:
        if self.analyzer_root is None:
            return False
        resolved = path.resolve()
        return resolved == self.analyzer_root or self.analyzer_root in resolved.parents

    def _analyzer_relative_path(self, path: Path) -> str:
        if self.analyzer_root is None:
            return str(path)
        return f".analyzer/{path.relative_to(self.analyzer_root).as_posix()}"

    def _within_trusted_read_root(self, path: Path) -> bool:
        return any(
            path == root or root in path.parents
            for root in self._trusted_read_roots
        )

    @staticmethod
    def _is_prior_architecture_path(raw_path: str) -> bool:
        """Return True if the path looks like a prior architecture output."""
        parts = Path(raw_path).parts
        for i, part in enumerate(parts):
            if part == _PRIOR_ARCHITECTURE_DIR and i + 1 < len(parts):
                remaining = "/".join(parts[i + 1 :])
                if remaining.endswith(".md"):
                    return True
        return False

    def _deny(
        self,
        tool_name: str,
        reason: str,
        *,
        category: str = "guardrail-boundary",
    ):
        self.denied_calls[tool_name] += 1
        self.denied_call_categories[category] += 1
        self._record_tool_activity("denied_call")
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }

    @staticmethod
    def _allow_with_input(tool_input: dict):
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "updatedInput": tool_input,
            }
        }

    def _rewrite_relative_path(
        self, tool_input: dict, raw_path: object, resolved: Path
    ):
        if Path(str(raw_path)).is_absolute():
            return {}
        updated = dict(tool_input)
        key = "file_path" if "file_path" in updated else "path"
        updated[key] = str(resolved)
        return self._allow_with_input(updated)

    def telemetry(self) -> dict[str, object]:
        result = {
            "source_read_observation": "claude-pre-tool-use-hooks",
            "tool_calls": sum(self.tool_calls.values()),
            "tool_calls_by_name": dict(sorted(self.tool_calls.items())),
            "tool_calls_by_activity": dict(
                sorted(self.tool_call_categories.items())
            ),
            "denied_tool_calls": sum(self.denied_calls.values()),
            "denied_tool_calls_by_name": dict(sorted(self.denied_calls.items())),
            "denied_tool_calls_by_category": dict(
                sorted(self.denied_call_categories.items())
            ),
            "avoidable_workflow_denials": sum(
                count
                for tool, count in self.denied_calls.items()
                if tool in _AVOIDABLE_WORKFLOW_DENIAL_TOOLS
            ),
            "read_calls": self.read_calls,
            "source_read_operations": self.source_read_operations,
            "source_read_budget": self.policy.get("file_budget"),
            "source_read_budget_exceeded": self.source_read_budget_exceeded,
            "source_read_budget_exceeded_files": (
                self.source_read_budget_exceeded_files
            ),
            "discovery_budget_exceeded": self.discovery_budget_exceeded,
            "source_files_read": self.source_reads,
            "source_file_count": len(self.source_reads),
            "source_read_ranges": self.source_read_ranges,
            "dependency_observations": dependency_observations(
                harness="claude",
                reads=[
                    {**record, "outcome": "observed-pre-tool-use"}
                    for record in self.source_read_ranges
                ],
                searches=self.search_observations,
                complete=not self.unclassified_source_commands,
                unclassified_source_commands=list(
                    dict.fromkeys(self.unclassified_source_commands)
                ),
            ),
            "context_metrics": self.ctx_telemetry.context_metrics(),
        }
        gap_reasons = self.policy.get("gap_reasons", ())
        if gap_reasons:
            result["gap_reasons"] = list(gap_reasons)
        return result


def get_model_display_name(
    model_shorthand: str | None,
    harness: str = "claude",
) -> str:
    """
    Convert model shorthand to human-readable display name for generated files.

    Args:
        model_shorthand: Short name (sonnet, opus, haiku)

    Returns:
        Human-readable model name
    """
    if harness == "codex":
        return model_shorthand or "Codex"
    model_shorthand = model_shorthand or "opus"
    display_names = {
        "sonnet": "Claude Sonnet 4.5",
        "opus": "Claude Opus 4.6",
        "haiku": "Claude Haiku 3.5",
    }
    return display_names.get(model_shorthand, model_shorthand)


def get_model_id(model_shorthand: str) -> str:
    """
    Convert model shorthand to full model ID.

    Args:
        model_shorthand: Short name (sonnet, opus, haiku)

    Returns:
        Full model ID string
    """
    # Model IDs without date suffixes -- the SDK resolves to the latest version
    model_mapping = {
        "sonnet": "claude-sonnet-4-5",
        "opus": "claude-opus-4-6",
        "haiku": "claude-haiku-3-5",
    }

    return model_mapping.get(model_shorthand, model_shorthand)


@lru_cache(maxsize=8)
def _inspect_claude_cli(
    path: str,
    stat_identity: tuple[int, int, int, int, int],
) -> dict[str, str | int]:
    """Identify one resolved Claude CLI without starting an SDK session."""

    del stat_identity  # Cache key: invalidates an in-place executable change.
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    try:
        completed = subprocess.run(
            [path, "--version"],
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError) as error:
        raise RuntimeError(f"cannot identify Claude CLI {path}: {error}") from error
    version_output = completed.stdout.strip()
    if not version_output:
        raise RuntimeError(f"Claude CLI {path} returned an empty version identity")
    return {
        "implementation": "claude-code-cli",
        "version_output": version_output,
        "binary_sha256": f"sha256:{digest.hexdigest()}",
    }


def resolve_claude_cli_identity(
    cli_path: str | Path | None = None,
) -> tuple[str, dict[str, str | int]]:
    """Resolve and bind the exact CLI implementation used by the Claude SDK."""

    if cli_path is None:
        from claude_agent_sdk._internal.transport.subprocess_cli import (
            SubprocessCLITransport,
        )

        resolver = SubprocessCLITransport(
            prompt=empty_async_iter(), options=ClaudeAgentOptions()
        )
        candidate = resolver._find_cli()
    else:
        candidate = str(cli_path)
    resolved = Path(candidate).expanduser().resolve(strict=True)
    status = resolved.stat()
    stat_identity = (
        status.st_dev,
        status.st_ino,
        status.st_size,
        status.st_mtime_ns,
        status.st_ctime_ns,
    )
    return str(resolved), dict(_inspect_claude_cli(str(resolved), stat_identity))


def format_duration(seconds: float) -> str:
    """Format seconds into a human-readable duration string."""
    total = int(seconds)
    h, remainder = divmod(total, 3600)
    m, s = divmod(remainder, 60)
    parts = []
    if h:
        parts.append(f"{h}h")
    if m:
        parts.append(f"{m}m")
    parts.append(f"{s}s")
    return " ".join(parts)


def _provider_exception_details(error: BaseException) -> dict:
    """Retain structured transport status without serializing opaque objects."""

    response = getattr(error, "response", None)
    status_code = getattr(error, "status_code", None)
    if status_code is None and response is not None:
        status_code = getattr(response, "status_code", None)
    code = getattr(error, "code", None)
    return {
        "kind": "claude-exception",
        "error_type": type(error).__name__,
        "message": str(error),
        "status_code": status_code if isinstance(status_code, int) else None,
        "code": str(code) if code is not None else None,
    }


def _exception_is_rate_limit(error: BaseException) -> bool:
    details = _provider_exception_details(error)
    code = str(details.get("code") or "").casefold().replace("-", "_")
    return details.get("status_code") == 429 or code in {
        "rate_limit",
        "rate_limit_error",
        "usage_limit",
        "usage_limit_exceeded",
    }


def _result_text_is_session_limit(result: object) -> bool:
    if not isinstance(result, str):
        return False
    normalized = " ".join(result.casefold().replace("_", " ").split())
    return (
        "you've hit your session limit" in normalized
        or "you have hit your session limit" in normalized
    )


async def run_agent(
    name: str,
    cwd: str,
    prompt: str,
    log_dir: Path,
    model: str | None = "opus",
    enable_skills: bool = False,
    progress: AgentProgress | None = None,
    strace_dir: Path | None = None,
    agent_policy: dict | None = None,
    checkout_path: str | Path | None = None,
    analyzer_root: str | Path | None = None,
    input_paths: tuple[str | Path, ...] = (),
    output_paths: tuple[str | Path, ...] = (),
    harness: str = "claude",
    max_turns: int | None = None,
    max_budget_usd: float | None = None,
    tool_free: bool = False,
    response_schema: dict | None = None,
    claude_cli_path: str | Path | None = None,
    codex_structured_context: dict | None = None,
) -> dict:
    """
    Launch one independent agent session through the selected harness.

    Args:
        name: Component name for identification
        cwd: Working directory for the agent
        prompt: Prompt to send to the agent
        log_dir: Directory to write log files
        model: Model understood by the selected harness
        enable_skills: If True, enable Skill tool and load skills from filesystem

    Returns:
        dict with 'name', 'success', 'log_file', and optional 'error' keys
    """
    if harness == "codex":
        if max_turns is not None or max_budget_usd is not None:
            raise ValueError(
                "Claude turn and dollar limits are unsupported by the Codex harness"
            )
        from lib.codex_agent import run_codex_agent

        return await run_codex_agent(
            name=name,
            cwd=cwd,
            prompt=prompt,
            log_dir=log_dir,
            model=model,
            enable_skills=enable_skills,
            progress=progress,
            strace_dir=strace_dir,
            checkout_path=checkout_path,
            input_paths=input_paths,
            output_paths=output_paths,
            tool_free=tool_free,
            response_schema=response_schema,
            expected_structured_context=codex_structured_context,
        )
    if harness != "claude":
        raise ValueError(f"Unsupported agent harness: {harness!r}")

    model = model or "opus"
    if max_turns is not None and max_turns < 1:
        raise ValueError("max_turns must be at least 1")
    if max_budget_usd is not None and max_budget_usd <= 0:
        raise ValueError("max_budget_usd must be greater than zero")
    if tool_free and max_turns not in {None, 1}:
        raise ValueError("tool-free structured calls require max_turns=1")
    if tool_free:
        max_turns = 1

    resolved_claude_cli_path: str | None = None
    claude_cli_identity: dict[str, str | int] | None = None
    if tool_free:
        resolved_claude_cli_path, claude_cli_identity = (
            resolve_claude_cli_identity(claude_cli_path)
        )

    # Create log file for this agent
    log_file = log_dir / f"{name.replace('/', '_')}.log"

    # Convert shorthand to full model ID
    model_id = get_model_id(model)

    policy = dict(agent_policy) if agent_policy is not None else {}
    policy.setdefault("component", name)
    guard = _AgentExecutionGuard(
        policy,
        checkout_path,
        analyzer_root=analyzer_root,
        input_paths=input_paths,
        output_paths=output_paths,
    )
    allowed_tools = ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
    if enable_skills:
        allowed_tools.extend(["Skill", "Task"])
    if guard.restricted:
        allowed_tools = ["Read", "Write", "Edit", "Skill"]
        allowed_tools.extend(policy.get("discovery_tools", ()))
    if tool_free:
        allowed_tools = []

    def capture_claude_stderr(line: str) -> None:
        """Keep Claude CLI stderr in the per-agent log for failed runs."""
        with open(log_file, "a") as log:
            log.write(f"CLAUDE CLI STDERR: {line}\n")
            log.flush()

    # Claude Code writes project/session state to its config directory even
    # when permission checks are bypassed. Give every concurrent agent a
    # private disposable directory so runs cannot mutate ~/.claude or race on
    # a shared config file.
    config_dir = Path(tempfile.mkdtemp(prefix="architecture-claude-config-"))
    credentials_staged = _stage_claude_credentials(config_dir)
    options = ClaudeAgentOptions(
        tools=[] if tool_free else None,
        cwd=cwd,
        allowed_tools=allowed_tools,
        permission_mode="bypassPermissions",
        model=model_id,
        max_turns=max_turns,
        max_budget_usd=max_budget_usd,
        setting_sources=([] if tool_free else ["project"] if enable_skills else None),
        disallowed_tools=(
            ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Task", "Skill"]
            if tool_free
            else []
        ),
        cli_path=resolved_claude_cli_path,
        output_format=(
            {"type": "json_schema", "schema": response_schema}
            if response_schema is not None and not tool_free
            else None
        ),
        env={"CLAUDE_CONFIG_DIR": str(config_dir)},
        stderr=capture_claude_stderr,
        hooks={
            "PreToolUse": [
                HookMatcher(
                    matcher=None,
                    hooks=[guard.pre_tool_use],
                )
            ]
        },
    )

    _log = progress.log if progress else print

    transport = None
    if strace_dir is not None:
        strace_dir.mkdir(parents=True, exist_ok=True)
        transport = StracedTransport(
            prompt=empty_async_iter(),
            options=options,
            strace_output_path=strace_dir / "trace",
        )

    _log(f"\n{'=' * 60}")
    _log(f"Starting agent: {name}")
    _log(f"Model: {model}")
    _log(f"Working directory: {cwd}")
    _log(f"Log file: {log_file}")
    if strace_dir is not None:
        _log(f"Strace output: {strace_dir}")
    _log(f"{'=' * 60}")

    # Write log header before try block so error handler always has context
    with open(log_file, "w") as log:
        log.write(f"Agent: {name}\n")
        log.write(f"Model: {model}\n")
        log.write(f"Working directory: {cwd}\n")
        log.write(f"{'=' * 60}\n\n")
        log.write("PROMPT:\n")
        log.write(prompt)
        log.write(f"\n\n{'=' * 60}\n")
        log.write("AGENT OUTPUT:\n\n")

    start_time = time.monotonic()
    last_activity = start_time
    heartbeat_task = None

    if not progress:

        async def _heartbeat():
            """Print periodic status while the agent is working silently."""
            nonlocal last_activity
            while True:
                await asyncio.sleep(30)
                silence = time.monotonic() - last_activity
                elapsed = time.monotonic() - start_time
                if silence >= 30:
                    print(
                        f"[{name}] ... still running "
                        f"({format_duration(elapsed)} elapsed)"
                    )

        heartbeat_task = asyncio.create_task(_heartbeat())

    if progress:
        progress.agent_started(name)

    try:
        result_message = None
        response_models: list[str] = []
        assistant_errors: list[str] = []
        rate_limit_events: list[dict] = []
        with open(log_file, "a") as log:
            async with ClaudeSDKClient(options=options, transport=transport) as client:
                await client.query(prompt)

                async for msg in client.receive_response():
                    last_activity = time.monotonic()
                    # Concurrent runs already have a live progress display. Keep
                    # full SDK payloads in the per-agent log instead of streaming
                    # multi-megabyte Read results through the shared console.
                    if not progress:
                        _log(f"[{name}] {msg}")
                    log.write(f"{msg}\n")
                    log.flush()
                    if isinstance(msg, ResultMessage):
                        result_message = msg
                    elif isinstance(msg, AssistantMessage):
                        if msg.model and msg.model not in response_models:
                            response_models.append(msg.model)
                        if msg.error:
                            assistant_errors.append(str(msg.error))
                    elif isinstance(msg, RateLimitEvent):
                        rate_limit_events.append(
                            {
                                "status": msg.rate_limit_info.status,
                                "resets_at": msg.rate_limit_info.resets_at,
                                "rate_limit_type": (
                                    msg.rate_limit_info.rate_limit_type
                                ),
                                "utilization": msg.rate_limit_info.utilization,
                                "overage_status": (
                                    msg.rate_limit_info.overage_status
                                ),
                                "overage_resets_at": (
                                    msg.rate_limit_info.overage_resets_at
                                ),
                                "overage_disabled_reason": (
                                    msg.rate_limit_info.overage_disabled_reason
                                ),
                                "raw": msg.rate_limit_info.raw,
                            }
                        )

        elapsed = time.monotonic() - start_time

        _log(f"Completed: {name} ({format_duration(elapsed)})")

        rejected_rate_limit = any(
            event.get("status") == "rejected" for event in rate_limit_events
        )
        result_is_error = bool(
            result_message is not None and result_message.is_error
        )
        assistant_rate_limit = "rate_limit" in assistant_errors
        result_text = getattr(result_message, "result", None)
        session_limit_denied = result_is_error and _result_text_is_session_limit(
            result_text
        )
        if result_is_error or rejected_rate_limit or assistant_rate_limit:
            errors = getattr(result_message, "errors", None) or []
            error_text = "; ".join(str(error) for error in errors)
            if not error_text and isinstance(result_text, str) and result_text:
                error_text = result_text
            if not error_text and rejected_rate_limit:
                error_text = "Claude rate limit rejected the request"
            if not error_text and assistant_errors:
                error_text = "; ".join(assistant_errors)
            if not error_text:
                error_text = "Claude execution failed"
            provider_error = {
                "kind": "claude-result",
                "is_error": result_is_error,
                "subtype": getattr(result_message, "subtype", None),
                "result": result_text,
                "errors": list(errors),
                "stop_reason": getattr(result_message, "stop_reason", None),
                "assistant_errors": assistant_errors,
                "rate_limit_events": rate_limit_events,
            }
            if progress:
                progress.agent_completed(name, success=False)
            return {
                "name": name,
                "success": False,
                "error": error_text,
                "provider_error": provider_error,
                "rate_limit_denied": (
                    rejected_rate_limit
                    or assistant_rate_limit
                    or session_limit_denied
                ),
                "log_file": str(log_file),
                "duration_seconds": elapsed,
                "telemetry": {
                    **guard.telemetry(),
                    "claude_credentials_staged": credentials_staged,
                    "requested_model_identity": model_id,
                    **(
                        {"claude_cli_identity": claude_cli_identity}
                        if claude_cli_identity is not None
                        else {}
                    ),
                    "applied_model_settings": {
                        **(
                            {"max_budget_usd": max_budget_usd}
                            if max_budget_usd is not None
                            else {}
                        )
                    },
                    "response_models": response_models,
                    "model_usage": (
                        getattr(result_message, "model_usage", None) or {}
                    ),
                    "rate_limit_events": rate_limit_events,
                },
            }

        if progress:
            progress.agent_completed(name, success=True)

        result = {
            "name": name,
            "success": True,
            "log_file": str(log_file),
            "duration_seconds": elapsed,
            "telemetry": {
                **guard.telemetry(),
                "claude_credentials_staged": credentials_staged,
                "requested_model_identity": model_id,
                **(
                    {"claude_cli_identity": claude_cli_identity}
                    if claude_cli_identity is not None
                    else {}
                ),
                "applied_model_settings": {
                    **(
                        {"max_budget_usd": max_budget_usd}
                        if max_budget_usd is not None
                        else {}
                    )
                },
                "response_models": response_models,
                "rate_limit_events": rate_limit_events,
            },
        }
        if result_message is not None:
            result["raw_response"] = result_message.result
            result["telemetry"].update(
                {
                    "duration_api_ms": result_message.duration_api_ms,
                    "num_turns": result_message.num_turns,
                    "total_cost_usd": result_message.total_cost_usd,
                    "usage": result_message.usage or {},
                    "model_usage": result_message.model_usage or {},
                    "permission_denials": result_message.permission_denials or [],
                }
            )
        return result

    except BaseException as e:
        # Catch BaseException (not just Exception) because the Claude Code CLI
        # can crash on benign text patterns like [/path], causing anyio to cancel
        # concurrent sub-agent tasks. The resulting CancelledError exceptions are
        # wrapped in a BaseExceptionGroup, which is a BaseException — not caught
        # by `except Exception`.
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise

        elapsed = time.monotonic() - start_time

        if progress:
            progress.agent_completed(name, success=False)
        _log(f"Failed: {name} ({format_duration(elapsed)}) — {e}")

        with open(log_file, "a") as log:
            log.write(f"\n\n{'=' * 60}\n")
            log.write(f"ERROR: {e}\n")

        return {
            "name": name,
            "success": False,
            "error": str(e),
            "provider_error": _provider_exception_details(e),
            "rate_limit_denied": _exception_is_rate_limit(e),
            "log_file": str(log_file),
            "duration_seconds": elapsed,
            "telemetry": {
                **guard.telemetry(),
                "claude_credentials_staged": credentials_staged,
                "requested_model_identity": model_id,
                **(
                    {"claude_cli_identity": claude_cli_identity}
                    if claude_cli_identity is not None
                    else {}
                ),
                "applied_model_settings": {
                    **(
                        {"max_budget_usd": max_budget_usd}
                        if max_budget_usd is not None
                        else {}
                    )
                },
            },
        }

    finally:
        shutil.rmtree(config_dir, ignore_errors=True)
        if heartbeat_task:
            heartbeat_task.cancel()
            try:
                await heartbeat_task
            except asyncio.CancelledError:
                pass


async def run_agents_concurrently(
    jobs: list,
    log_dir: Path,
    model: str | None,
    max_concurrent: int,
    enable_skills: bool = False,
    strace_prefix: str | None = None,
    phase_label: str = "",
    on_result=None,
    harness: str = "claude",
    max_turns: int | None = None,
    max_budget_usd: float | None = None,
) -> list:
    """
    Run multiple agent jobs with a concurrency limit.

    Displays a rich progress panel pinned to the bottom of the terminal
    showing completion count, running agents, elapsed time, and ETA.

    Args:
        jobs: List of dicts with 'name', 'cwd', 'prompt' keys
        log_dir: Directory for agent log files
        model: Model understood by the selected harness
        max_concurrent: Max agents running at once
        enable_skills: If True, enable Skill tool and load skills from filesystem

    Returns:
        List of result dicts (or Exceptions) in the same order as jobs
    """
    total = len(jobs)

    def _strace_dir_for(job_name: str) -> Path | None:
        if strace_prefix is None:
            return None
        safe_prefix = re.sub(r"[^a-zA-Z0-9._-]", "_", strace_prefix)
        safe_name = re.sub(r"[^a-zA-Z0-9._-]", "_", job_name)
        return Path("logs/strace") / f"{safe_prefix}-{safe_name}"

    async def _finalize_result(index: int, job: dict, result):
        if on_result is None:
            return result
        try:
            return await on_result(index, job, result)
        except BaseException as e:
            if isinstance(e, (KeyboardInterrupt, SystemExit)):
                raise
            return {
                **(result if isinstance(result, dict) else {}),
                "name": job["name"],
                "success": False,
                "_postprocessed": True,
                "error": f"post-processing failed: {e}",
                "log_file": str(log_dir / f"{job['name'].replace('/', '_')}.log"),
                "duration_seconds": (
                    result.get("duration_seconds", 0)
                    if isinstance(result, dict)
                    else 0
                ),
            }

    # Single job: skip the progress panel — just run directly with heartbeat
    if total == 1:
        job = jobs[0]
        try:
            result = await run_agent(
                job["name"],
                job["cwd"],
                job["prompt"],
                log_dir,
                model,
                enable_skills=enable_skills,
                strace_dir=_strace_dir_for(job["name"]),
                agent_policy=job.get("agent_policy"),
                checkout_path=job.get("checkout_path"),
                analyzer_root=job.get("analyzer_root"),
                input_paths=tuple(job.get("input_paths", ())),
                output_paths=tuple(job.get("output_paths", ())),
                harness=harness,
                max_turns=max_turns,
                max_budget_usd=max_budget_usd,
            )
        except BaseException as e:
            if isinstance(e, (KeyboardInterrupt, SystemExit)):
                raise
            result = {
                "name": job["name"],
                "success": False,
                "error": str(e),
                "log_file": str(log_dir / f"{job['name'].replace('/', '_')}.log"),
                "duration_seconds": 0,
            }
        return [await _finalize_result(0, job, result)]

    from lib.progress import AgentProgress

    semaphore = asyncio.Semaphore(max_concurrent)
    progress = AgentProgress(total, max_concurrent, phase_label=phase_label)

    async def _run(index: int, job: dict):
        if semaphore.locked():
            progress.log(
                f"[{job['name']}] queued ({index + 1}/{total}), waiting for slot ..."
            )
        try:
            async with semaphore:
                result = await run_agent(
                    job["name"],
                    job["cwd"],
                    job["prompt"],
                    log_dir,
                    model,
                    enable_skills=enable_skills,
                    progress=progress,
                    strace_dir=_strace_dir_for(job["name"]),
                    agent_policy=job.get("agent_policy"),
                    checkout_path=job.get("checkout_path"),
                    analyzer_root=job.get("analyzer_root"),
                    input_paths=tuple(job.get("input_paths", ())),
                    output_paths=tuple(job.get("output_paths", ())),
                    harness=harness,
                    max_turns=max_turns,
                    max_budget_usd=max_budget_usd,
                )
            return await _finalize_result(index, job, result)
        except BaseException as e:
            #print(e)
            #import pdb; pdb.set_trace()
            if isinstance(e, (KeyboardInterrupt, SystemExit)):
                raise
            progress.agent_completed(job["name"], success=False)
            progress.log(f"Failed (outer): {job['name']} — {e}")
            result = {
                "name": job["name"],
                "success": False,
                "error": str(e),
                "log_file": str(log_dir / f"{job['name'].replace('/', '_')}.log"),
                "duration_seconds": 0,
            }
            return await _finalize_result(index, job, result)

    if phase_label:
        progress.log(f"{phase_label}\n")
    progress.log("Starting agent execution...\n")
    progress.start()
    try:
        results = await asyncio.gather(
            *(_run(i, job) for i, job in enumerate(jobs)),
            return_exceptions=True,
        )
    finally:
        progress.stop()

    return results
