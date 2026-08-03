#!/usr/bin/env python3
"""Run benchmark corpus questions against two architecture doc trees.

For each question, launches two fresh agent sessions (one per tree) via the
Claude Agent SDK. Tools are restricted to Read/Glob/Grep (read-only).
Presentation order (which tree runs first) is randomized per question.

Writes raw-results.json with responses, telemetry, and presentation order.
"""

from __future__ import annotations

import argparse
import asyncio
import importlib.util
import json
import os
import random
import re
import shlex
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

from lib.context_telemetry import (  # noqa: E402
    CONTRACT_VERSION as _CTX_CONTRACT_VERSION,
)
from lib.context_telemetry import ContextTelemetryCollector  # noqa: E402

_planner_spec = importlib.util.spec_from_file_location(
    "planner",
    REPO_ROOT / "benchmark" / "analyzer-assisted-v1" / "planner.py",
)
_planner = importlib.util.module_from_spec(_planner_spec)
_planner_spec.loader.exec_module(_planner)

_mat_spec = importlib.util.spec_from_file_location(
    "materialize_index",
    REPO_ROOT / "benchmark" / "analyzer-assisted-v1" / "materialize_index.py",
)
_mat_mod = importlib.util.module_from_spec(_mat_spec)
_mat_spec.loader.exec_module(_mat_mod)

_CLAUDE_ENV_VARS = (
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_AUTH_TOKEN",
    "ANTHROPIC_BASE_URL",
    "CLAUDE_CODE_USE_VERTEX",
    "ANTHROPIC_VERTEX_PROJECT_ID",
    "CLOUD_ML_REGION",
    "ANTHROPIC_DEFAULT_OPUS_MODEL",
    "ANTHROPIC_DEFAULT_SONNET_MODEL",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL",
)

_AUTH_FAILURE_PATTERNS = (
    "not logged in",
    "please run /login",
    "invalid api key",
    "authentication failed",
)

_PRIVATE_ARCHITECTURE_DIRS = {".analyzer", ".generation"}
_PRIVATE_ARCHITECTURE_REASON = (
    "private analyzer/generation sidecars are not evaluation context"
)


def _parse_env_file(path: Path) -> dict[str, str]:
    """Parse simple KEY=VALUE lines without shell-sourcing the file."""

    values: dict[str, str] = {}
    if not path.is_file():
        return values
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if key not in _CLAUDE_ENV_VARS:
            continue
        value = value.strip()
        if (
            len(value) >= 2
            and value[0] == value[-1]
            and value[0] in {"'", '"'}
        ):
            value = value[1:-1]
        values[key] = value
    return values


def _claude_sdk_env() -> dict[str, str]:
    """Return known Claude auth env with caller exports taking precedence."""

    env = _parse_env_file(REPO_ROOT / ".env")
    for key in _CLAUDE_ENV_VARS:
        if os.environ.get(key):
            env[key] = os.environ[key]
    return env


def _auth_failure_text(response_text: str) -> str | None:
    """Return an error reason if Claude emitted an auth/login response."""

    normalized = response_text.strip().lower()
    if any(pattern in normalized for pattern in _AUTH_FAILURE_PATTERNS):
        return response_text.strip() or "Claude authentication failed"
    return None


def _is_private_architecture_path(path: Path) -> bool:
    """Return whether *path* points into non-consumer generation sidecars."""

    return any(part in _PRIVATE_ARCHITECTURE_DIRS for part in path.parts)


def _parse_index_header(index_path: Path) -> dict:
    """Read provenance header from an INDEX.md file. Returns {} on failure."""
    try:
        content = index_path.read_text()
    except OSError:
        return {}
    return _mat_mod.parse_header(content) or {}


