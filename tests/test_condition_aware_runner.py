"""Tests for condition-aware evaluation runner integration.

Tests the --condition, --dry-run, --question-id, and --artifact-json
CLI options added to run_evaluation.py, without launching agents or
running paid evaluations.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RUNNER_PATH = PROJECT_ROOT / "benchmark" / "consumer-v1" / "run_evaluation.py"
MANIFEST_PATH = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "experiment.json"
)


_ARCH_QUERY_ARTIFACT_JSON = json.dumps({
    "type": "architecture-tree-with-query",
    "revision_source": "git_sha",
    "query_binary_version": "test-sha",
})


def _run(extra_args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(RUNNER_PATH)] + extra_args,
        capture_output=True,
        text=True,
    )


class TestDryRun:
    """--dry-run prints the planner's sorted JSON plan and exits 0."""

    def test_baseline_dry_run(self):
        result = _run(["--condition", "baseline", "--dry-run"])
        assert result.returncode == 0, f"stderr: {result.stderr}"
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "baseline"
        assert plan["available"] is True

    def test_combined_dry_run(self):
        _INDEX_PATH = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        _COMBINED_ARTIFACT_JSON = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        result = _run([
            "--condition", "combined",
            "--artifact-json", _COMBINED_ARTIFACT_JSON,
            "--index-artifact-path", _INDEX_PATH,
            "--dry-run",
        ])
        assert result.returncode == 0, f"stderr: {result.stderr}"
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "combined"
        assert plan["available"] is True
        assert plan["index_artifact_path"] == _INDEX_PATH

    def test_dry_run_does_not_require_tree_paths(self):
        result = _run(["--condition", "baseline", "--dry-run"])
        assert result.returncode == 0, f"stderr: {result.stderr}"

    def test_dry_run_with_question_subset(self):
        result = _run([
            "--condition", "baseline",
            "--question-id", "INV-001",
            "--question-id", "FACT-001",
            "--dry-run",
        ])
        assert result.returncode == 0, f"stderr: {result.stderr}"
        plan = json.loads(result.stdout)
        assert plan["question_ids"] == ["FACT-001", "INV-001"]

    def test_dry_run_output_is_sorted_json(self):
        result = _run(["--condition", "baseline", "--dry-run"])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert list(plan.keys()) == sorted(plan.keys())

    def test_dry_run_all_conditions(self):
        _INDEX_PATH = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        _INDEX_MD_ARTIFACT_JSON = json.dumps({
            "type": "architecture-tree-with-index",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
        })
        _COMBINED_ARTIFACT_JSON = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        for cid in ("baseline", "index-md", "arch-query", "combined"):
            extra = []
            if cid == "arch-query":
                extra = ["--artifact-json", _ARCH_QUERY_ARTIFACT_JSON]
            elif cid == "index-md":
                extra = [
                    "--artifact-json", _INDEX_MD_ARTIFACT_JSON,
                    "--index-artifact-path", _INDEX_PATH,
                ]
            elif cid == "combined":
                extra = [
                    "--artifact-json", _COMBINED_ARTIFACT_JSON,
                    "--index-artifact-path", _INDEX_PATH,
                ]
            result = _run(["--condition", cid, "--dry-run"] + extra)
            assert result.returncode == 0, f"{cid} stderr: {result.stderr}"
            plan = json.loads(result.stdout)
            assert plan["condition_id"] == cid

    def test_dry_run_with_explicit_artifact(self):
        custom = {"type": "custom-tree", "revision_source": "manual"}
        result = _run([
            "--condition", "baseline",
            "--artifact-json", json.dumps(custom),
            "--dry-run",
        ])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert plan["artifact_identity"]["type"] == "custom-tree"


