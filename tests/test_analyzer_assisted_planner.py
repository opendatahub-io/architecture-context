"""Tests for the condition-aware evaluation planner.

Validates plan_condition() determinism, input validation, and the CLI
without running paid evaluations or launching agents.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent

_planner_path = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "planner.py"
)
_spec = importlib.util.spec_from_file_location("planner", _planner_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

load_manifest = _mod.load_manifest
plan_condition = _mod.plan_condition
main = _mod.main

MANIFEST_PATH = PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "experiment.json"


def _load_real_manifest() -> dict:
    return load_manifest(MANIFEST_PATH)


def _minimal_manifest(
    *,
    active_question_ids: list[str] | None = None,
) -> dict:
    """Build a minimal experiment manifest for unit tests."""
    if active_question_ids is None:
        active_question_ids = ["FACT-001", "FACT-002", "INV-001", "INV-002"]
    return {
        "manifest_version": "1.0.0",
        "experiment_id": "test-experiment",
        "conditions": [
            {
                "condition_id": "baseline",
                "name": "Baseline",
                "description": "Control condition",
                "status": "available",
                "available": True,
                "context_sources": ["architecture/*.md"],
                "tools_permitted": ["Read", "Glob", "Grep"],
                "tools_denied": ["Write", "Bash"],
                "artifact_identity": {
                    "type": "architecture-tree",
                    "revision_source": "git_sha",
                },
                "access_boundary": "Read-only architecture tree.",
            },
            {
                "condition_id": "index-md",
                "name": "INDEX.md",
                "description": "With INDEX.md",
                "status": "pending",
                "available": False,
                "unavailable_reason": "INDEX.md not implemented.",
                "context_sources": ["architecture/*.md", "INDEX.md"],
                "tools_permitted": ["Read", "Glob", "Grep"],
                "tools_denied": ["Write", "Bash"],
                "artifact_identity": {
                    "type": "architecture-tree-with-index",
                    "revision_source": "git_sha",
                    "index_revision_source": "index_generation_sha",
                },
                "access_boundary": "Architecture tree + INDEX.md.",
            },
            {
                "condition_id": "arch-query",
                "name": "arch-query",
                "description": "With query CLI",
                "status": "pending",
                "available": False,
                "unavailable_reason": "Query interface not implemented.",
                "context_sources": ["architecture/*.md"],
                "tools_permitted": ["Read", "Glob", "Grep", "arch-query"],
                "tools_denied": ["Write", "Bash"],
                "artifact_identity": {
                    "type": "architecture-tree-with-query",
                    "revision_source": "git_sha",
                    "query_binary_version": None,
                },
                "access_boundary": "Architecture tree + arch-query.",
            },
            {
                "condition_id": "combined",
                "name": "Combined",
                "description": "INDEX.md + arch-query",
                "status": "pending",
                "available": False,
                "unavailable_reason": "Requires INDEX.md and arch-query.",
                "context_sources": ["architecture/*.md", "INDEX.md"],
                "tools_permitted": ["Read", "Glob", "Grep", "arch-query"],
                "tools_denied": ["Write", "Bash"],
                "artifact_identity": {
                    "type": "architecture-tree-with-index-and-query",
                    "revision_source": "git_sha",
                    "index_revision_source": "index_generation_sha",
                    "query_binary_version": None,
                },
                "access_boundary": "Architecture tree + INDEX.md + arch-query.",
            },
        ],
        "_active_question_ids": sorted(active_question_ids),
    }


SAMPLE_ARTIFACT = {
    "type": "architecture-tree",
    "revision_source": "git_sha",
    "architecture_context_sha": "abc123def456",
}


# --- Loading ---


class TestLoadManifest:
    def test_loads_real_manifest(self):
        manifest = _load_real_manifest()
        assert manifest["experiment_id"] == "analyzer-assisted-retrieval-v1"
        assert len(manifest["conditions"]) == 4

    def test_populates_active_question_ids(self):
        manifest = _load_real_manifest()
        ids = manifest["_active_question_ids"]
        assert isinstance(ids, list)
        assert len(ids) == 37
        assert ids == sorted(ids)

    def test_active_ids_exclude_retired(self):
        manifest = _load_real_manifest()
        ids = set(manifest["_active_question_ids"])
        assert "INTG-006" not in ids
        assert "NAV-003" not in ids

    def test_active_ids_include_nav_010(self):
        manifest = _load_real_manifest()
        ids = set(manifest["_active_question_ids"])
        assert "NAV-010" in ids

    def test_active_ids_include_known(self):
        manifest = _load_real_manifest()
        ids = set(manifest["_active_question_ids"])
        assert "INV-001" in ids
        assert "FACT-001" in ids
        assert "INTG-001" in ids
        assert "INTG-002" in ids
        assert "NAV-001" in ids

    def test_file_not_found(self):
        with pytest.raises(FileNotFoundError):
            load_manifest(Path("/nonexistent/experiment.json"))


# --- Baseline planning (available condition) ---


class TestBaselinePlanning:
    def test_baseline_returns_available(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["condition_id"] == "baseline"
        assert plan["available"] is True
        assert plan["status"] == "available"
        assert plan["unavailable_reason"] is None

    def test_baseline_returns_all_active_questions(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["question_ids"] == ["FACT-001", "FACT-002", "INV-001", "INV-002"]

    def test_baseline_returns_sorted_questions(self):
        manifest = _minimal_manifest(
            active_question_ids=["INV-003", "FACT-001", "INV-001", "FACT-002"]
        )
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["question_ids"] == sorted(plan["question_ids"])

    def test_baseline_includes_tools(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["tools_permitted"] == ["Read", "Glob", "Grep"]
        assert plan["tools_denied"] == ["Write", "Bash"]

    def test_baseline_includes_access_boundary(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["access_boundary"] == "Read-only architecture tree."

    def test_baseline_includes_provenance_requirements(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        reqs = plan["provenance_requirements"]
        assert reqs["type"] == "architecture-tree"
        assert reqs["revision_source"] == "git_sha"

    def test_baseline_includes_artifact_identity(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["artifact_identity"] == SAMPLE_ARTIFACT

    def test_baseline_condition_name(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["condition_name"] == "Baseline"


# --- Pending condition planning ---


class TestPendingConditionPlanning:
    def test_pending_index_md(self):
        manifest = _minimal_manifest()
        plan = plan_condition(manifest, "index-md")
        assert plan["available"] is False
        assert plan["status"] == "pending"
        assert plan["unavailable_reason"] == "INDEX.md not implemented."

    def test_pending_arch_query_in_minimal_manifest(self):
        manifest = _minimal_manifest()
        plan = plan_condition(manifest, "arch-query")
        assert plan["available"] is False
        assert plan["unavailable_reason"] == "Query interface not implemented."

    def test_pending_combined(self):
        manifest = _minimal_manifest()
        plan = plan_condition(manifest, "combined")
        assert plan["available"] is False
        assert plan["unavailable_reason"] == "Requires INDEX.md and arch-query."

    def test_pending_still_returns_question_ids(self):
        manifest = _minimal_manifest()
        plan = plan_condition(manifest, "index-md")
        assert plan["question_ids"] == ["FACT-001", "FACT-002", "INV-001", "INV-002"]

    def test_pending_still_returns_tools(self):
        manifest = _minimal_manifest()
        plan = plan_condition(manifest, "arch-query")
        assert "arch-query" in plan["tools_permitted"]

    def test_pending_does_not_require_artifact_identity(self):
        manifest = _minimal_manifest()
        plan = plan_condition(manifest, "index-md", artifact_identity=None)
        assert plan["artifact_identity"] is None

    def test_pending_accepts_artifact_identity(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "index-md", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["artifact_identity"] == SAMPLE_ARTIFACT


# --- No fallback: pending must never silently become baseline ---


class TestNoFallback:
    def test_pending_never_returns_baseline_id(self):
        manifest = _minimal_manifest()
        for cid in ("index-md", "arch-query", "combined"):
            plan = plan_condition(manifest, cid)
            assert plan["condition_id"] == cid
            assert plan["condition_id"] != "baseline"

    def test_pending_never_returns_available_true(self):
        manifest = _minimal_manifest()
        for cid in ("index-md", "arch-query", "combined"):
            plan = plan_condition(manifest, cid)
            assert plan["available"] is False

    def test_pending_always_has_unavailable_reason(self):
        manifest = _minimal_manifest()
        for cid in ("index-md", "arch-query", "combined"):
            plan = plan_condition(manifest, cid)
            assert plan["unavailable_reason"] is not None
            assert len(plan["unavailable_reason"]) > 0

    def test_minimal_manifest_pending_never_returns_available(self):
        manifest = _minimal_manifest()
        for cid in ("index-md", "arch-query", "combined"):
            plan = plan_condition(manifest, cid)
            assert plan["available"] is False
            assert plan["unavailable_reason"] is not None


# --- Unknown condition rejection ---


class TestUnknownCondition:
    def test_reject_unknown_condition(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="Unknown condition_id"):
            plan_condition(manifest, "nonexistent")

    def test_reject_empty_condition(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="Unknown condition_id"):
            plan_condition(manifest, "")

    def test_reject_close_misspelling(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="Unknown condition_id"):
            plan_condition(manifest, "base-line")

    def test_error_lists_known_conditions(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="baseline") as exc_info:
            plan_condition(manifest, "bogus")
        assert "arch-query" in str(exc_info.value)
        assert "index-md" in str(exc_info.value)
        assert "combined" in str(exc_info.value)


# --- Question ID validation ---


class TestQuestionIDValidation:
    def test_valid_subset(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest,
            "baseline",
            question_ids=["INV-001", "FACT-001"],
            artifact_identity=SAMPLE_ARTIFACT,
        )
        assert plan["question_ids"] == ["FACT-001", "INV-001"]

    def test_subset_is_sorted(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest,
            "baseline",
            question_ids=["INV-002", "FACT-001", "INV-001"],
            artifact_identity=SAMPLE_ARTIFACT,
        )
        assert plan["question_ids"] == ["FACT-001", "INV-001", "INV-002"]

    def test_single_question(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest,
            "baseline",
            question_ids=["INV-001"],
            artifact_identity=SAMPLE_ARTIFACT,
        )
        assert plan["question_ids"] == ["INV-001"]

    def test_reject_duplicate_question_ids(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="Duplicate question_id"):
            plan_condition(
                manifest,
                "baseline",
                question_ids=["INV-001", "INV-001"],
                artifact_identity=SAMPLE_ARTIFACT,
            )

    def test_reject_invalid_format(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="Invalid question_id format"):
            plan_condition(
                manifest,
                "baseline",
                question_ids=["bad-format"],
                artifact_identity=SAMPLE_ARTIFACT,
            )

    def test_reject_lowercase_id(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="Invalid question_id format"):
            plan_condition(
                manifest,
                "baseline",
                question_ids=["inv-001"],
                artifact_identity=SAMPLE_ARTIFACT,
            )

    def test_reject_unknown_question_id(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="Unknown question_id"):
            plan_condition(
                manifest,
                "baseline",
                question_ids=["INV-999"],
                artifact_identity=SAMPLE_ARTIFACT,
            )

    def test_reject_retired_question_id(self):
        manifest = _load_real_manifest()
        with pytest.raises(ValueError, match="Unknown question_id 'INTG-006'"):
            plan_condition(
                manifest,
                "baseline",
                question_ids=["INTG-006"],
                artifact_identity=SAMPLE_ARTIFACT,
            )


# --- Artifact identity validation ---


class TestArtifactIdentity:
    def test_available_requires_artifact_identity(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="artifact_identity"):
            plan_condition(manifest, "baseline", artifact_identity=None)

    def test_available_accepts_artifact_identity(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["artifact_identity"] == SAMPLE_ARTIFACT

    def test_pending_does_not_require_artifact_identity(self):
        manifest = _minimal_manifest()
        plan = plan_condition(manifest, "index-md")
        assert plan["artifact_identity"] is None


# --- Artifact identity key validation ---


class TestArtifactIdentityKeyValidation:
    """Validate that available conditions reject incomplete artifact_identity."""

    def test_reject_missing_type(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="missing required key 'type'"):
            plan_condition(
                manifest,
                "baseline",
                artifact_identity={"revision_source": "git_sha", "sha": "abc"},
            )

    def test_reject_empty_type(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="missing required key 'type'"):
            plan_condition(
                manifest,
                "baseline",
                artifact_identity={"type": "", "revision_source": "git_sha"},
            )

    def test_reject_missing_revision_source(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="missing required key 'revision_source'"):
            plan_condition(
                manifest,
                "baseline",
                artifact_identity={"type": "architecture-tree", "sha": "abc"},
            )

    def test_reject_empty_revision_source(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="missing required key 'revision_source'"):
            plan_condition(
                manifest,
                "baseline",
                artifact_identity={
                    "type": "architecture-tree",
                    "revision_source": "",
                },
            )

    def test_reject_none_type(self):
        manifest = _minimal_manifest()
        with pytest.raises(ValueError, match="missing required key 'type'"):
            plan_condition(
                manifest,
                "baseline",
                artifact_identity={
                    "type": None,
                    "revision_source": "git_sha",
                },
            )

    def test_accept_complete_baseline_identity(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest,
            "baseline",
            artifact_identity={
                "type": "architecture-tree",
                "revision_source": "git_sha",
            },
        )
        assert plan["artifact_identity"]["type"] == "architecture-tree"
        assert plan["artifact_identity"]["revision_source"] == "git_sha"

    def test_reject_missing_index_revision_source(self):
        manifest = _minimal_manifest()
        for c in manifest["conditions"]:
            if c["condition_id"] == "index-md":
                c["available"] = True
                c["status"] = "available"
                break
        with pytest.raises(
            ValueError, match="missing required key 'index_revision_source'"
        ):
            plan_condition(
                manifest,
                "index-md",
                artifact_identity={
                    "type": "architecture-tree-with-index",
                    "revision_source": "git_sha",
                },
            )

    def test_accept_complete_index_md_identity(self, tmp_path):
        manifest = _minimal_manifest()
        for c in manifest["conditions"]:
            if c["condition_id"] == "index-md":
                c["available"] = True
                c["status"] = "available"
                break
        index_path = tmp_path / "INDEX.md"
        index_path.write_text(
            "<!-- INDEX.md format_version=1 arch_query_format_version=2"
            " version=test source_revision=abc123 component_count=0 -->\n"
            "\n# Architecture Context Index — test\n"
            "\n**Format version**: 1  \n"
            "\n## Components\n\n"
            "| Component | Purpose | Deploy Type | Sections | Source |\n"
            "|-----------|---------|-------------|----------|--------|\n"
        )
        plan = plan_condition(
            manifest,
            "index-md",
            artifact_identity={
                "type": "architecture-tree-with-index",
                "revision_source": "git_sha",
                "index_revision_source": "abc123",
            },
            index_artifact_path=str(index_path),
        )
        assert plan["artifact_identity"]["index_revision_source"] == "abc123"

    def test_null_manifest_requirement_not_enforced(self):
        manifest = _minimal_manifest()
        for c in manifest["conditions"]:
            if c["condition_id"] == "arch-query":
                c["available"] = True
                c["status"] = "available"
                break
        plan = plan_condition(
            manifest,
            "arch-query",
            artifact_identity={
                "type": "architecture-tree-with-query",
                "revision_source": "git_sha",
            },
        )
        assert plan["available"] is True

    def test_pending_condition_skips_key_validation(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest,
            "index-md",
            artifact_identity={"incomplete": True},
        )
        assert plan["artifact_identity"] == {"incomplete": True}

    def test_error_message_includes_manifest_declaration(self):
        manifest = _minimal_manifest()
        for c in manifest["conditions"]:
            if c["condition_id"] == "index-md":
                c["available"] = True
                c["status"] = "available"
                break
        with pytest.raises(ValueError, match="index_generation_sha") as exc_info:
            plan_condition(
                manifest,
                "index-md",
                artifact_identity={
                    "type": "architecture-tree-with-index",
                    "revision_source": "git_sha",
                },
            )
        assert "index-md" in str(exc_info.value)


# --- Determinism ---


class TestDeterminism:
    def test_repeated_calls_identical(self):
        manifest = _minimal_manifest()
        plan1 = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        plan2 = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan1 == plan2

    def test_question_order_stable_regardless_of_input_order(self):
        manifest = _minimal_manifest()
        plan_a = plan_condition(
            manifest,
            "baseline",
            question_ids=["INV-002", "FACT-001"],
            artifact_identity=SAMPLE_ARTIFACT,
        )
        plan_b = plan_condition(
            manifest,
            "baseline",
            question_ids=["FACT-001", "INV-002"],
            artifact_identity=SAMPLE_ARTIFACT,
        )
        assert plan_a["question_ids"] == plan_b["question_ids"]

    def test_json_serializable(self):
        manifest = _minimal_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        roundtripped = json.loads(json.dumps(plan, sort_keys=True))
        assert roundtripped == plan


# --- Real manifest integration ---


class TestRealManifest:
    def test_plan_baseline_from_real_manifest(self):
        manifest = _load_real_manifest()
        plan = plan_condition(
            manifest, "baseline", artifact_identity=SAMPLE_ARTIFACT
        )
        assert plan["available"] is True
        assert len(plan["question_ids"]) == 37
        assert "Read" in plan["tools_permitted"]
        assert "arch-query" in plan["tools_denied"]

    def test_plan_combined_available_from_real_manifest(self):
        manifest = _load_real_manifest()
        artifact = {
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "56eb7ab043e99c8e00f91f2903d2ed625e694049",
            "query_binary_version": "abc123def456",
        }
        index_path = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        plan = plan_condition(
            manifest, "combined",
            artifact_identity=artifact,
            index_artifact_path=index_path,
        )
        assert plan["available"] is True
        assert plan["unavailable_reason"] is None
        assert len(plan["question_ids"]) == 37
        assert plan["index_artifact_path"] == index_path
        assert "Bash" in plan["tools_permitted"]
        assert "Write" in plan["tools_denied"]

    def test_plan_index_md_available_from_real_manifest(self):
        manifest = _load_real_manifest()
        artifact = {
            "type": "architecture-tree-with-index",
            "revision_source": "git_sha",
            "index_revision_source": "56eb7ab043e99c8e00f91f2903d2ed625e694049",
        }
        index_path = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        plan = plan_condition(
            manifest, "index-md",
            artifact_identity=artifact,
            index_artifact_path=index_path,
        )
        assert plan["available"] is True
        assert plan["unavailable_reason"] is None
        assert len(plan["question_ids"]) == 37
        assert plan["index_artifact_path"] == index_path

    def test_plan_arch_query_available_from_real_manifest(self):
        manifest = _load_real_manifest()
        artifact = {
            "type": "architecture-tree-with-query",
            "revision_source": "git_sha",
            "query_binary_version": "abc123def456",
        }
        plan = plan_condition(
            manifest, "arch-query", artifact_identity=artifact,
        )
        assert plan["available"] is True
        assert plan["unavailable_reason"] is None
        assert len(plan["question_ids"]) == 37
        assert "Bash" in plan["tools_permitted"]
        assert "Write" in plan["tools_denied"]

    def test_plan_baseline_question_subset(self):
        manifest = _load_real_manifest()
        plan = plan_condition(
            manifest,
            "baseline",
            question_ids=["INV-001", "FACT-001", "NAV-001"],
            artifact_identity=SAMPLE_ARTIFACT,
        )
        assert plan["question_ids"] == ["FACT-001", "INV-001", "NAV-001"]


# --- CLI ---


class TestCLI:
    def test_cli_baseline_plan(self):
        result = subprocess.run(
            [
                sys.executable,
                str(_planner_path),
                "--manifest", str(MANIFEST_PATH),
                "--condition", "baseline",
                "--artifact-json", json.dumps(SAMPLE_ARTIFACT),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"stderr: {result.stderr}"
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "baseline"
        assert plan["available"] is True
        assert len(plan["question_ids"]) == 37

    def test_cli_combined_available(self):
        index_path = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        result = subprocess.run(
            [
                sys.executable,
                str(_planner_path),
                "--manifest", str(MANIFEST_PATH),
                "--condition", "combined",
                "--artifact-json", artifact,
                "--index-artifact-path", index_path,
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"stderr: {result.stderr}"
        plan = json.loads(result.stdout)
        assert plan["available"] is True
        assert plan["unavailable_reason"] is None
        assert plan["index_artifact_path"] == index_path

    def test_cli_combined_fails_without_index_path(self):
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        result = subprocess.run(
            [
                sys.executable,
                str(_planner_path),
                "--manifest", str(MANIFEST_PATH),
                "--condition", "combined",
                "--artifact-json", artifact,
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 1
        assert "index_artifact_path" in result.stderr

    def test_cli_combined_fails_without_query_provenance(self):
        index_path = str(
            Path(__file__).resolve().parent.parent
            / "benchmark" / "analyzer-assisted-v1" / "INDEX.md"
        )
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
        })
        result = subprocess.run(
            [
                sys.executable,
                str(_planner_path),
                "--manifest", str(MANIFEST_PATH),
                "--condition", "combined",
                "--artifact-json", artifact,
                "--index-artifact-path", index_path,
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 1
        assert "query_binary_version" in result.stderr

    def test_cli_unknown_condition_fails(self):
        result = subprocess.run(
            [
                sys.executable,
                str(_planner_path),
                "--manifest", str(MANIFEST_PATH),
                "--condition", "nonexistent",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 1
        assert "Unknown condition_id" in result.stderr

    def test_cli_question_subset(self):
        result = subprocess.run(
            [
                sys.executable,
                str(_planner_path),
                "--manifest", str(MANIFEST_PATH),
                "--condition", "baseline",
                "--question-id", "INV-001",
                "--question-id", "FACT-001",
                "--artifact-json", json.dumps(SAMPLE_ARTIFACT),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"stderr: {result.stderr}"
        plan = json.loads(result.stdout)
        assert plan["question_ids"] == ["FACT-001", "INV-001"]

    def test_cli_duplicate_question_fails(self):
        result = subprocess.run(
            [
                sys.executable,
                str(_planner_path),
                "--manifest", str(MANIFEST_PATH),
                "--condition", "baseline",
                "--question-id", "INV-001",
                "--question-id", "INV-001",
                "--artifact-json", json.dumps(SAMPLE_ARTIFACT),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 1
        assert "Duplicate" in result.stderr

    def test_cli_output_is_sorted_json(self):
        result = subprocess.run(
            [
                sys.executable,
                str(_planner_path),
                "--manifest", str(MANIFEST_PATH),
                "--condition", "baseline",
                "--artifact-json", json.dumps(SAMPLE_ARTIFACT),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        keys = list(plan.keys())
        assert keys == sorted(keys)

    def test_cli_missing_artifact_for_available_fails(self):
        result = subprocess.run(
            [
                sys.executable,
                str(_planner_path),
                "--manifest", str(MANIFEST_PATH),
                "--condition", "baseline",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 1
        assert "artifact_identity" in result.stderr

    def test_cli_main_function(self):
        rc = main([
            "--manifest", str(MANIFEST_PATH),
            "--condition", "baseline",
            "--artifact-json", json.dumps(SAMPLE_ARTIFACT),
        ])
        assert rc == 0

    def test_cli_main_bad_manifest_path(self):
        rc = main([
            "--manifest", "/nonexistent/experiment.json",
            "--condition", "baseline",
        ])
        assert rc == 1
