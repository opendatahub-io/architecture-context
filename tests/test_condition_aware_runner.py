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

    def test_pending_dry_run(self):
        result = _run(["--condition", "index-md", "--dry-run"])
        assert result.returncode == 0, f"stderr: {result.stderr}"
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "index-md"
        assert plan["available"] is False
        assert plan["unavailable_reason"]

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
        for cid in ("baseline", "index-md", "arch-query", "combined"):
            result = _run(["--condition", cid, "--dry-run"])
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


class TestPendingNoFallback:
    """Pending conditions emit condition_unavailable JSON, never substitute baseline."""

    def test_pending_writes_unavailable_json(self, tmp_path):
        result = _run([
            "--condition", "index-md",
            "--output-dir", str(tmp_path),
        ])
        assert result.returncode == 0, f"stderr: {result.stderr}"
        output_path = tmp_path / "raw-results.json"
        assert output_path.exists()
        output = json.loads(output_path.read_text())
        assert output["condition_unavailable"] is True
        assert output["condition_id"] == "index-md"

    def test_pending_never_returns_baseline_id(self, tmp_path):
        for cid in ("index-md", "arch-query", "combined"):
            out = tmp_path / cid
            result = _run([
                "--condition", cid,
                "--output-dir", str(out),
            ])
            assert result.returncode == 0
            output = json.loads((out / "raw-results.json").read_text())
            assert output["condition_id"] == cid
            assert output["condition_id"] != "baseline"

    def test_pending_condition_available_false(self, tmp_path):
        result = _run([
            "--condition", "arch-query",
            "--output-dir", str(tmp_path),
        ])
        assert result.returncode == 0
        output = json.loads((tmp_path / "raw-results.json").read_text())
        assert output["condition_available"] is False
        assert output["available"] is False

    def test_pending_includes_unavailable_reason(self, tmp_path):
        result = _run([
            "--condition", "index-md",
            "--output-dir", str(tmp_path),
        ])
        assert result.returncode == 0
        output = json.loads((tmp_path / "raw-results.json").read_text())
        assert output["unavailable_reason"]
        assert isinstance(output["unavailable_reason"], str)

    def test_pending_output_is_deterministic(self, tmp_path):
        outputs = []
        for i in range(2):
            out = tmp_path / f"run{i}"
            _run(["--condition", "index-md", "--output-dir", str(out)])
            outputs.append(json.loads((out / "raw-results.json").read_text()))
        assert outputs[0] == outputs[1]

    def test_pending_with_question_subset(self, tmp_path):
        result = _run([
            "--condition", "index-md",
            "--question-id", "INV-001",
            "--question-id", "FACT-001",
            "--output-dir", str(tmp_path),
        ])
        assert result.returncode == 0
        output = json.loads((tmp_path / "raw-results.json").read_text())
        assert output["question_ids"] == ["FACT-001", "INV-001"]

    def test_pending_output_is_sorted_keys(self, tmp_path):
        result = _run([
            "--condition", "index-md",
            "--output-dir", str(tmp_path),
        ])
        assert result.returncode == 0
        raw = (tmp_path / "raw-results.json").read_text()
        output = json.loads(raw)
        assert list(output.keys()) == sorted(output.keys())


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

    def test_baseline_31_questions_default(self):
        result = _run(["--condition", "baseline", "--dry-run"])
        plan = json.loads(result.stdout)
        assert len(plan["question_ids"]) == 31

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

    def test_retired_question_id_fails(self):
        result = _run([
            "--condition", "baseline",
            "--question-id", "INTG-002",
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

    def test_pending_condition_without_sdk(self, tmp_path):
        result = self._run_with_blocked_sdk([
            "--condition", "index-md",
            "--output-dir", str(tmp_path),
        ])
        assert result.returncode == 0, (
            f"pending condition imported claude_agent_sdk:\n{result.stderr}"
        )
        output = json.loads((tmp_path / "raw-results.json").read_text())
        assert output["condition_unavailable"] is True
