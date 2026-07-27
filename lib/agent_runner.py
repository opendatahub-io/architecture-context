"""Claude SDK agent launcher and model utilities."""

from __future__ import annotations

import asyncio
import re
import time
from collections import Counter
from pathlib import Path
from typing import TYPE_CHECKING

from claude_agent_sdk import (
    ClaudeAgentOptions,
    ClaudeSDKClient,
    HookMatcher,
    ResultMessage,
)

from lib.context_telemetry import ContextTelemetryCollector
from lib.strace_transport import StracedTransport, empty_async_iter

if TYPE_CHECKING:
    from lib.context_telemetry import ContextExporter
    from lib.progress import AgentProgress

_NAVIGATION_FILES = frozenset({
    "analyzer_architecture.md",
    "GENERATED_ARCHITECTURE.md",
    "ARCHITECTURE_CHANGES.md",
    "component-architecture.json",
})

_AGENT_OUTPUT_FILES = frozenset({
    "GENERATED_ARCHITECTURE.md",
    "ARCHITECTURE_CHANGES.md",
    "INSIGHTS_ARTIFACT.json",
})

_PRIOR_ARCHITECTURE_DIR = "architecture"
_REPO_ROOT = Path(__file__).resolve().parent.parent
_TRUSTED_SKILL_ROOT = _REPO_ROOT / ".claude" / "skills" / "repo-to-architecture-summary"