def check_isolation():
    """Verify no Claude memories or project config leak into the environment.

    Errors out if ~/.claude/ or any CLAUDE.md exists under the working
    directory. This is a negative control for containerized evaluation runs.
    """
    home = Path.home()
    claude_dir = home / ".claude"
    if claude_dir.exists():
        print(
            f"ISOLATION FAILURE: {claude_dir} exists. "
            "Remove it or run inside the evaluation container.",
            file=sys.stderr,
        )
        sys.exit(1)

    cwd = Path.cwd()
    for claude_md in cwd.rglob("CLAUDE.md"):
        print(
            f"ISOLATION FAILURE: {claude_md} found. "
            "Remove it or run inside the evaluation container.",
            file=sys.stderr,
        )
        sys.exit(1)

SYSTEM_PROMPT_TEMPLATE = """\
You are a technical analyst answering questions about RHOAI architecture \
documentation. Your working directory is set to an architecture document tree. \
Use Read, Glob, and Grep to find information. Answer factually from the \
documents on disk. If information is not documented, say so explicitly rather \
than guessing.

Architecture tree root: {tree_path}

Rules:
- Only read files under the architecture tree root shown above.
- Cite specific file paths and line numbers when possible.
- If the information is not present in the documents, state "not documented" \
clearly.
- Do not fabricate answers for missing information.
"""


APPROVED_QUERY_SUBCOMMANDS = frozenset({
    "callers-of",
    "config-sources",
    "consumers-of",
    "crds",
    "dependency-status",
    "diff",
})

_SHELL_METACHAR_RE = re.compile(r"[|&;`$(){}!<>]")


def parse_query_command(command: str):
    """Parse and validate an arch-query command string.

    Returns (argv, error) where argv is the parsed argument list if valid,
    or error is a denial reason string if invalid.
    """
    if _SHELL_METACHAR_RE.search(command):
        return None, "shell operators are not permitted in query commands"

    try:
        argv = shlex.split(command)
    except ValueError as exc:
        return None, f"failed to parse command: {exc}"

    if not argv:
        return None, "empty command"

    if argv[0] != "arch-query":
        return None, (
            f"only the bare 'arch-query' command is permitted, got '{argv[0]}'"
        )

    if len(argv) < 2 or argv[1] != "query":
        return None, "only 'arch-query query' subcommand is permitted"

    if len(argv) < 3:
        return None, "query subcommand name is required"

    subcommand = argv[2]
    if subcommand not in APPROVED_QUERY_SUBCOMMANDS:
        return None, (
            f"query subcommand '{subcommand}' is not approved; "
            f"allowed: {sorted(APPROVED_QUERY_SUBCOMMANDS)}"
        )

    has_json_output = False
    for i, arg in enumerate(argv):
        if arg in ("-o", "--output") and i + 1 < len(argv) and argv[i + 1] == "json":
            has_json_output = True
            break
        if arg in ("--output=json", "-o=json"):
            has_json_output = True
            break
    if not has_json_output:
        return None, (
            "explicit JSON output is required: use -o json or --output json"
        )

    return argv, None


def validate_query_base_dir(argv: list[str], tree_path: Path) -> str | None:
    """Validate --base-dir in a parsed arch-query argv.

    Returns None if valid, or an error string if the base-dir escapes the
    evaluated tree.
    """
    tree_resolved = tree_path.resolve()
    for i, arg in enumerate(argv):
        if arg == "--base-dir" and i + 1 < len(argv):
            base = Path(argv[i + 1]).resolve()
            if base != tree_resolved and tree_resolved not in base.parents:
                return (
                    f"--base-dir must be inside the evaluated tree "
                    f"({tree_resolved}), got {base}"
                )
            return None
        if arg.startswith("--base-dir="):
            base = Path(arg.split("=", 1)[1]).resolve()
            if base != tree_resolved and tree_resolved not in base.parents:
                return (
                    f"--base-dir must be inside the evaluated tree "
                    f"({tree_resolved}), got {base}"
                )
            return None
    return "--base-dir is required to anchor queries to the evaluated tree"


