"""Tests for INDEX.md materialization and the index-md evaluation condition.

Validates:
  - Deterministic rendering from arch-query index JSON
  - Stable ordering, format/version fields, source revision presence
  - Missing and incompatible input error handling
  - Provenance header parsing and validation
  - Planner integration: index-md requires artifact path, validates artifact
  - Evaluator integration: guard allows INDEX.md read when configured
  - Baseline and arch-query conditions unchanged
  - Combined remains pending
"""

from __future__ import annotations

import copy
import importlib.util
import json
import random
import subprocess
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent

_mat_path = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "materialize_index.py"
)
_mat_spec = importlib.util.spec_from_file_location("materialize_index", _mat_path)
_mat = importlib.util.module_from_spec(_mat_spec)
_mat_spec.loader.exec_module(_mat)

materialize = _mat.materialize
validate_index_artifact = _mat.validate_index_artifact
parse_header = _mat.parse_header
MaterializeError = _mat.MaterializeError
INDEX_FORMAT_VERSION = _mat.INDEX_FORMAT_VERSION
main_mat = _mat.main

_planner_path = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "planner.py"
)
_planner_spec = importlib.util.spec_from_file_location("planner", _planner_path)
_planner = importlib.util.module_from_spec(_planner_spec)
_planner_spec.loader.exec_module(_planner)

load_manifest = _planner.load_manifest
plan_condition = _planner.plan_condition

MANIFEST_PATH = PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "experiment.json"
RUNNER_PATH = PROJECT_ROOT / "benchmark" / "consumer-v1" / "run_evaluation.py"

_runner_spec = importlib.util.spec_from_file_location("run_evaluation", RUNNER_PATH)
sys.path.insert(0, str(PROJECT_ROOT))
_runner = importlib.util.module_from_spec(_runner_spec)
_runner_spec.loader.exec_module(_runner)
_EvalGuard = _runner._EvalGuard
SYSTEM_PROMPT_TEMPLATE = _runner.SYSTEM_PROMPT_TEMPLATE
QUERY_PROMPT_GUIDANCE = _runner.QUERY_PROMPT_GUIDANCE
INDEX_PROMPT_GUIDANCE = _runner.INDEX_PROMPT_GUIDANCE
_parse_index_header = _runner._parse_index_header


def _sample_index_json(
    *,
    n_components: int = 3,
    version: str = "rhoai-3.5",
    format_version: str = "2",
) -> dict:
    """Build a sample arch-query index JSON dict."""
    components = []
    for i in range(n_components):
        name = f"comp-{i:03d}"
        components.append({
            "name": name,
            "source_path": f"{version}/{name}.md",
            "purpose": f"Component {i}",
            "deploy_type": "operator" if i % 2 == 0 else "deployment",
            "sections": {"crds": i + 1, "services": 1} if i > 0 else {},
            "metadata": {"commit_sha": f"sha{i:03d}"},
        })
    return {
        "format_version": format_version,
        "version": version,
        "category_mappings": {
            "api-surface": ["crds", "endpoints"],
            "deployment-model": ["services"],
            "purpose": [],
        },
        "components": components,
    }


def _write_valid_index(tmp_path: Path, **kwargs) -> Path:
    """Materialize a valid INDEX.md to tmp_path and return the path."""
    index_json = _sample_index_json(**kwargs)
    content = materialize(index_json, source_revision="abc123")
    path = tmp_path / "INDEX.md"
    path.write_text(content)
    return path


# ---------------------------------------------------------------------------
# Materialization: deterministic rendering
# ---------------------------------------------------------------------------