class TestCombinedNoSilentFallback:
    """Combined requires both index and query provenance — never silently falls back."""

    def test_combined_without_artifact_fails(self):
        result = _run([
            "--condition", "combined",
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "artifact_identity" in result.stderr

    def test_combined_without_index_path_fails(self):
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        result = _run([
            "--condition", "combined",
            "--artifact-json", artifact,
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "index_artifact_path" in result.stderr

    def test_combined_without_query_provenance_fails(self):
        _INDEX_PATH = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
        })
        result = _run([
            "--condition", "combined",
            "--artifact-json", artifact,
            "--index-artifact-path", _INDEX_PATH,
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "query_binary_version" in result.stderr

    def test_combined_without_index_provenance_fails(self):
        _INDEX_PATH = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "query_binary_version": "test-binary-sha",
        })
        result = _run([
            "--condition", "combined",
            "--artifact-json", artifact,
            "--index-artifact-path", _INDEX_PATH,
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "index_revision_source" in result.stderr

    def test_combined_never_emits_baseline_id(self):
        _INDEX_PATH = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        result = _run([
            "--condition", "combined",
            "--artifact-json", artifact,
            "--index-artifact-path", _INDEX_PATH,
            "--dry-run",
        ])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "combined"
        assert plan["condition_id"] != "baseline"

    def test_combined_plan_is_deterministic(self):
        _INDEX_PATH = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        plans = []
        for _ in range(2):
            result = _run([
                "--condition", "combined",
                "--artifact-json", artifact,
                "--index-artifact-path", _INDEX_PATH,
                "--dry-run",
            ])
            assert result.returncode == 0
            plans.append(json.loads(result.stdout))
        assert plans[0] == plans[1]

    def test_combined_plan_has_sorted_keys(self):
        _INDEX_PATH = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        result = _run([
            "--condition", "combined",
            "--artifact-json", artifact,
            "--index-artifact-path", _INDEX_PATH,
            "--dry-run",
        ])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert list(plan.keys()) == sorted(plan.keys())


class TestBaselineCompatibility:
    """Baseline adds condition_id, condition_available, provenance fields."""

    def test_baseline_plan_has_condition_fields(self):
        result = _run(["--condition", "baseline", "--dry-run"])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "baseline"
        assert plan["available"] is True
        assert plan["artifact_identity"] is not None

    def test_baseline_auto_constructs_artifact_identity(self):
        result = _run(["--condition", "baseline", "--dry-run"])
        plan = json.loads(result.stdout)
        ai = plan["artifact_identity"]
        assert ai["type"] == "architecture-tree"
        assert ai["revision_source"] == "git_sha"

    def test_baseline_explicit_artifact_overrides_default(self):
        custom = {"type": "custom-tree", "revision_source": "manual"}
        result = _run([
            "--condition", "baseline",
            "--artifact-json", json.dumps(custom),
            "--dry-run",
        ])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert plan["artifact_identity"]["type"] == "custom-tree"

    def test_baseline_37_questions_default(self):
        result = _run(["--condition", "baseline", "--dry-run"])
        plan = json.loads(result.stdout)
        assert len(plan["question_ids"]) == 40

    def test_baseline_preserves_tools(self):
        result = _run(["--condition", "baseline", "--dry-run"])
        plan = json.loads(result.stdout)
        assert "Read" in plan["tools_permitted"]
        assert "Glob" in plan["tools_permitted"]
        assert "Grep" in plan["tools_permitted"]

    def test_baseline_requires_trees_for_non_dry_run(self):
        result = _run(["--condition", "baseline"])
        assert result.returncode != 0
        assert "--tree-a" in result.stderr


class TestPreflightValidation:
    """Unknown/invalid question IDs and conditions fail before agent launch."""

    def test_unknown_question_id_fails(self):
        result = _run([
            "--condition", "baseline",
            "--question-id", "INV-999",
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "Unknown question_id" in result.stderr

    def test_invalid_question_format_fails(self):
        result = _run([
            "--condition", "baseline",
            "--question-id", "bad-format",
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "Invalid question_id" in result.stderr

    def test_unknown_condition_fails(self):
        result = _run(["--condition", "nonexistent", "--dry-run"])
        assert result.returncode != 0
        assert "Unknown condition_id" in result.stderr

    def test_duplicate_question_id_fails(self):
        result = _run([
            "--condition", "baseline",
            "--question-id", "INV-001",
            "--question-id", "INV-001",
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "Duplicate" in result.stderr

    def test_nonexistent_question_id_fails(self):
        result = _run([
            "--condition", "baseline",
            "--question-id", "NAV-099",
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "Unknown question_id" in result.stderr

    def test_validation_runs_before_tree_check(self):
        """Preflight catches bad question IDs even without tree paths."""
        result = _run([
            "--condition", "baseline",
            "--question-id", "BOGUS-001",
        ])
        assert result.returncode != 0
        assert "question_id" in result.stderr

    def test_bad_manifest_path_fails(self):
        result = _run([
            "--condition", "baseline",
            "--condition-manifest", "/nonexistent/experiment.json",
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "Error loading" in result.stderr


class TestNoSDKRequired:
    """Planning paths must work without claude_agent_sdk installed."""

    @staticmethod
    def _run_with_blocked_sdk(extra_args: list[str]) -> subprocess.CompletedProcess:
        blocker = (
            "import builtins, sys, runpy\n"
            "_real_import = builtins.__import__\n"
            "def _blocked(name, *a, **kw):\n"
            "    if name == 'claude_agent_sdk'"
            " or name.startswith('claude_agent_sdk.'):\n"
            "        raise ImportError(f'{name} blocked by test')\n"
            "    return _real_import(name, *a, **kw)\n"
            "builtins.__import__ = _blocked\n"
            f"sys.argv = {['run_evaluation.py'] + extra_args!r}\n"
            f"runpy.run_path({str(RUNNER_PATH)!r}, run_name='__main__')\n"
        )
        return subprocess.run(
            [sys.executable, "-c", blocker],
            capture_output=True,
            text=True,
        )

    def test_dry_run_without_sdk(self):
        result = self._run_with_blocked_sdk([
            "--condition", "baseline", "--dry-run",
        ])
        assert result.returncode == 0, (
            f"dry-run imported claude_agent_sdk:\n{result.stderr}"
        )
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "baseline"

    def test_combined_dry_run_without_sdk(self):
        _INDEX_PATH = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        result = self._run_with_blocked_sdk([
            "--condition", "combined",
            "--artifact-json", artifact,
            "--index-artifact-path", _INDEX_PATH,
            "--dry-run",
        ])
        assert result.returncode == 0, (
            f"combined dry-run imported claude_agent_sdk:\n{result.stderr}"
        )
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "combined"
        assert plan["available"] is True