INDEX_PROMPT_GUIDANCE = """\

Index artifact:
An architecture context index is available at: {index_path}
This INDEX.md was generated from the architecture data (source revision: \
{source_revision}) and has passed provenance validation (format version: \
{format_version}, {component_count} components).
It is read-only evidence — use it to orient yourself on available components \
and their sections, but always cross-reference with the underlying architecture \
documents for detailed facts.
"""

QUERY_PROMPT_GUIDANCE = """\

Query tool:
You also have access to the arch-query CLI for structured fact retrieval.
Use it via Bash with commands like:
  arch-query query crds --component <name> --base-dir {tree_path} -o json
  arch-query query dependency-status --component <name> --base-dir {tree_path} -o json
  arch-query query config-sources --component <name> --base-dir {tree_path} -o json
  arch-query query diff --component <name> --from <v1> --to <v2> \
--base-dir {tree_path} -o json

Rules for query tool:
- Always use --base-dir {tree_path} to anchor queries to the architecture tree.
- Always use -o json for machine-readable output.
- Only these query subcommands are available: callers-of, config-sources, \
consumers-of, crds, dependency-status, diff.
- Do not use shell operators (pipes, redirects, semicolons, etc.).
- Query output is structured evidence, not authoritative — cross-reference \
with documentation when possible.
"""