class TestMaterialize:
    def test_basic_rendering(self):
        idx = _sample_index_json()
        md = materialize(idx, source_revision="abc123")
        assert "# Architecture Context Index" in md
        assert "rhoai-3.5" in md
        assert "abc123" in md

    def test_format_version_in_header(self):
        idx = _sample_index_json()
        md = materialize(idx, source_revision="abc123")
        header = parse_header(md)
        assert header is not None
        assert header["format_version"] == INDEX_FORMAT_VERSION

    def test_arch_query_format_version_in_header(self):
        idx = _sample_index_json(format_version="2")
        md = materialize(idx, source_revision="abc123")
        header = parse_header(md)
        assert header["arch_query_format_version"] == "2"

    def test_source_revision_in_header(self):
        idx = _sample_index_json()
        md = materialize(idx, source_revision="deadbeef")
        header = parse_header(md)
        assert header["source_revision"] == "deadbeef"

    def test_component_count_in_header(self):
        idx = _sample_index_json(n_components=5)
        md = materialize(idx, source_revision="abc123")
        header = parse_header(md)
        assert header["component_count"] == 5

    def test_components_in_table(self):
        idx = _sample_index_json(n_components=3)
        md = materialize(idx, source_revision="abc123")
        assert "comp-000" in md
        assert "comp-001" in md
        assert "comp-002" in md

    def test_category_mappings_table(self):
        idx = _sample_index_json()
        md = materialize(idx, source_revision="abc123")
        assert "## Category Mappings" in md
        assert "api-surface" in md
        assert "deployment-model" in md

    def test_empty_components(self):
        idx = _sample_index_json(n_components=0)
        md = materialize(idx, source_revision="abc123")
        header = parse_header(md)
        assert header["component_count"] == 0

    def test_sections_sorted_in_output(self):
        idx = _sample_index_json(n_components=2)
        md = materialize(idx, source_revision="abc123")
        for line in md.split("\n"):
            if line.startswith("| comp-001"):
                assert "crds(2)" in line
                assert "services(1)" in line
                crds_pos = line.index("crds")
                services_pos = line.index("services")
                assert crds_pos < services_pos


class TestMaterializeDeterminism:
    def test_repeated_calls_identical(self):
        idx = _sample_index_json()
        md1 = materialize(idx, source_revision="abc123")
        md2 = materialize(idx, source_revision="abc123")
        assert md1 == md2

    def test_component_order_sorted_by_name(self):
        idx = _sample_index_json(n_components=5)
        md = materialize(idx, source_revision="abc123")
        lines = md.split("\n")
        comp_lines = [ln for ln in lines if ln.startswith("| comp-")]
        names = [ln.split("|")[1].strip() for ln in comp_lines]
        assert names == sorted(names)

    def test_shuffled_input_produces_identical_output(self):
        idx = _sample_index_json(n_components=8)
        canonical = materialize(idx, source_revision="abc123")
        rng = random.Random(99)
        for _ in range(5):
            shuffled = copy.deepcopy(idx)
            rng.shuffle(shuffled["components"])
            comps_changed = shuffled["components"] != idx["components"]
            assert comps_changed or len(idx["components"]) <= 1
            result = materialize(shuffled, source_revision="abc123")
            assert result == canonical


# ---------------------------------------------------------------------------
# Materialization: error handling
# ---------------------------------------------------------------------------


class TestMaterializeErrors:
    def test_non_dict_input(self):
        with pytest.raises(MaterializeError, match="Expected dict"):
            materialize("not a dict", source_revision="abc")

    def test_missing_format_version(self):
        idx = _sample_index_json()
        del idx["format_version"]
        with pytest.raises(MaterializeError, match="format_version"):
            materialize(idx, source_revision="abc")

    def test_missing_version(self):
        idx = _sample_index_json()
        del idx["version"]
        with pytest.raises(MaterializeError, match="version"):
            materialize(idx, source_revision="abc")

    def test_missing_components(self):
        idx = _sample_index_json()
        del idx["components"]
        with pytest.raises(MaterializeError, match="components"):
            materialize(idx, source_revision="abc")

    def test_components_not_list(self):
        idx = _sample_index_json()
        idx["components"] = "not a list"
        with pytest.raises(MaterializeError, match="must be a list"):
            materialize(idx, source_revision="abc")

    def test_empty_source_revision(self):
        idx = _sample_index_json()
        with pytest.raises(MaterializeError, match="source_revision"):
            materialize(idx, source_revision="")

    def test_whitespace_source_revision(self):
        idx = _sample_index_json()
        with pytest.raises(MaterializeError, match="source_revision"):
            materialize(idx, source_revision="   ")


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------