class _AgentExecutionGuard:
    """Enforce a readiness policy and collect per-agent tool telemetry."""

    def __init__(
        self,
        policy: dict | None,
        checkout_path: str | Path | None,
        *,
        analyzer_root: str | Path | None = None,
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
        self._allowed_output_paths = {
            Path(path).resolve() for path in output_paths
        }
        if not self._allowed_output_paths and self.checkout is not None:
            self._allowed_output_paths = {
                self.checkout / name for name in _AGENT_OUTPUT_FILES
            }
        # Restricted agents may read the architecture-summary skill's
        # instructions, templates, and references. This is deliberately a
        # separate read-only root: skill documentation does not become source
        # evidence, does not consume the component file budget, and cannot be
        # written through the agent guard.
        self._trusted_read_roots = (_TRUSTED_SKILL_ROOT.resolve(),)
        self.tool_calls: Counter[str] = Counter()
        self.denied_calls: Counter[str] = Counter()
        self.read_calls = 0
        self.source_reads: list[str] = []
        self._source_read_set: set[str] = set()
        self._discovery_calls: Counter[str] = Counter()
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
            if tool_name == "Read":
                self._track_unrestricted_read(tool_input)
            return {}

        if tool_name == "Task":
            return self._deny(tool_name, "sub-agents are disabled for this readiness")
        if tool_name == "Bash":
            return self._deny(
                tool_name,
                "shell discovery is disabled; the orchestrator performs validation",
            )
        permitted_tools = {
            "Read",
            "Write",
            "Edit",
            "Skill",
            *self.policy.get("discovery_tools", ()),
        }
        if tool_name not in permitted_tools:
            return self._deny(
                tool_name,
                "this tool is outside the restricted execution policy",
            )
        if tool_name in {"Glob", "Grep"}:
            return self._check_discovery(tool_name, tool_input)
        if tool_name == "Read":
            return self._check_read(tool_name, tool_input)
        if tool_name in {"Write", "Edit"}:
            return self._check_write(tool_name, tool_input)
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
            return self._deny(tool_name, f"{tool_name} call budget {limit} exhausted")
        search_path = tool_input.get("path")
        if search_path and not self._within_checkout(Path(str(search_path))):
            return self._deny(tool_name, "discovery must stay inside the checkout")
        if not search_path:
            tool_input["path"] = str(self.checkout)
        elif not Path(str(search_path)).is_absolute():
            tool_input["path"] = str(self._resolve_tool_path(Path(str(search_path))))
        if tool_name == "Grep":
            remaining = max(
                1,
                int(self.policy.get("file_budget") or 1) - len(self._source_read_set),
            )
            tool_input["output_mode"] = "files_with_matches"
            tool_input["head_limit"] = remaining
            return self._allow_with_input(tool_input)
        pattern = str(tool_input.get("pattern", "")).strip()
        if pattern in {"*", "**", "**/*", "./*", "./**/*"}:
            return self._deny(
                tool_name,
                "partial discovery requires a targeted file pattern, "
                "not a full-checkout Glob",
            )
        return self._allow_with_input(tool_input)

    def _check_read(self, tool_name: str, tool_input: dict):
        raw_path = tool_input.get("file_path") or tool_input.get("path")
        if not raw_path:
            reason = "Read requires a file path"
            self.ctx_telemetry.record_denied_read(detail=reason)
            return self._deny(tool_name, reason)
        path = self._resolve_tool_path(Path(str(raw_path)))
        if path is not None and self._within_trusted_read_root(path):
            self.read_calls += 1
            return self._rewrite_relative_path(tool_input, raw_path, path)
        if path is not None and self._within_analyzer_root(path):
            self.read_calls += 1
            self.ctx_telemetry.record_navigation_read(
                self._analyzer_relative_path(path),
            )
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
                return self._deny(tool_name, reason)
            reason = "reads must stay inside the checkout"
            self.ctx_telemetry.record_denied_read(
                file=str(raw_path), detail=reason,
            )
            return self._deny(tool_name, reason)
        self.read_calls += 1
        if path.name in _NAVIGATION_FILES:
            self.ctx_telemetry.record_navigation_read(
                path.relative_to(self.checkout).as_posix()
                if self.checkout else str(path),
            )
            return self._rewrite_relative_path(tool_input, raw_path, path)
        if self.policy.get("readiness") == "sufficient" and (
            path not in self._allowed_sources
        ):
            reason = "sufficient policy permits only analyzer-referenced source files"
            self.ctx_telemetry.record_denied_read(
                file=path.relative_to(self.checkout).as_posix()
                if self.checkout else str(path),
                detail=reason,
            )
            return self._deny(tool_name, reason)
        relative = path.relative_to(self.checkout).as_posix()
        if relative not in self._source_read_set:
            budget = int(self.policy.get("file_budget") or 0)
            if len(self._source_read_set) >= budget:
                reason = f"source-file budget {budget} exhausted"
                self.ctx_telemetry.record_denied_read(file=relative, detail=reason)
                return self._deny(tool_name, reason)
            self._source_read_set.add(relative)
            self.source_reads.append(relative)
        self.ctx_telemetry.record_useful_read(relative)
        return self._rewrite_relative_path(tool_input, raw_path, path)

    def _check_write(self, tool_name: str, tool_input: dict):
        raw_path = tool_input.get("file_path") or tool_input.get("path")
        if not raw_path:
            return self._deny(tool_name, f"{tool_name} requires a file path")
        path = self._resolve_tool_path(Path(str(raw_path)))
        if (
            path is None
            or path not in self._allowed_output_paths
        ):
            return self._deny(
                tool_name,
                "constrained agents may write only architecture output artifacts",
            )
        if (
            tool_name == "Write"
            and path.name == "GENERATED_ARCHITECTURE.md"
            and self.policy.get("output_preseeded")
            and path.parent == self.checkout
        ):
            return self._deny(
                tool_name,
                "the orchestrator pre-seeded the analyzer baseline; use targeted Edit",
            )
        return self._rewrite_relative_path(tool_input, raw_path, path)

    def _track_unrestricted_read(self, tool_input: dict) -> None:
        """Record legacy reads without changing or rejecting the tool call."""

        self.read_calls += 1
        raw_path = tool_input.get("file_path") or tool_input.get("path")
        if not raw_path or self.checkout is None:
            return
        path = self._resolve_tool_path(Path(str(raw_path)))
        if path is None or not self._within_checkout(path):
            return
        relative = path.relative_to(self.checkout).as_posix()
        if path.name in _NAVIGATION_FILES:
            self.ctx_telemetry.record_navigation_read(relative)
            return
        if relative not in self._source_read_set:
            self._source_read_set.add(relative)
            self.source_reads.append(relative)
        self.ctx_telemetry.record_useful_read(relative)

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

    def _deny(self, tool_name: str, reason: str):
        self.denied_calls[tool_name] += 1
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
            "tool_calls": sum(self.tool_calls.values()),
            "tool_calls_by_name": dict(sorted(self.tool_calls.items())),
            "denied_tool_calls": sum(self.denied_calls.values()),
            "denied_tool_calls_by_name": dict(sorted(self.denied_calls.items())),
            "read_calls": self.read_calls,
            "source_files_read": self.source_reads,
            "source_file_count": len(self.source_reads),
            "context_metrics": self.ctx_telemetry.context_metrics(),
        }
        gap_reasons = self.policy.get("gap_reasons", ())
        if gap_reasons:
            result["gap_reasons"] = list(gap_reasons)
        return result


