"""Tests for the query-aware evaluation boundary.

Validates that arch-query access is opt-in per condition, commands are
constrained to approved subcommands, base-dir stays inside the tree,
shell operators are denied, telemetry records queries, and baseline
behavior is unchanged.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RUNNER_PATH = PROJECT_ROOT / "benchmark" / "consumer-v1" / "run_evaluation.py"

_spec = importlib.util.spec_from_file_location("run_evaluation", RUNNER_PATH)
_mod = importlib.util.module_from_spec(_spec)
sys.path.insert(0, str(PROJECT_ROOT))
_spec.loader.exec_module(_mod)

APPROVED_QUERY_SUBCOMMANDS = _mod.APPROVED_QUERY_SUBCOMMANDS
QUERY_PROMPT_GUIDANCE = _mod.QUERY_PROMPT_GUIDANCE
SYSTEM_PROMPT_TEMPLATE = _mod.SYSTEM_PROMPT_TEMPLATE
_EvalGuard = _mod._EvalGuard
parse_query_command = _mod.parse_query_command
validate_query_base_dir = _mod.validate_query_base_dir


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _run_cli(extra_args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(RUNNER_PATH)] + extra_args,
        capture_output=True,
        text=True,
    )


def _make_guard(tmp_path: Path, *, query_enabled: bool = False) -> _EvalGuard:
    tree = tmp_path / "arch-tree"
    tree.mkdir(exist_ok=True)
    return _EvalGuard(tree, query_enabled=query_enabled)


async def _call_guard(guard: _EvalGuard, tool_name: str, tool_input: dict):
    return await guard.pre_tool_use(
        {"tool_name": tool_name, "tool_input": tool_input},
        "test-id",
        None,
    )


# ---------------------------------------------------------------------------
# parse_query_command
# ---------------------------------------------------------------------------

class TestParseQueryCommand:
    """Validates command parsing and constraint enforcement."""

    def test_valid_crds_command(self):
        argv, err = parse_query_command(
            "arch-query query crds --component foo -o json"
        )
        assert err is None
        assert argv[0] == "arch-query"
        assert argv[1] == "query"
        assert argv[2] == "crds"

    def test_all_approved_subcommands(self):
        for sub in sorted(APPROVED_QUERY_SUBCOMMANDS):
            argv, err = parse_query_command(f"arch-query query {sub} -o json")
            assert err is None, f"subcommand {sub} should be approved"
            assert argv[2] == sub

    def test_unapproved_subcommand_denied(self):
        argv, err = parse_query_command("arch-query query list")
        assert argv is None
        assert "not approved" in err

    def test_wrong_binary_denied(self):
        argv, err = parse_query_command("curl http://example.com")
        assert argv is None
        assert "only the bare 'arch-query'" in err

    def test_arch_query_without_query_subcommand(self):
        argv, err = parse_query_command("arch-query list")
        assert argv is None
        assert "only 'arch-query query'" in err

    def test_arch_query_query_without_subcommand_name(self):
        argv, err = parse_query_command("arch-query query")
        assert argv is None
        assert "subcommand name is required" in err

    def test_empty_command(self):
        argv, err = parse_query_command("")
        assert argv is None
        assert "empty command" in err

    def test_shell_pipe_denied(self):
        argv, err = parse_query_command("arch-query query crds | cat")
        assert argv is None
        assert "shell operators" in err

    def test_shell_semicolon_denied(self):
        argv, err = parse_query_command("arch-query query crds; rm -rf /")
        assert argv is None
        assert "shell operators" in err

    def test_shell_backtick_denied(self):
        argv, err = parse_query_command("arch-query query crds `whoami`")
        assert argv is None
        assert "shell operators" in err

    def test_shell_dollar_paren_denied(self):
        argv, err = parse_query_command("arch-query query crds $(whoami)")
        assert argv is None
        assert "shell operators" in err

    def test_shell_ampersand_denied(self):
        argv, err = parse_query_command("arch-query query crds & echo pwned")
        assert argv is None
        assert "shell operators" in err

    def test_shell_redirect_denied(self):
        argv, err = parse_query_command("arch-query query crds > /tmp/out")
        assert argv is None
        assert "shell operators" in err

    def test_absolute_path_binary_rejected(self):
        argv, err = parse_query_command(
            "/usr/local/bin/arch-query query crds --component foo -o json"
        )
        assert argv is None
        assert "only the bare 'arch-query'" in err

    def test_relative_path_binary_rejected(self):
        argv, err = parse_query_command(
            "./arch-query query crds --component foo -o json"
        )
        assert argv is None
        assert "only the bare 'arch-query'" in err

    def test_quoted_args_parsed(self):
        argv, err = parse_query_command(
            'arch-query query crds --component "my component" -o json'
        )
        assert err is None
        assert "my component" in argv

    def test_missing_output_flag_rejected(self):
        argv, err = parse_query_command(
            "arch-query query crds --component foo"
        )
        assert argv is None
        assert "JSON output is required" in err

    def test_non_json_output_rejected(self):
        argv, err = parse_query_command(
            "arch-query query crds --component foo -o table"
        )
        assert argv is None
        assert "JSON output is required" in err

    def test_output_long_form_json_accepted(self):
        argv, err = parse_query_command(
            "arch-query query crds --output json --component foo"
        )
        assert err is None
        assert argv[2] == "crds"

    def test_output_equals_json_accepted(self):
        argv, err = parse_query_command(
            "arch-query query crds --output=json --component foo"
        )
        assert err is None
        assert argv[2] == "crds"


# ---------------------------------------------------------------------------
# validate_query_base_dir
# ---------------------------------------------------------------------------

class TestValidateQueryBaseDir:
    """Validates --base-dir path enforcement."""

    def test_base_dir_inside_tree_ok(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        argv = ["arch-query", "query", "crds", "--base-dir", str(tree)]
        assert validate_query_base_dir(argv, tree) is None

    def test_base_dir_subdir_of_tree_ok(self, tmp_path):
        tree = tmp_path / "arch-tree"
        sub = tree / "rhoai" / "next"
        sub.mkdir(parents=True)
        argv = ["arch-query", "query", "crds", "--base-dir", str(sub)]
        assert validate_query_base_dir(argv, tree) is None

    def test_base_dir_outside_tree_denied(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        other = tmp_path / "other"
        other.mkdir()
        argv = ["arch-query", "query", "crds", "--base-dir", str(other)]
        err = validate_query_base_dir(argv, tree)
        assert err is not None
        assert "must be inside" in err

    def test_base_dir_equals_form(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        other = tmp_path / "other"
        other.mkdir()
        argv = ["arch-query", "query", "crds", f"--base-dir={other}"]
        err = validate_query_base_dir(argv, tree)
        assert err is not None
        assert "must be inside" in err

    def test_no_base_dir_rejected(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        argv = ["arch-query", "query", "crds", "--component", "foo"]
        err = validate_query_base_dir(argv, tree)
        assert err is not None
        assert "--base-dir is required" in err

    def test_base_dir_traversal_denied(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        traversal = str(tree / ".." / "other")
        argv = ["arch-query", "query", "crds", "--base-dir", traversal]
        err = validate_query_base_dir(argv, tree)
        assert err is not None
        assert "must be inside" in err


# ---------------------------------------------------------------------------
# _EvalGuard: opt-in permission gating
# ---------------------------------------------------------------------------

class TestEvalGuardPermissionGating:
    """Query access is unavailable unless explicitly enabled."""

    @pytest.mark.asyncio
    async def test_bash_denied_without_query_enabled(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=False)
        result = await _call_guard(guard, "Bash", {
            "command": "arch-query query crds --component foo"
        })
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_bash_allowed_with_query_enabled_valid_command(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree_str = str(guard.tree)
        cmd = (
            f"arch-query query crds --component foo"
            f" --base-dir {tree_str} -o json"
        )
        result = await _call_guard(guard, "Bash", {"command": cmd})
        assert result == {} or result.get("hookSpecificOutput", {}).get(
            "permissionDecision"
        ) != "deny"

    @pytest.mark.asyncio
    async def test_write_denied_even_with_query_enabled(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Write", {"path": "/tmp/x"})
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_edit_denied_even_with_query_enabled(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Edit", {"path": "/tmp/x"})
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_read_still_works_with_query_enabled(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree = guard.tree
        test_file = tree / "test.md"
        test_file.write_text("hello")
        result = await _call_guard(guard, "Read", {
            "file_path": str(test_file)
        })
        assert result == {} or result.get("hookSpecificOutput", {}).get(
            "permissionDecision"
        ) != "deny"

    @pytest.mark.asyncio
    async def test_glob_still_works_with_query_enabled(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Glob", {"path": str(guard.tree)})
        assert result.get("hookSpecificOutput", {}).get(
            "permissionDecision"
        ) != "deny"

    @pytest.mark.asyncio
    async def test_grep_still_works_with_query_enabled(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Grep", {"path": str(guard.tree)})
        assert result.get("hookSpecificOutput", {}).get(
            "permissionDecision"
        ) != "deny"


# ---------------------------------------------------------------------------
# _EvalGuard: command validation via Bash
# ---------------------------------------------------------------------------

class TestEvalGuardQueryValidation:
    """Bash commands are only allowed when they are valid arch-query invocations."""

    @pytest.mark.asyncio
    async def test_arbitrary_bash_denied(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Bash", {"command": "ls -la"})
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"
        reason = result["hookSpecificOutput"]["permissionDecisionReason"]
        assert "only the bare 'arch-query'" in reason

    @pytest.mark.asyncio
    async def test_rm_denied(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Bash", {"command": "rm -rf /"})
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_pipe_in_query_denied(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Bash", {
            "command": "arch-query query crds | jq ."
        })
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_unapproved_subcommand_denied(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Bash", {
            "command": "arch-query query platform-summary"
        })
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_arch_query_non_query_denied(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Bash", {
            "command": "arch-query list"
        })
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_base_dir_escape_denied(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Bash", {
            "command": "arch-query query crds --base-dir /tmp -o json"
        })
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_missing_base_dir_denied(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        result = await _call_guard(guard, "Bash", {
            "command": "arch-query query crds --component foo -o json"
        })
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"
        reason = result["hookSpecificOutput"]["permissionDecisionReason"]
        assert "--base-dir is required" in reason

    @pytest.mark.asyncio
    async def test_valid_query_with_base_dir_allowed(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree_str = str(guard.tree)
        cmd = (
            f"arch-query query crds --component foo"
            f" --base-dir {tree_str} -o json"
        )
        result = await _call_guard(guard, "Bash", {"command": cmd})
        assert result == {}


# ---------------------------------------------------------------------------
# _EvalGuard: telemetry
# ---------------------------------------------------------------------------

class TestEvalGuardTelemetry:
    """Query telemetry is recorded for allowed and denied queries."""

    @pytest.mark.asyncio
    async def test_allowed_query_in_telemetry(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree_str = str(guard.tree)
        cmd = (
            f"arch-query query crds --component foo"
            f" --base-dir {tree_str} -o json"
        )
        await _call_guard(guard, "Bash", {"command": cmd})
        telem = guard.telemetry()
        assert telem["query_allowed_count"] == 1
        assert telem["query_denied_count"] == 0
        assert len(telem["query_calls"]) == 1
        assert telem["query_calls"][0]["status"] == "allowed"
        assert telem["query_calls"][0]["subcommand"] == "crds"

    @pytest.mark.asyncio
    async def test_denied_query_in_telemetry(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        await _call_guard(guard, "Bash", {"command": "ls -la"})
        telem = guard.telemetry()
        assert telem["query_allowed_count"] == 0
        assert telem["query_denied_count"] == 1
        assert telem["query_calls"][0]["status"] == "denied"

    @pytest.mark.asyncio
    async def test_mixed_query_telemetry(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree_str = str(guard.tree)
        cmd_crds = (
            f"arch-query query crds --component foo"
            f" --base-dir {tree_str} -o json"
        )
        cmd_diff = (
            f"arch-query query diff --component bar"
            f" --from v1 --to v2"
            f" --base-dir {tree_str} -o json"
        )
        await _call_guard(guard, "Bash", {"command": cmd_crds})
        await _call_guard(guard, "Bash", {"command": "ls -la"})
        await _call_guard(guard, "Bash", {"command": cmd_diff})
        telem = guard.telemetry()
        assert telem["query_allowed_count"] == 2
        assert telem["query_denied_count"] == 1
        assert len(telem["query_calls"]) == 3

    @pytest.mark.asyncio
    async def test_no_query_telemetry_without_query_enabled(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=False)
        fp = str(tmp_path / "arch-tree" / "x")
        await _call_guard(guard, "Read", {"file_path": fp})
        telem = guard.telemetry()
        assert "query_calls" not in telem
        assert "query_allowed_count" not in telem

    @pytest.mark.asyncio
    async def test_tool_calls_counter_includes_bash(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        tree_str = str(guard.tree)
        cmd = (
            f"arch-query query crds --component foo"
            f" --base-dir {tree_str} -o json"
        )
        await _call_guard(guard, "Bash", {"command": cmd})
        telem = guard.telemetry()
        assert telem["tool_calls"]["Bash"] == 1

    @pytest.mark.asyncio
    async def test_denied_bash_in_denied_tool_calls(self, tmp_path):
        guard = _make_guard(tmp_path, query_enabled=True)
        await _call_guard(guard, "Bash", {"command": "ls"})
        telem = guard.telemetry()
        assert telem["denied_tool_calls"]["Bash"] >= 1


# ---------------------------------------------------------------------------
# Baseline compatibility: _EvalGuard without query
# ---------------------------------------------------------------------------

class TestBaselineGuardUnchanged:
    """Default _EvalGuard (query_enabled=False) behavior is preserved."""

    @pytest.mark.asyncio
    async def test_read_allowed(self, tmp_path):
        guard = _make_guard(tmp_path)
        tree = guard.tree
        f = tree / "doc.md"
        f.write_text("content")
        result = await _call_guard(guard, "Read", {"file_path": str(f)})
        assert result == {} or result.get("hookSpecificOutput", {}).get(
            "permissionDecision"
        ) != "deny"

    @pytest.mark.asyncio
    async def test_glob_allowed(self, tmp_path):
        guard = _make_guard(tmp_path)
        result = await _call_guard(guard, "Glob", {"path": str(guard.tree)})
        assert result.get("hookSpecificOutput", {}).get(
            "permissionDecision"
        ) != "deny"

    @pytest.mark.asyncio
    async def test_grep_allowed(self, tmp_path):
        guard = _make_guard(tmp_path)
        result = await _call_guard(guard, "Grep", {"path": str(guard.tree)})
        assert result.get("hookSpecificOutput", {}).get(
            "permissionDecision"
        ) != "deny"

    @pytest.mark.asyncio
    async def test_bash_denied(self, tmp_path):
        guard = _make_guard(tmp_path)
        result = await _call_guard(guard, "Bash", {"command": "echo hi"})
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"
        reason = result["hookSpecificOutput"]["permissionDecisionReason"]
        assert "Read, Glob, and Grep" in reason

    @pytest.mark.asyncio
    async def test_write_denied(self, tmp_path):
        guard = _make_guard(tmp_path)
        result = await _call_guard(guard, "Write", {"path": "/tmp/x"})
        assert result["hookSpecificOutput"]["permissionDecision"] == "deny"

    @pytest.mark.asyncio
    async def test_baseline_telemetry_shape(self, tmp_path):
        guard = _make_guard(tmp_path)
        telem = guard.telemetry()
        assert "tool_calls" in telem
        assert "denied_tool_calls" in telem
        assert "files_read" in telem
        assert "file_count" in telem
        assert "query_calls" not in telem


# ---------------------------------------------------------------------------
# Condition-aware prompt guidance
# ---------------------------------------------------------------------------

class TestPromptGuidance:
    """System prompt includes query guidance only when query is enabled."""

    def test_baseline_prompt_no_query_guidance(self):
        prompt = SYSTEM_PROMPT_TEMPLATE.format(tree_path="/some/tree")
        assert "arch-query" not in prompt
        assert "Query tool" not in prompt

    def test_query_prompt_includes_guidance(self):
        prompt = SYSTEM_PROMPT_TEMPLATE.format(tree_path="/some/tree")
        prompt += QUERY_PROMPT_GUIDANCE.format(tree_path="/some/tree")
        assert "arch-query" in prompt
        assert "Query tool" in prompt
        assert "--base-dir /some/tree" in prompt
        for sub in APPROVED_QUERY_SUBCOMMANDS:
            assert sub in prompt or sub in QUERY_PROMPT_GUIDANCE


# ---------------------------------------------------------------------------
# CLI integration: dry-run with arch-query condition
# ---------------------------------------------------------------------------

class TestArchQueryConditionDryRun:
    """Dry-run for arch-query condition shows query in tools_permitted."""

    def test_arch_query_dry_run_has_query_tool(self):
        result = _run_cli(["--condition", "arch-query", "--dry-run"])
        assert result.returncode == 0, f"stderr: {result.stderr}"
        plan = json.loads(result.stdout)
        assert "arch-query" in plan["tools_permitted"]

    def test_baseline_dry_run_no_query_tool(self):
        result = _run_cli(["--condition", "baseline", "--dry-run"])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert "arch-query" not in plan["tools_permitted"]

    def test_arch_query_still_pending(self):
        result = _run_cli(["--condition", "arch-query", "--dry-run"])
        plan = json.loads(result.stdout)
        assert plan["available"] is False


# ---------------------------------------------------------------------------
# Approved subcommands constant
# ---------------------------------------------------------------------------

class TestApprovedSubcommands:
    """The approved set matches the experiment manifest."""

    def test_matches_manifest_description(self):
        expected = {
            "callers-of", "consumers-of", "config-sources",
            "crds", "dependency-status", "diff",
        }
        assert APPROVED_QUERY_SUBCOMMANDS == expected

    def test_is_frozen(self):
        assert isinstance(APPROVED_QUERY_SUBCOMMANDS, frozenset)