class _EvalGuard:
    """Tool guard for evaluation agents.

    By default allows Read, Glob, Grep only. When query_enabled is True,
    also permits constrained arch-query invocations via Bash: only the
    approved binary, approved query subcommands, JSON output, and base-dir
    within the evaluated tree.
    """

    def __init__(
        self,
        tree_path: Path,
        *,
        query_enabled: bool = False,
        index_path: Path | None = None,
        context_exporter=None,
    ):
        self.tree = tree_path.resolve()
        self.query_enabled = query_enabled
        self.index_path = index_path.resolve() if index_path else None
        self.tool_calls: dict[str, int] = {}
        self.denied_calls: dict[str, int] = {}
        self.files_read: list[str] = []
        self._read_set: set[str] = set()
        self.query_calls: list[dict] = []
        route = "combined" if (query_enabled and index_path) else (
            "query" if query_enabled else (
                "index" if index_path else "baseline"
            )
        )
        self.ctx_telemetry = ContextTelemetryCollector(
            route=route, exporter=context_exporter,
        )

    async def pre_tool_use(self, data, _tool_use_id, _context):
        tool_name = str(data.get("tool_name", ""))
        tool_input = dict(data.get("tool_input", {}))
        self.tool_calls[tool_name] = self.tool_calls.get(tool_name, 0) + 1

        allowed_tools = {"Read", "Glob", "Grep"}
        if self.query_enabled:
            allowed_tools.add("Bash")

        if tool_name not in allowed_tools:
            self.denied_calls[tool_name] = (
                self.denied_calls.get(tool_name, 0) + 1
            )
            permitted_desc = "Read, Glob, and Grep"
            if self.query_enabled:
                permitted_desc += " (and Bash for arch-query queries)"
            reason = (
                f"{tool_name} is not permitted in evaluation mode. "
                f"Only {permitted_desc} are allowed."
            )
            self.ctx_telemetry.record_denied_read(detail=reason)
            return {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }

        if tool_name == "Bash":
            return self._check_query(tool_input)

        if tool_name == "Read":
            return self._check_read(tool_input)
        if tool_name in {"Glob", "Grep"}:
            return self._check_search(tool_input)
        return {}

    def _resolve(self, raw: str) -> Path | None:
        p = Path(raw)
        if p.is_absolute():
            return p.resolve()
        return (self.tree / p).resolve()

    def _in_tree(self, resolved: Path) -> bool:
        if resolved == self.tree or self.tree in resolved.parents:
            return True
        if self.index_path and resolved == self.index_path:
            return True
        return False

    def _check_read(self, tool_input: dict):
        raw = tool_input.get("file_path") or tool_input.get("path")
        if not raw:
            self.ctx_telemetry.record_denied_read(detail="Read requires a file path")
            return self._deny("Read", "Read requires a file path")
        resolved = self._resolve(str(raw))
        if resolved is None or not self._in_tree(resolved):
            self.ctx_telemetry.record_denied_read(
                file=str(raw), detail="reads must stay inside the architecture tree",
            )
            return self._deny("Read", "reads must stay inside the architecture tree")
        if _is_private_architecture_path(resolved):
            self.ctx_telemetry.record_denied_read(
                file=str(raw),
                detail=_PRIVATE_ARCHITECTURE_REASON,
            )
            return self._deny("Read", _PRIVATE_ARCHITECTURE_REASON)
        try:
            rel = str(resolved.relative_to(self.tree))
        except ValueError:
            rel = str(resolved)
        if rel not in self._read_set:
            self._read_set.add(rel)
            self.files_read.append(rel)
        is_index = self.index_path and resolved == self.index_path
        if is_index:
            self.ctx_telemetry.record_navigation_read(rel)
        else:
            self.ctx_telemetry.record_useful_read(rel)
        if not Path(str(raw)).is_absolute():
            updated = dict(tool_input)
            key = "file_path" if "file_path" in updated else "path"
            updated[key] = str(resolved)
            return self._allow(updated)
        return {}

    def _check_search(self, tool_input: dict):
        raw = tool_input.get("path", "")
        if not raw:
            tool_input["path"] = str(self.tree)
        else:
            resolved = self._resolve(str(raw))
            if resolved is None or not self._in_tree(resolved):
                self.ctx_telemetry.record_denied_read(
                    file=str(raw),
                    detail="search must stay inside the architecture tree",
                )
                return self._deny(
                    "search", "search must stay inside the architecture tree"
                )
            if _is_private_architecture_path(resolved):
                self.ctx_telemetry.record_denied_read(
                    file=str(raw),
                    detail=_PRIVATE_ARCHITECTURE_REASON,
                )
                return self._deny("search", _PRIVATE_ARCHITECTURE_REASON)
            if not Path(str(raw)).is_absolute():
                tool_input["path"] = str(resolved)
        self.ctx_telemetry.record_navigation_read(raw or str(self.tree))
        return self._allow(tool_input)

    def _deny(self, tool_name: str, reason: str):
        self.denied_calls[tool_name] = self.denied_calls.get(tool_name, 0) + 1
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }

    def _check_query(self, tool_input: dict):
        """Validate a Bash tool call as a constrained arch-query invocation."""
        command = tool_input.get("command", "")

        argv, error = parse_query_command(command)
        if error:
            self.query_calls.append({
                "command": command,
                "status": "denied",
                "reason": error,
            })
            self.denied_calls["Bash"] = (
                self.denied_calls.get("Bash", 0) + 1
            )
            self.ctx_telemetry.record_denied_query(detail=error)
            return self._deny("Bash", f"query denied: {error}")

        base_dir_error = validate_query_base_dir(argv, self.tree)
        if base_dir_error:
            self.query_calls.append({
                "command": command,
                "status": "denied",
                "reason": base_dir_error,
            })
            self.denied_calls["Bash"] = (
                self.denied_calls.get("Bash", 0) + 1
            )
            self.ctx_telemetry.record_denied_query(detail=base_dir_error)
            return self._deny("Bash", f"query denied: {base_dir_error}")

        self.query_calls.append({
            "command": command,
            "status": "allowed",
            "subcommand": argv[2],
        })
        self.ctx_telemetry.record_query()
        return {}

    @staticmethod
    def _allow(tool_input: dict):
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "updatedInput": tool_input,
            }
        }

    def telemetry(self) -> dict:
        telem = {
            "tool_calls": dict(sorted(self.tool_calls.items())),
            "denied_tool_calls": dict(sorted(self.denied_calls.items())),
            "files_read": self.files_read,
            "file_count": len(self.files_read),
            "context_metrics": self.ctx_telemetry.context_metrics(),
        }
        if self.query_enabled:
            allowed_queries = [
                q for q in self.query_calls if q["status"] == "allowed"
            ]
            denied_queries = [
                q for q in self.query_calls if q["status"] == "denied"
            ]
            telem["query_calls"] = self.query_calls
            telem["query_allowed_count"] = len(allowed_queries)
            telem["query_denied_count"] = len(denied_queries)
        if self.index_path:
            telem["index_artifact_path"] = str(self.index_path)
        return telem

    def context_provenance(self) -> dict:
        """Return context telemetry provenance for result records."""
        return {
            "context_telemetry_version": _CTX_CONTRACT_VERSION,
            "context_events": json.loads(self.ctx_telemetry.serialize()),
        }