def get_model_display_name(model_shorthand: str) -> str:
    """
    Convert model shorthand to human-readable display name for generated files.

    Args:
        model_shorthand: Short name (sonnet, opus, haiku)

    Returns:
        Human-readable model name
    """
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


async def run_agent(
    name: str,
    cwd: str,
    prompt: str,
    log_dir: Path,
    model: str = "opus",
    enable_skills: bool = False,
    progress: AgentProgress | None = None,
    strace_dir: Path | None = None,
    agent_policy: dict | None = None,
    checkout_path: str | Path | None = None,
    analyzer_root: str | Path | None = None,
    output_paths: tuple[str | Path, ...] = (),
) -> dict:
    """
    Launch one independent Claude agent session.

    Args:
        name: Component name for identification
        cwd: Working directory for the agent
        prompt: Prompt to send to the agent
        log_dir: Directory to write log files
        model: Claude model to use (sonnet, opus, or haiku)
        enable_skills: If True, enable Skill tool and load skills from filesystem

    Returns:
        dict with 'name', 'success', 'log_file', and optional 'error' keys
    """
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
        output_paths=output_paths,
    )
    allowed_tools = ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
    if enable_skills:
        allowed_tools.extend(["Skill", "Task"])
    if guard.restricted:
        allowed_tools = ["Read", "Write", "Edit", "Skill"]
        allowed_tools.extend(policy.get("discovery_tools", ()))

    options = ClaudeAgentOptions(
        cwd=cwd,
        allowed_tools=allowed_tools,
        permission_mode="bypassPermissions",
        model=model_id,
        setting_sources=["user", "project"] if enable_skills else None,
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

        elapsed = time.monotonic() - start_time

        if progress:
            progress.agent_completed(name, success=True)
        _log(f"Completed: {name} ({format_duration(elapsed)})")

        result = {
            "name": name,
            "success": True,
            "log_file": str(log_file),
            "duration_seconds": elapsed,
            "telemetry": guard.telemetry(),
        }
        if result_message is not None:
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
            "log_file": str(log_file),
            "duration_seconds": elapsed,
            "telemetry": guard.telemetry(),
        }

    finally:
        if heartbeat_task:
            heartbeat_task.cancel()
            try:
                await heartbeat_task
            except asyncio.CancelledError:
                pass


async def run_agents_concurrently(
    jobs: list,
    log_dir: Path,
    model: str,
    max_concurrent: int,
    enable_skills: bool = False,
    strace_prefix: str | None = None,
    phase_label: str = "",
) -> list:
    """
    Run multiple agent jobs with a concurrency limit.

    Displays a rich progress panel pinned to the bottom of the terminal
    showing completion count, running agents, elapsed time, and ETA.

    Args:
        jobs: List of dicts with 'name', 'cwd', 'prompt' keys
        log_dir: Directory for agent log files
        model: Model shorthand (sonnet, opus, haiku)
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
                output_paths=tuple(job.get("output_paths", ())),
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
        return [result]

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
                return await run_agent(
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
                    output_paths=tuple(job.get("output_paths", ())),
                )
        except BaseException as e:
            if isinstance(e, (KeyboardInterrupt, SystemExit)):
                raise
            progress.agent_completed(job["name"], success=False)
            progress.log(f"Failed (outer): {job['name']} — {e}")
            return {
                "name": job["name"],
                "success": False,
                "error": str(e),
                "log_file": str(log_dir / f"{job['name'].replace('/', '_')}.log"),
                "duration_seconds": 0,
            }

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