class TestValidateIndexArtifact:
    def test_valid_artifact(self):
        idx = _sample_index_json()
        md = materialize(idx, source_revision="abc123")
        errors = validate_index_artifact(md)
        assert errors == []

    def test_empty_content(self):
        errors = validate_index_artifact("")
        assert len(errors) == 1
        assert "empty" in errors[0]

    def test_missing_header(self):
        errors = validate_index_artifact("# Some document\n\nNo header here.")
        assert len(errors) == 1
        assert "provenance header" in errors[0]

    def test_wrong_format_version(self):
        idx = _sample_index_json()
        md = materialize(idx, source_revision="abc123")
        md = md.replace(
            f"format_version={INDEX_FORMAT_VERSION}",
            "format_version=99",
            1,
        )
        errors = validate_index_artifact(md)
        assert any("format_version" in e for e in errors)

    def test_component_count_mismatch(self):
        idx = _sample_index_json(n_components=3)
        md = materialize(idx, source_revision="abc123")
        md = md.replace("component_count=3", "component_count=5", 1)
        errors = validate_index_artifact(md)
        assert any("component_count" in e or "components" in e for e in errors)


class TestParseHeader:
    def test_valid_header(self):
        idx = _sample_index_json()
        md = materialize(idx, source_revision="rev123")
        header = parse_header(md)
        assert header is not None
        assert header["format_version"] == INDEX_FORMAT_VERSION
        assert header["version"] == "rhoai-3.5"
        assert header["source_revision"] == "rev123"
        assert header["component_count"] == 3

    def test_missing_header(self):
        assert parse_header("no header here") is None

    def test_empty_content(self):
        assert parse_header("") is None


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