async def run_question_against_tree(
    question: dict,
    tree_path: Path,
    tree_label: str,
    model: str,
    log_dir: Path,
    *,
    condition_plan: dict | None = None,
) -> dict:
    """Run a single question against one architecture tree."""
    from claude_agent_sdk import (
        ClaudeAgentOptions,
        ClaudeSDKClient,
        HookMatcher,
        ResultMessage,
    )

    from lib.agent_runner import get_model_id

    tree_resolved = tree_path.resolve()

    query_enabled = (
        condition_plan is not None
        and "arch-query" in (condition_plan.get("tools_permitted") or [])
    )
    index_path = None
    if condition_plan and condition_plan.get("index_artifact_path"):
        index_path = Path(condition_plan["index_artifact_path"])
    guard = _EvalGuard(
        tree_resolved,
        query_enabled=query_enabled,
        index_path=index_path,
    )

    system_prompt = SYSTEM_PROMPT_TEMPLATE.format(tree_path=tree_resolved)
    if query_enabled:
        system_prompt += QUERY_PROMPT_GUIDANCE.format(tree_path=tree_resolved)
    if index_path is not None:
        _idx_header = _parse_index_header(index_path)
        system_prompt += INDEX_PROMPT_GUIDANCE.format(
            index_path=index_path.resolve(),
            source_revision=_idx_header.get("source_revision", "unknown"),
            format_version=_idx_header.get("format_version", "unknown"),
            component_count=_idx_header.get("component_count", "unknown"),
        )

    user_prompt = question["question"]

    model_id = get_model_id(model)
    qid = question["id"]
    safe_name = f"{qid}_{tree_label}".replace("/", "_")
    log_file = log_dir / f"{safe_name}.log"

    allowed_tools = ["Read", "Glob", "Grep"]
    if query_enabled:
        allowed_tools.append("Bash")

    options = ClaudeAgentOptions(
        cwd=str(tree_resolved),
        allowed_tools=allowed_tools,
        permission_mode="bypassPermissions",
        model=model_id,
        system_prompt=system_prompt,
        setting_sources=None,
        env=_claude_sdk_env(),
        hooks={
            "PreToolUse": [
                HookMatcher(
                    matcher=None,
                    hooks=[guard.pre_tool_use],
                )
            ]
        },
    )

    with open(log_file, "w") as f:
        f.write(f"Question: {qid}\nTree: {tree_label} ({tree_resolved})\n")
        f.write(f"Model: {model_id}\n{'=' * 60}\n\n")

    start = time.monotonic()
    response_text = ""
    result_msg = None

    try:
        with open(log_file, "a") as log:
            async with ClaudeSDKClient(options=options) as client:
                await client.query(user_prompt)
                async for msg in client.receive_response():
                    log.write(f"{msg}\n")
                    log.flush()
                    if isinstance(msg, ResultMessage):
                        result_msg = msg
                        response_text = msg.result or ""
    except BaseException as e:
        if isinstance(e, (KeyboardInterrupt, SystemExit)):
            raise
        elapsed = time.monotonic() - start
        return {
            "question_id": qid,
            "tree": tree_label,
            "tree_path": str(tree_resolved),
            "success": False,
            "error": str(e),
            "response": "",
            "duration_seconds": round(elapsed, 2),
            "telemetry": guard.telemetry(),
            "context_metrics": guard.ctx_telemetry.context_metrics(),
            "context_provenance": guard.context_provenance(),
            "log_file": str(log_file),
        }

    elapsed = time.monotonic() - start

    telemetry = guard.telemetry()
    if result_msg is not None:
        telemetry.update({
            "duration_api_ms": result_msg.duration_api_ms,
            "num_turns": result_msg.num_turns,
            "total_cost_usd": result_msg.total_cost_usd,
            "usage": result_msg.usage or {},
            "model_usage": result_msg.model_usage or {},
            "model_id": model_id,
            "session_id": result_msg.session_id,
        })

    error_text = None
    if result_msg is not None and result_msg.is_error:
        errors = getattr(result_msg, "errors", None) or []
        error_text = "; ".join(str(error) for error in errors) or (
            "Claude evaluation failed"
        )
    error_text = error_text or _auth_failure_text(response_text)
    if error_text:
        return {
            "question_id": qid,
            "tree": tree_label,
            "tree_path": str(tree_resolved),
            "success": False,
            "error": error_text,
            "response": response_text,
            "duration_seconds": round(elapsed, 2),
            "telemetry": telemetry,
            "context_metrics": guard.ctx_telemetry.context_metrics(),
            "context_provenance": guard.context_provenance(),
            "log_file": str(log_file),
        }

    return {
        "question_id": qid,
        "tree": tree_label,
        "tree_path": str(tree_resolved),
        "success": True,
        "response": response_text,
        "duration_seconds": round(elapsed, 2),
        "telemetry": telemetry,
        "context_metrics": guard.ctx_telemetry.context_metrics(),
        "context_provenance": guard.context_provenance(),
        "log_file": str(log_file),
    }