class TestMaterializeCLI:
    def test_materialize_from_file(self, tmp_path):
        idx = _sample_index_json()
        input_file = tmp_path / "index.json"
        input_file.write_text(json.dumps(idx))
        output_file = tmp_path / "INDEX.md"

        result = subprocess.run(
            [
                sys.executable, str(_mat_path),
                "--input", str(input_file),
                "--source-revision", "abc123",
                "--output", str(output_file),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"stderr: {result.stderr}"
        assert output_file.exists()
        errors = validate_index_artifact(output_file.read_text())
        assert errors == []

    def test_validate_mode(self, tmp_path):
        path = _write_valid_index(tmp_path)
        result = subprocess.run(
            [
                sys.executable, str(_mat_path),
                "--validate", str(path),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert "PASS" in result.stdout

    def test_validate_bad_file(self, tmp_path):
        path = tmp_path / "bad.md"
        path.write_text("no header")
        result = subprocess.run(
            [
                sys.executable, str(_mat_path),
                "--validate", str(path),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 1
        assert "FAIL" in result.stderr

    def test_missing_source_revision(self, tmp_path):
        idx = _sample_index_json()
        input_file = tmp_path / "index.json"
        input_file.write_text(json.dumps(idx))
        result = subprocess.run(
            [
                sys.executable, str(_mat_path),
                "--input", str(input_file),
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 1
        assert "source-revision" in result.stderr

    def test_stdout_output(self, tmp_path):
        idx = _sample_index_json()
        input_file = tmp_path / "index.json"
        input_file.write_text(json.dumps(idx))
        result = subprocess.run(
            [
                sys.executable, str(_mat_path),
                "--input", str(input_file),
                "--source-revision", "abc123",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert "# Architecture Context Index" in result.stdout


# ---------------------------------------------------------------------------
# Planner: index-md requires index artifact path
# ---------------------------------------------------------------------------


def _minimal_manifest_with_index_available(
    *,
    active_question_ids: list[str] | None = None,
) -> dict:
    if active_question_ids is None:
        active_question_ids = ["FACT-001", "INV-001"]
    return {
        "manifest_version": "1.0.0",
        "experiment_id": "test",
        "conditions": [
            {
                "condition_id": "baseline",
                "name": "Baseline",
                "description": "Control",
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
                "status": "available",
                "available": True,
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
                "status": "available",
                "available": True,
                "context_sources": ["architecture/*.md"],
                "tools_permitted": ["Read", "Glob", "Grep", "Bash"],
                "tools_denied": ["Write", "Edit"],
                "artifact_identity": {
                    "type": "architecture-tree-with-query",
                    "revision_source": "git_sha",
                    "query_binary_version": "git_sha",
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
                "tools_permitted": ["Read", "Glob", "Grep", "Bash"],
                "tools_denied": ["Write", "Edit"],
                "artifact_identity": {
                    "type": "architecture-tree-with-index-and-query",
                    "revision_source": "git_sha",
                    "index_revision_source": "index_generation_sha",
                    "query_binary_version": "git_sha",
                },
                "access_boundary": "Architecture tree + INDEX.md + arch-query.",
            },
        ],
        "_active_question_ids": sorted(active_question_ids),
    }


INDEX_MD_ARTIFACT = {
    "type": "architecture-tree-with-index",
    "revision_source": "git_sha",
    "index_revision_source": "test-gen-sha",
}

BASELINE_ARTIFACT = {
    "type": "architecture-tree",
    "revision_source": "git_sha",
}


class TestPlannerIndexMdRequiresArtifactPath:
    def test_available_index_md_requires_path(self, tmp_path):
        manifest = _minimal_manifest_with_index_available()
        with pytest.raises(ValueError, match="index_artifact_path"):
            plan_condition(
                manifest,
                "index-md",
                artifact_identity=INDEX_MD_ARTIFACT,
            )

    def test_available_index_md_rejects_missing_file(self, tmp_path):
        manifest = _minimal_manifest_with_index_available()
        with pytest.raises(ValueError, match="not found"):
            plan_condition(
                manifest,
                "index-md",
                artifact_identity=INDEX_MD_ARTIFACT,
                index_artifact_path=str(tmp_path / "nonexistent.md"),
            )

    def test_available_index_md_rejects_invalid_artifact(self, tmp_path):
        manifest = _minimal_manifest_with_index_available()
        bad = tmp_path / "INDEX.md"
        bad.write_text("no provenance header")
        with pytest.raises(ValueError, match="failed validation"):
            plan_condition(
                manifest,
                "index-md",
                artifact_identity=INDEX_MD_ARTIFACT,
                index_artifact_path=str(bad),
            )

    def test_available_index_md_accepts_valid_artifact(self, tmp_path):
        manifest = _minimal_manifest_with_index_available()
        path = _write_valid_index(tmp_path)
        plan = plan_condition(
            manifest,
            "index-md",
            artifact_identity=INDEX_MD_ARTIFACT,
            index_artifact_path=str(path),
        )
        assert plan["available"] is True
        assert plan["index_artifact_path"] == str(path)

    def test_baseline_does_not_require_index_path(self):
        manifest = _minimal_manifest_with_index_available()
        plan = plan_condition(
            manifest, "baseline",
            artifact_identity=BASELINE_ARTIFACT,
        )
        assert plan["index_artifact_path"] is None

    def test_arch_query_does_not_require_index_path(self):
        manifest = _minimal_manifest_with_index_available()
        plan = plan_condition(
            manifest, "arch-query",
            artifact_identity={
                "type": "architecture-tree-with-query",
                "revision_source": "git_sha",
                "query_binary_version": "sha123",
            },
        )
        assert plan["index_artifact_path"] is None


class TestPlannerIndexMdAvailable:
    """index-md is available with pinned artifact; combined stays pending."""

    def test_index_md_available_with_artifact(self):
        manifest = load_manifest(MANIFEST_PATH)
        index_path = str(MANIFEST_PATH.parent / "INDEX.md")
        plan = plan_condition(
            manifest,
            "index-md",
            artifact_identity=INDEX_MD_ARTIFACT,
            index_artifact_path=index_path,
        )
        assert plan["available"] is True
        assert plan["index_artifact_path"] == index_path

    def test_index_md_requires_artifact_path_when_available(self):
        manifest = load_manifest(MANIFEST_PATH)
        with pytest.raises(ValueError, match="index_artifact_path"):
            plan_condition(
                manifest,
                "index-md",
                artifact_identity=INDEX_MD_ARTIFACT,
            )

    def test_combined_requires_artifact_path_when_available(self):
        manifest = load_manifest(MANIFEST_PATH)
        with pytest.raises(ValueError, match="index_artifact_path"):
            plan_condition(
                manifest,
                "combined",
                artifact_identity={
                    "type": "architecture-tree-with-index-and-query",
                    "revision_source": "git_sha",
                    "index_revision_source": "test-sha",
                    "query_binary_version": "test-sha",
                },
            )


class TestPlannerNoFallbackPreserved:
    """No-fallback: combined with missing artifacts produces explicit errors."""

    def test_combined_without_artifacts_never_returns_baseline(self):
        manifest = load_manifest(MANIFEST_PATH)
        with pytest.raises(ValueError, match="artifact_identity"):
            plan_condition(manifest, "combined")

    def test_combined_available_in_real_manifest(self):
        manifest = load_manifest(MANIFEST_PATH)
        index_path = str(MANIFEST_PATH.parent / "INDEX.md")
        plan = plan_condition(
            manifest, "combined",
            artifact_identity={
                "type": "architecture-tree-with-index-and-query",
                "revision_source": "git_sha",
                "index_revision_source": "test-sha",
                "query_binary_version": "test-sha",
            },
            index_artifact_path=index_path,
        )
        assert plan["status"] == "available"
        assert plan["available"] is True
        assert plan["condition_id"] == "combined"


# ---------------------------------------------------------------------------
# Evaluator guard: index path read boundary
# ---------------------------------------------------------------------------


async def _call_guard(guard, tool_name, tool_input):
    return await guard.pre_tool_use(
        {"tool_name": tool_name, "tool_input": tool_input},
        "test-id",
        None,
    )


class TestEvalGuardIndexPath:
    @pytest.mark.asyncio
    async def test_index_path_read_allowed(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("content")
        guard = _EvalGuard(tree, index_path=index)
        result = await _call_guard(
            guard, "Read", {"file_path": str(index)}
        )
        decision = result.get("hookSpecificOutput", {}).get("permissionDecision")
        assert decision != "deny"

    @pytest.mark.asyncio
    async def test_read_outside_tree_and_index_denied(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("content")
        other = tmp_path / "other.txt"
        other.write_text("secret")
        guard = _EvalGuard(tree, index_path=index)
        result = await _call_guard(
            guard, "Read", {"file_path": str(other)}
        )
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_no_index_path_default_behavior(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        outside = tmp_path / "INDEX.md"
        outside.write_text("content")
        guard = _EvalGuard(tree)
        result = await _call_guard(
            guard, "Read", {"file_path": str(outside)}
        )
        decision = result["hookSpecificOutput"]["permissionDecision"]
        assert decision == "deny"

    @pytest.mark.asyncio
    async def test_index_path_in_telemetry(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        index = tmp_path / "INDEX.md"
        index.write_text("content")
        guard = _EvalGuard(tree, index_path=index)
        telem = guard.telemetry()
        assert telem["index_artifact_path"] == str(index.resolve())

    @pytest.mark.asyncio
    async def test_no_index_path_no_telemetry_key(self, tmp_path):
        tree = tmp_path / "arch-tree"
        tree.mkdir()
        guard = _EvalGuard(tree)
        telem = guard.telemetry()
        assert "index_artifact_path" not in telem


# ---------------------------------------------------------------------------
# Prompt guidance: INDEX.md system-prompt injection
# ---------------------------------------------------------------------------


class TestIndexPromptGuidance:
    def test_index_guidance_includes_path(self, tmp_path):
        path = _write_valid_index(tmp_path)
        header = _parse_index_header(path)
        guidance = INDEX_PROMPT_GUIDANCE.format(
            index_path=path.resolve(),
            source_revision=header["source_revision"],
            format_version=header["format_version"],
            component_count=header["component_count"],
        )
        assert str(path.resolve()) in guidance

    def test_index_guidance_includes_provenance(self, tmp_path):
        path = _write_valid_index(tmp_path)
        header = _parse_index_header(path)
        guidance = INDEX_PROMPT_GUIDANCE.format(
            index_path=path.resolve(),
            source_revision=header["source_revision"],
            format_version=header["format_version"],
            component_count=header["component_count"],
        )
        assert "abc123" in guidance
        assert "read-only evidence" in guidance
        assert "provenance validation" in guidance

    def test_index_guidance_includes_component_count(self, tmp_path):
        path = _write_valid_index(tmp_path, n_components=5)
        header = _parse_index_header(path)
        guidance = INDEX_PROMPT_GUIDANCE.format(
            index_path=path.resolve(),
            source_revision=header["source_revision"],
            format_version=header["format_version"],
            component_count=header["component_count"],
        )
        assert "5 components" in guidance

    def test_baseline_prompt_has_no_index_guidance(self):
        tree = Path("/fake/tree")
        prompt = SYSTEM_PROMPT_TEMPLATE.format(tree_path=tree)
        assert "INDEX.md" not in prompt
        assert "index" not in prompt.lower()

    def test_query_prompt_has_no_index_guidance(self):
        tree = Path("/fake/tree")
        guidance = QUERY_PROMPT_GUIDANCE.format(tree_path=tree)
        assert "INDEX.md" not in guidance
        assert "read-only evidence" not in guidance

    def test_parse_index_header_returns_provenance(self, tmp_path):
        path = _write_valid_index(tmp_path)
        header = _parse_index_header(path)
        assert header["source_revision"] == "abc123"
        assert header["format_version"] == INDEX_FORMAT_VERSION
        assert header["component_count"] == 3

    def test_parse_index_header_missing_file(self, tmp_path):
        header = _parse_index_header(tmp_path / "nonexistent.md")
        assert header == {}

    def test_parse_index_header_invalid_content(self, tmp_path):
        bad = tmp_path / "INDEX.md"
        bad.write_text("not a valid index")
        header = _parse_index_header(bad)
        assert header == {}


# ---------------------------------------------------------------------------
# Runner CLI: dry-run with index-md
# ---------------------------------------------------------------------------


def _run_cli(extra_args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(RUNNER_PATH)] + extra_args,
        capture_output=True,
        text=True,
    )


class TestRunnerIndexMdDryRun:
    def test_index_md_dry_run_available_with_artifact(self):
        index_path = str(MANIFEST_PATH.parent / "INDEX.md")
        artifact = json.dumps({
            "type": "architecture-tree-with-index",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
        })
        result = _run_cli([
            "--condition", "index-md",
            "--artifact-json", artifact,
            "--index-artifact-path", index_path,
            "--dry-run",
        ])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "index-md"
        assert plan["available"] is True
        assert plan["index_artifact_path"] == index_path

    def test_index_md_dry_run_fails_without_artifact_path(self):
        artifact = json.dumps({
            "type": "architecture-tree-with-index",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
        })
        result = _run_cli([
            "--condition", "index-md",
            "--artifact-json", artifact,
            "--dry-run",
        ])
        assert result.returncode == 1
        assert "index_artifact_path" in result.stderr

    def test_baseline_dry_run_unchanged(self):
        result = _run_cli(["--condition", "baseline", "--dry-run"])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "baseline"
        assert plan["available"] is True
        assert plan["index_artifact_path"] is None

    def test_arch_query_dry_run_unchanged(self):
        artifact = json.dumps({
            "type": "architecture-tree-with-query",
            "revision_source": "git_sha",
            "query_binary_version": "test-sha",
        })
        result = _run_cli([
            "--condition", "arch-query",
            "--artifact-json", artifact,
            "--dry-run",
        ])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "arch-query"
        assert plan["available"] is True
        assert plan["index_artifact_path"] is None


class TestRunnerCombinedNoFallback:
    def test_combined_requires_both_artifacts(self):
        result = _run_cli([
            "--condition", "combined",
            "--dry-run",
        ])
        assert result.returncode != 0
        assert "artifact_identity" in result.stderr

    def test_combined_dry_run_with_artifacts(self):
        index_path = str(MANIFEST_PATH.parent / "INDEX.md")
        artifact = json.dumps({
            "type": "architecture-tree-with-index-and-query",
            "revision_source": "git_sha",
            "index_revision_source": "test-gen-sha",
            "query_binary_version": "test-binary-sha",
        })
        result = _run_cli([
            "--condition", "combined",
            "--artifact-json", artifact,
            "--index-artifact-path", index_path,
            "--dry-run",
        ])
        assert result.returncode == 0
        plan = json.loads(result.stdout)
        assert plan["condition_id"] == "combined"
        assert plan["available"] is True
        assert plan["index_artifact_path"] == index_path


# ---------------------------------------------------------------------------
# Real manifest integration
# ---------------------------------------------------------------------------


class TestRealManifestIntegration:
    def test_real_manifest_baseline_31_questions(self):
        manifest = load_manifest(MANIFEST_PATH)
        plan = plan_condition(
            manifest, "baseline",
            artifact_identity=BASELINE_ARTIFACT,
        )
        assert len(plan["question_ids"]) == 31
        assert plan["index_artifact_path"] is None

    def test_real_manifest_index_md_available(self):
        manifest = load_manifest(MANIFEST_PATH)
        index_path = str(MANIFEST_PATH.parent / "INDEX.md")
        plan = plan_condition(
            manifest, "index-md",
            artifact_identity=INDEX_MD_ARTIFACT,
            index_artifact_path=index_path,
        )
        assert plan["available"] is True
        assert plan["status"] == "available"
        assert plan["index_artifact_path"] == index_path

    def test_real_manifest_combined_available(self):
        manifest = load_manifest(MANIFEST_PATH)
        index_path = str(MANIFEST_PATH.parent / "INDEX.md")
        plan = plan_condition(
            manifest, "combined",
            artifact_identity={
                "type": "architecture-tree-with-index-and-query",
                "revision_source": "git_sha",
                "index_revision_source": "56eb7ab043e99c8e00f91f2903d2ed625e694049",
                "query_binary_version": "test-sha",
            },
            index_artifact_path=index_path,
        )
        assert plan["available"] is True
        assert plan["status"] == "available"
        assert plan["index_artifact_path"] == index_path

    def test_real_manifest_arch_query_available(self):
        manifest = load_manifest(MANIFEST_PATH)
        plan = plan_condition(
            manifest, "arch-query",
            artifact_identity={
                "type": "architecture-tree-with-query",
                "revision_source": "git_sha",
                "query_binary_version": "sha",
            },
        )
        assert plan["available"] is True
        assert plan["index_artifact_path"] is None