async def run_question(
    question: dict,
    tree_a: Path,
    tree_b: Path,
    model: str,
    log_dir: Path,
    rng: random.Random,
    *,
    condition_plan: dict | None = None,
) -> dict:
    """Run one question against both trees in randomized order."""
    trees = [("tree_a", tree_a), ("tree_b", tree_b)]
    if rng.random() < 0.5:
        trees = list(reversed(trees))
    presentation_order = [t[0] for t in trees]

    results = {}
    for label, path in trees:
        results[label] = await run_question_against_tree(
            question, path, label, model, log_dir,
            condition_plan=condition_plan,
        )

    return {
        "question_id": question["id"],
        "tier": question["tier"],
        "consumer": question["consumer"],
        "question": question["question"],
        "expected_answer": question["expected_answer"],
        "not_documented_expected": question["not_documented_expected"],
        "presentation_order": presentation_order,
        "tree_a": results.get("tree_a"),
        "tree_b": results.get("tree_b"),
    }


async def run_evaluation(
    corpus_path: Path,
    tree_a: Path,
    tree_b: Path,
    model: str,
    output_dir: Path,
    max_concurrent: int,
    seed: int | None = None,
    condition_plan: dict | None = None,
) -> Path:
    """Run the full evaluation and write raw-results.json."""
    from lib.agent_runner import get_model_id

    with open(corpus_path) as f:
        corpus = json.load(f)

    questions = corpus["questions"]

    if condition_plan is not None:
        planned_ids = set(condition_plan["question_ids"])
        questions = [q for q in questions if q["id"] in planned_ids]

    rng = random.Random(seed if seed is not None else 42)
    output_dir.mkdir(parents=True, exist_ok=True)
    log_dir = output_dir / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    git_sha = "unknown"
    try:
        git_sha = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=str(REPO_ROOT),
            stderr=subprocess.DEVNULL,
        ).decode().strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    print(f"Evaluation: {len(questions)} questions x 2 trees")
    print(f"  Corpus: {corpus_path}")
    print(f"  Tree A: {tree_a.resolve()}")
    print(f"  Tree B: {tree_b.resolve()}")
    print(f"  Model:  {model} ({get_model_id(model)})")
    print(f"  Output: {output_dir}")
    print(f"  Concurrency: {max_concurrent}")
    print()

    semaphore = asyncio.Semaphore(max_concurrent)
    start_time = time.monotonic()

    async def _run_with_limit(q: dict, idx: int) -> dict:
        async with semaphore:
            print(f"[{idx + 1}/{len(questions)}] {q['id']}: {q['question'][:60]}...")
            result = await run_question(
                q, tree_a, tree_b, model, log_dir, rng,
                condition_plan=condition_plan,
            )
            elapsed = time.monotonic() - start_time
            print(f"  Done {q['id']} ({elapsed:.0f}s elapsed)")
            return result

    tasks = [_run_with_limit(q, i) for i, q in enumerate(questions)]
    question_results = await asyncio.gather(*tasks)

    total_elapsed = time.monotonic() - start_time

    raw_results = {
        "corpus_version": corpus.get("corpus_version"),
        "architecture_context_version": corpus.get("architecture_context_version"),
        "model": model,
        "model_id": get_model_id(model),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "git_sha": git_sha,
        "seed": seed if seed is not None else 42,
        "tree_a_path": str(tree_a.resolve()),
        "tree_b_path": str(tree_b.resolve()),
        "total_questions": len(questions),
        "total_duration_seconds": round(total_elapsed, 2),
        "max_concurrent": max_concurrent,
        "results": list(question_results),
    }

    if condition_plan is not None:
        raw_results["condition_id"] = condition_plan["condition_id"]
        raw_results["condition_available"] = condition_plan["available"]
        provenance = {
            "condition_id": condition_plan["condition_id"],
            "artifact_identity": condition_plan.get("artifact_identity"),
            "access_boundary": condition_plan.get("access_boundary"),
            "tools_permitted": condition_plan.get("tools_permitted"),
            "tools_denied": condition_plan.get("tools_denied"),
            "context_telemetry_version": _CTX_CONTRACT_VERSION,
            "context_provenance": {
                "context_telemetry_version": _CTX_CONTRACT_VERSION,
                "events_attached_per_tree": True,
            },
        }
        query_enabled = "arch-query" in (
            condition_plan.get("tools_permitted") or []
        )
        if query_enabled:
            provenance["query_enabled"] = True
            provenance["approved_query_subcommands"] = sorted(
                APPROVED_QUERY_SUBCOMMANDS
            )
        raw_results["provenance"] = provenance

    output_path = output_dir / "raw-results.json"
    with open(output_path, "w") as f:
        json.dump(raw_results, f, indent=2)
    print(f"\nWrote {output_path} ({len(question_results)} questions)")
    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="Run benchmark questions against two architecture doc trees.",
    )
    parser.add_argument(
        "--corpus",
        type=Path,
        default=Path(__file__).parent / "corpus.json",
        help="Path to corpus.json (default: %(default)s)",
    )
    parser.add_argument(
        "--tree-a",
        type=Path,
        default=None,
        help="Path to first architecture doc tree (baseline)",
    )
    parser.add_argument(
        "--tree-b",
        type=Path,
        default=None,
        help="Path to second architecture doc tree (candidate)",
    )
    parser.add_argument(
        "--model",
        default="opus",
        help="Model shorthand: opus, sonnet, haiku (default: %(default)s)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("benchmark/consumer-v1/results"),
        help="Output directory for results (default: %(default)s)",
    )
    parser.add_argument(
        "--max-concurrent",
        type=int,
        default=1,
        help="Max concurrent agent sessions (default: %(default)s)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for presentation order (default: %(default)s)",
    )
    parser.add_argument(
        "--check-isolation",
        action="store_true",
        help="Error out if ~/.claude/ or CLAUDE.md exists (container negative control)",
    )
    parser.add_argument(
        "--condition",
        default="baseline",
        help="Condition ID from experiment manifest (default: %(default)s)",
    )
    parser.add_argument(
        "--condition-manifest",
        type=Path,
        default=REPO_ROOT / "benchmark" / "analyzer-assisted-v1" / "experiment.json",
        help="Path to experiment.json (default: %(default)s)",
    )
    parser.add_argument(
        "--question-id",
        action="append",
        dest="question_ids",
        help="Question ID subset (repeatable). Omit for all active.",
    )
    parser.add_argument(
        "--artifact-json",
        type=str,
        default=None,
        help="Artifact identity as JSON string or @file path.",
    )
    parser.add_argument(
        "--index-artifact-path",
        type=str,
        default=None,
        help="Path to materialized INDEX.md (required for index-md/combined).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print evaluation plan as JSON and exit without launching agents.",
    )
    args = parser.parse_args()

    # Parse artifact identity
    artifact_identity = None
    if args.artifact_json is not None:
        raw = args.artifact_json
        if raw.startswith("@"):
            with open(raw[1:]) as f:
                artifact_identity = json.load(f)
        else:
            artifact_identity = json.loads(raw)

    # Auto-construct for baseline backward compatibility
    if artifact_identity is None and args.condition == "baseline":
        artifact_identity = {
            "type": "architecture-tree",
            "revision_source": "git_sha",
        }

    # Load manifest and validate condition (preflight)
    try:
        manifest = _planner.load_manifest(args.condition_manifest)
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        print(f"Error loading condition manifest: {exc}", file=sys.stderr)
        sys.exit(1)

    try:
        plan = _planner.plan_condition(
            manifest,
            args.condition,
            question_ids=args.question_ids,
            artifact_identity=artifact_identity,
            index_artifact_path=args.index_artifact_path,
        )
    except ValueError as exc:
        print(f"Condition planning failed: {exc}", file=sys.stderr)
        sys.exit(1)

    # Dry-run: print deterministic plan and exit
    if args.dry_run:
        json.dump(plan, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        sys.exit(0)

    # Unavailable condition: emit deterministic result and exit
    if not plan["available"]:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        unavailable_result = dict(plan)
        unavailable_result["condition_unavailable"] = True
        unavailable_result["condition_available"] = False
        output_path = args.output_dir / "raw-results.json"
        with open(output_path, "w") as f:
            json.dump(unavailable_result, f, indent=2, sort_keys=True)
        print(
            f"Condition '{args.condition}' is unavailable: "
            f"{plan['unavailable_reason']}"
        )
        print(f"Wrote {output_path}")
        sys.exit(0)

    # Available condition: validate required paths
    if args.check_isolation:
        check_isolation()

    if args.tree_a is None:
        print(
            "error: --tree-a is required for available conditions",
            file=sys.stderr,
        )
        sys.exit(1)
    if args.tree_b is None:
        print(
            "error: --tree-b is required for available conditions",
            file=sys.stderr,
        )
        sys.exit(1)
    if not args.corpus.exists():
        print(f"error: Corpus not found: {args.corpus}", file=sys.stderr)
        sys.exit(1)
    if not args.tree_a.exists():
        print(f"error: Tree A not found: {args.tree_a}", file=sys.stderr)
        sys.exit(1)
    if not args.tree_b.exists():
        print(f"error: Tree B not found: {args.tree_b}", file=sys.stderr)
        sys.exit(1)

    asyncio.run(run_evaluation(
        corpus_path=args.corpus,
        tree_a=args.tree_a,
        tree_b=args.tree_b,
        model=args.model,
        output_dir=args.output_dir,
        max_concurrent=args.max_concurrent,
        seed=args.seed,
        condition_plan=plan,
    ))


if __name__ == "__main__":
    main()
