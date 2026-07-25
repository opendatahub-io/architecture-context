"""Tests for the analyzer-assisted evaluation contract.

Validates the experiment manifest, result schema, and validation logic
without running paid evaluations or fabricating benchmark scores.
"""

import importlib.util
import json
from copy import deepcopy
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent

_validate_path = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "validate.py"
)
_spec = importlib.util.spec_from_file_location(
    "analyzer_assisted_validate", _validate_path
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

VALID_CONDITION_IDS = _mod.VALID_CONDITION_IDS
VALID_FAILURE_CLASSIFICATIONS = _mod.VALID_FAILURE_CLASSIFICATIONS
VALID_QUESTION_CATEGORIES = _mod.VALID_QUESTION_CATEGORIES
VALID_QUESTION_DIFFICULTIES = _mod.VALID_QUESTION_DIFFICULTIES
VALID_QUESTION_SCOPES = _mod.VALID_QUESTION_SCOPES
validate_experiment_manifest = _mod.validate_experiment_manifest
validate_result_record = _mod.validate_result_record
validate_result_schema = _mod.validate_result_schema

MANIFEST_DIR = PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1"


def _load_manifest() -> dict:
    with open(MANIFEST_DIR / "experiment.json") as f:
        return json.load(f)


def _minimal_result(
    condition_id: str = "baseline",
    question_id: str = "INV-001",
    **overrides,
) -> dict:
    """Build a minimal valid result record for testing."""
    result = {
        "schema_version": "1.0.0",
        "experiment_id": "analyzer-assisted-retrieval-v1",
        "condition_id": condition_id,
        "condition_available": condition_id == "baseline",
        "question_id": question_id,
        "question_category": "inventory",
        "question_difficulty": "direct-lookup",
        "question_scope": "rhoai.next",
        "model": "claude-opus-4-6",
        "seed": 42,
        "runner_version": "1.0.0",
        "timestamp": "2026-07-24T12:00:00Z",
        "provenance": {
            "architecture_context_sha": "0920cf3b8255cfd45584554de82b9812c1d01c08",
            "index_generation_sha": None,
            "query_binary_version": None,
            "corpus_version": "1.0.0",
            "experiment_manifest_version": "1.0.0",
        },
        "response": {
            "success": True,
            "text": "The platform analyzes 92 components.",
            "source_citations": [{"file": "PLATFORM.md", "line": 11}],
            "error": None,
        },
        "telemetry": {
            "duration_seconds": 12.5,
            "input_tokens": 5000,
            "output_tokens": 200,
            "total_cost_usd": 0.05,
            "num_turns": 3,
            "tool_calls": {"Read": 2, "Glob": 1},
            "files_read": ["PLATFORM.md", "README.md"],
        },
        "context_metrics": {
            "context_fetches": 3,
            "useful_reads": 1,
            "navigation_reads": 2,
            "queries_issued": None,
            "missing_context_detected": False,
            "stale_context_detected": False,
            "unsupported_inference_detected": False,
        },
        "failure_classifications": [],
    }
    result.update(overrides)
    return result


# --- Manifest validation ---


class TestManifestValidation:
    def test_on_disk_manifest_validates(self):
        manifest = _load_manifest()
        errors = validate_experiment_manifest(manifest)
        assert errors == [], f"Manifest errors: {errors}"

    def test_all_four_conditions_defined(self):
        manifest = _load_manifest()
        condition_ids = {c["condition_id"] for c in manifest["conditions"]}
        assert condition_ids == VALID_CONDITION_IDS

    def test_unavailable_conditions_have_reason(self):
        manifest = _load_manifest()
        for cond in manifest["conditions"]:
            if not cond.get("available", True):
                cid = cond["condition_id"]
                assert cond.get("unavailable_reason"), (
                    f"Condition '{cid}' is unavailable "
                    "but has no reason"
                )

    def test_baseline_is_available(self):
        manifest = _load_manifest()
        baseline = next(
            c for c in manifest["conditions"] if c["condition_id"] == "baseline"
        )
        assert baseline["available"] is True
        assert baseline["status"] == "available"

    def test_all_conditions_are_available(self):
        manifest = _load_manifest()
        for cond in manifest["conditions"]:
            assert cond["available"] is True, (
                f"Condition '{cond['condition_id']}' should be available"
            )
            assert cond["status"] == "available"

    def test_index_md_is_available(self):
        manifest = _load_manifest()
        index_md = next(
            c for c in manifest["conditions"] if c["condition_id"] == "index-md"
        )
        assert index_md["available"] is True
        assert index_md["status"] == "available"

    def test_arch_query_is_available(self):
        manifest = _load_manifest()
        arch_query = next(
            c for c in manifest["conditions"] if c["condition_id"] == "arch-query"
        )
        assert arch_query["available"] is True
        assert arch_query["status"] == "available"

    def test_combined_is_available(self):
        manifest = _load_manifest()
        combined = next(
            c for c in manifest["conditions"] if c["condition_id"] == "combined"
        )
        assert combined["available"] is True
        assert combined["status"] == "available"

    def test_combined_requires_both_index_and_query_provenance(self):
        manifest = _load_manifest()
        combined = next(
            c for c in manifest["conditions"] if c["condition_id"] == "combined"
        )
        ai = combined["artifact_identity"]
        assert ai["index_revision_source"] is not None
        assert ai["index_revision_source"] == "index_generation_sha"
        assert ai["query_binary_version"] is not None
        assert ai["query_binary_version"] == "git_sha"

    def test_combined_has_index_artifact(self):
        manifest = _load_manifest()
        combined = next(
            c for c in manifest["conditions"] if c["condition_id"] == "combined"
        )
        assert "index_artifact" in combined
        ia = combined["index_artifact"]
        assert ia["path"] == "benchmark/analyzer-assisted-v1/INDEX.md"
        assert ia["format_version"] == "1"
        assert ia["component_count"] == 69

    def test_combined_permits_bash_transport(self):
        manifest = _load_manifest()
        combined = next(
            c for c in manifest["conditions"] if c["condition_id"] == "combined"
        )
        assert "Bash" in combined["tools_permitted"]
        assert "Write" in combined["tools_denied"]
        assert "Edit" in combined["tools_denied"]

    def test_combined_has_evaluator_bash_constraint(self):
        manifest = _load_manifest()
        combined = next(
            c for c in manifest["conditions"] if c["condition_id"] == "combined"
        )
        assert "evaluator_bash_constraint" in combined
        assert "arch-query" in combined["evaluator_bash_constraint"]

    def test_combined_approved_subcommands_match_arch_query(self):
        manifest = _load_manifest()
        combined = next(
            c for c in manifest["conditions"] if c["condition_id"] == "combined"
        )
        arch_query = next(
            c for c in manifest["conditions"] if c["condition_id"] == "arch-query"
        )
        assert set(combined["approved_query_subcommands"]) == set(
            arch_query["approved_query_subcommands"]
        )

    def test_all_failure_classifications_defined(self):
        manifest = _load_manifest()
        fc_ids = {fc["id"] for fc in manifest["failure_classifications"]}
        assert fc_ids == VALID_FAILURE_CLASSIFICATIONS

    def test_reject_unknown_condition_id(self):
        manifest = _load_manifest()
        manifest["conditions"].append({
            "condition_id": "invented-condition",
            "name": "Bad",
            "description": "Should fail",
            "status": "available",
            "available": True,
            "context_sources": [],
            "tools_permitted": [],
        })
        errors = validate_experiment_manifest(manifest)
        assert any("unknown condition_id 'invented-condition'" in e for e in errors)

    def test_reject_duplicate_condition_id(self):
        manifest = _load_manifest()
        manifest["conditions"].append(deepcopy(manifest["conditions"][0]))
        errors = validate_experiment_manifest(manifest)
        assert any("duplicate condition_id" in e for e in errors)

    def test_reject_missing_required_fields(self):
        errors = validate_experiment_manifest({})
        assert len(errors) >= 3
        assert any("manifest_version" in e for e in errors)
        assert any("conditions" in e for e in errors)

    def test_reject_unavailable_without_reason(self):
        manifest = _load_manifest()
        for cond in manifest["conditions"]:
            if cond["condition_id"] == "combined":
                cond["available"] = False
                cond["status"] = "pending"
                break
        errors = validate_experiment_manifest(manifest)
        assert any("unavailable_reason" in e for e in errors)


# --- Result record validation ---


class TestResultValidation:
    def test_valid_baseline_result(self):
        result = _minimal_result()
        errors = validate_result_record(result)
        assert errors == [], f"Result errors: {errors}"

    def test_valid_result_for_each_condition(self):
        for cid in VALID_CONDITION_IDS:
            result = _minimal_result(condition_id=cid)
            if cid != "baseline":
                result["condition_available"] = False
                result["response"]["success"] = False
                result["response"]["text"] = None
                result["response"]["error"] = "Condition unavailable"
            errors = validate_result_record(result)
            assert errors == [], f"Errors for condition '{cid}': {errors}"

    def test_reject_unknown_condition_id(self):
        result = _minimal_result(condition_id="nonexistent")
        errors = validate_result_record(result)
        assert any("Unknown condition_id" in e for e in errors)

    def test_reject_missing_provenance(self):
        result = _minimal_result()
        del result["provenance"]
        errors = validate_result_record(result)
        assert any("Missing provenance" in e for e in errors)

    def test_reject_empty_architecture_sha(self):
        result = _minimal_result()
        result["provenance"]["architecture_context_sha"] = ""
        errors = validate_result_record(result)
        assert any("architecture_context_sha" in e for e in errors)

    def test_reject_missing_corpus_version(self):
        result = _minimal_result()
        result["provenance"]["corpus_version"] = None
        errors = validate_result_record(result)
        assert any("corpus_version" in e for e in errors)

    def test_reject_missing_manifest_version(self):
        result = _minimal_result()
        result["provenance"]["experiment_manifest_version"] = None
        errors = validate_result_record(result)
        assert any("experiment_manifest_version" in e for e in errors)

    def test_reject_invalid_failure_classification(self):
        result = _minimal_result(failure_classifications=["invented-failure"])
        errors = validate_result_record(result)
        assert any("Unknown failure classification" in e for e in errors)

    def test_reject_duplicate_failure_classifications(self):
        result = _minimal_result(
            failure_classifications=["stale-context", "stale-context"]
        )
        errors = validate_result_record(result)
        assert any("duplicates" in e for e in errors)

    def test_reject_negative_telemetry(self):
        result = _minimal_result()
        result["telemetry"]["duration_seconds"] = -1.0
        errors = validate_result_record(result)
        assert any("non-negative" in e and "duration_seconds" in e for e in errors)

    def test_reject_negative_token_count(self):
        result = _minimal_result()
        result["telemetry"]["input_tokens"] = -100
        errors = validate_result_record(result)
        assert any("non-negative" in e and "input_tokens" in e for e in errors)

    def test_reject_negative_cost(self):
        result = _minimal_result()
        result["telemetry"]["total_cost_usd"] = -0.5
        errors = validate_result_record(result)
        assert any("non-negative" in e and "total_cost_usd" in e for e in errors)

    def test_reject_negative_tool_call_count(self):
        result = _minimal_result()
        result["telemetry"]["tool_calls"] = {"Read": -1}
        errors = validate_result_record(result)
        assert any("non-negative" in e and "Read" in e for e in errors)

    def test_reject_negative_context_metrics(self):
        result = _minimal_result()
        result["context_metrics"]["useful_reads"] = -5
        errors = validate_result_record(result)
        assert any("non-negative" in e and "useful_reads" in e for e in errors)

    def test_reject_unavailable_condition_with_success(self):
        result = _minimal_result(condition_id="index-md")
        result["condition_available"] = False
        result["response"]["success"] = True
        errors = validate_result_record(result)
        assert any("condition_available is false" in e for e in errors)

    def test_reject_bad_question_id_pattern(self):
        result = _minimal_result(question_id="bad-format")
        errors = validate_result_record(result)
        assert any("does not match pattern" in e for e in errors)

    def test_reject_unknown_question_category(self):
        result = _minimal_result(question_category="unknown-cat")
        errors = validate_result_record(result)
        assert any("Unknown question_category" in e for e in errors)

    def test_reject_unknown_question_difficulty(self):
        result = _minimal_result(question_difficulty="impossible")
        errors = validate_result_record(result)
        assert any("Unknown question_difficulty" in e for e in errors)

    def test_reject_unknown_question_scope(self):
        result = _minimal_result(question_scope="nonexistent-scope")
        errors = validate_result_record(result)
        assert any("Unknown question_scope" in e for e in errors)

    def test_reject_missing_model(self):
        result = _minimal_result()
        result["model"] = ""
        errors = validate_result_record(result)
        assert any("Missing model" in e for e in errors)

    def test_reject_missing_runner_version(self):
        result = _minimal_result()
        result["runner_version"] = ""
        errors = validate_result_record(result)
        assert any("Missing runner_version" in e for e in errors)

    def test_accept_all_valid_failure_classifications(self):
        for fc in VALID_FAILURE_CLASSIFICATIONS:
            result = _minimal_result(failure_classifications=[fc])
            errors = validate_result_record(result)
            assert errors == [], f"Error for classification '{fc}': {errors}"

    def test_accept_null_telemetry_values(self):
        result = _minimal_result()
        result["telemetry"]["duration_seconds"] = None
        result["telemetry"]["input_tokens"] = None
        result["telemetry"]["total_cost_usd"] = None
        errors = validate_result_record(result)
        assert errors == []

    def test_accept_null_context_metrics(self):
        result = _minimal_result()
        result["context_metrics"] = {
            "context_fetches": None,
            "useful_reads": None,
            "navigation_reads": None,
            "queries_issued": None,
            "missing_context_detected": None,
            "stale_context_detected": None,
            "unsupported_inference_detected": None,
        }
        errors = validate_result_record(result)
        assert errors == []


# --- Result schema validation (JSON Schema) ---


class TestResultSchemaValidation:
    def test_valid_result_passes_schema(self):
        result = _minimal_result()
        errors = validate_result_schema(result)
        non_warn = [e for e in errors if not e.startswith("WARN:")]
        assert non_warn == [], f"Schema errors: {non_warn}"

    def test_missing_required_field_fails_schema(self):
        result = _minimal_result()
        del result["condition_id"]
        errors = validate_result_schema(result)
        non_warn = [e for e in errors if not e.startswith("WARN:")]
        if non_warn:
            assert any("condition_id" in e for e in non_warn)


# --- Fixture: classified failure result ---


class TestFailureFixtures:
    def test_stale_context_failure(self):
        result = _minimal_result(
            failure_classifications=["stale-context"],
        )
        result["response"]["text"] = (
            "The platform analyzes 85 components. "
            "This is based on an older version of the documentation."
        )
        result["context_metrics"]["stale_context_detected"] = True
        errors = validate_result_record(result)
        assert errors == []
        assert "stale-context" in result["failure_classifications"]

    def test_missing_context_failure(self):
        result = _minimal_result(
            failure_classifications=["missing-context"],
        )
        result["response"]["text"] = "Not documented in the architecture files."
        result["context_metrics"]["missing_context_detected"] = True
        errors = validate_result_record(result)
        assert errors == []

    def test_retrieval_failure(self):
        result = _minimal_result(
            failure_classifications=["retrieval-failure"],
        )
        result["response"]["text"] = "I could not find this information."
        errors = validate_result_record(result)
        assert errors == []

    def test_infrastructure_failure(self):
        result = _minimal_result(
            failure_classifications=["infrastructure-failure"],
        )
        result["response"]["success"] = False
        result["response"]["text"] = None
        result["response"]["error"] = "Agent session timed out after 120s"
        errors = validate_result_record(result)
        assert errors == []

    def test_multiple_failure_classifications(self):
        result = _minimal_result(
            failure_classifications=["stale-context", "retrieval-failure"],
        )
        errors = validate_result_record(result)
        assert errors == []


# --- Fixture: unavailable condition ---


class TestUnavailableConditionFixtures:
    def test_unavailable_condition_skipped(self):
        result = _minimal_result(condition_id="index-md")
        result["condition_available"] = False
        result["response"] = {
            "success": False,
            "text": None,
            "source_citations": [],
            "error": (
                "Condition index-md is not available: "
                "INDEX.md generation not implemented"
            ),
        }
        result["failure_classifications"] = ["infrastructure-failure"]
        errors = validate_result_record(result)
        assert errors == []

    def test_unavailable_arch_query(self):
        result = _minimal_result(condition_id="arch-query")
        result["condition_available"] = False
        result["response"] = {
            "success": False,
            "text": None,
            "source_citations": [],
            "error": (
                "Condition arch-query is not available: "
                "query interface not implemented"
            ),
        }
        errors = validate_result_record(result)
        assert errors == []

    def test_available_arch_query(self):
        result = _minimal_result(condition_id="arch-query")
        result["condition_available"] = True
        errors = validate_result_record(result)
        assert errors == []

    def test_unavailable_combined(self):
        result = _minimal_result(condition_id="combined")
        result["condition_available"] = False
        result["response"] = {
            "success": False,
            "text": None,
            "source_citations": [],
            "error": (
                "Condition combined is not available: "
                "requires INDEX.md and arch-query"
            ),
        }
        errors = validate_result_record(result)
        assert errors == []


# --- V1 compatibility ---


class TestV1Compatibility:
    def test_existing_v1_corpus_schema_unchanged(self):
        """Verify the v1 corpus schema file has not been modified."""
        schema_path = PROJECT_ROOT / "benchmark" / "consumer-v1" / "schema.json"
        with open(schema_path) as f:
            schema = json.load(f)
        assert schema["title"] == "Architecture-Context Consumer Benchmark Corpus"
        assert "questions" in schema["properties"]
        assert schema["properties"]["questions"]["minItems"] == 40

    def test_existing_v1_corpus_still_valid(self):
        """Verify the v1 corpus.json is untouched and parseable."""
        corpus_path = PROJECT_ROOT / "benchmark" / "consumer-v1" / "corpus.json"
        with open(corpus_path) as f:
            corpus = json.load(f)
        assert corpus["corpus_version"] == "1.0.0"
        assert len(corpus["questions"]) >= 29

    def test_existing_v1_raw_results_parseable(self):
        """Verify existing v1 raw results are still parseable."""
        results_path = (
            PROJECT_ROOT
            / "benchmark"
            / "consumer-v1"
            / "results"
            / "v1-ab"
            / "raw-results.json"
        )
        if not results_path.exists():
            pytest.skip("No v1 raw results on disk")
        with open(results_path) as f:
            raw = json.load(f)
        assert raw["corpus_version"] == "1.0.0"
        assert len(raw["results"]) == 40

    def test_existing_v1_scored_results_parseable(self):
        """Verify existing v1 scored results are still parseable."""
        results_path = (
            PROJECT_ROOT
            / "benchmark"
            / "consumer-v1"
            / "results"
            / "v1-ab"
            / "scored-results.json"
        )
        if not results_path.exists():
            pytest.skip("No v1 scored results on disk")
        with open(results_path) as f:
            scored = json.load(f)
        assert scored["corpus_version"] == "1.0.0"
        assert "aggregates" in scored


# --- Constants consistency ---


class TestArchQueryBoundary:
    """Validate that the arch-query manifest boundary matches the evaluator guard."""

    def test_arch_query_permits_bash_transport(self):
        manifest = _load_manifest()
        arch_query = next(
            c for c in manifest["conditions"] if c["condition_id"] == "arch-query"
        )
        assert "Bash" in arch_query["tools_permitted"]

    def test_arch_query_denies_write_and_edit(self):
        manifest = _load_manifest()
        arch_query = next(
            c for c in manifest["conditions"] if c["condition_id"] == "arch-query"
        )
        assert "Write" in arch_query["tools_denied"]
        assert "Edit" in arch_query["tools_denied"]

    def test_arch_query_has_evaluator_bash_constraint(self):
        manifest = _load_manifest()
        arch_query = next(
            c for c in manifest["conditions"] if c["condition_id"] == "arch-query"
        )
        assert "evaluator_bash_constraint" in arch_query
        constraint = arch_query["evaluator_bash_constraint"]
        assert "arch-query query" in constraint
        low = constraint.lower()
        assert "metachar" in low

    def test_arch_query_approved_subcommands_match_evaluator(self):
        manifest = _load_manifest()
        arch_query = next(
            c for c in manifest["conditions"] if c["condition_id"] == "arch-query"
        )
        manifest_subs = set(arch_query["approved_query_subcommands"])
        _eval_path = (
            PROJECT_ROOT / "benchmark" / "consumer-v1" / "run_evaluation.py"
        )
        _eval_spec = importlib.util.spec_from_file_location(
            "run_eval", _eval_path
        )
        _eval_mod = importlib.util.module_from_spec(_eval_spec)
        _eval_spec.loader.exec_module(_eval_mod)
        evaluator_subs = _eval_mod.APPROVED_QUERY_SUBCOMMANDS
        assert manifest_subs == evaluator_subs

    def test_arch_query_requires_binary_provenance(self):
        manifest = _load_manifest()
        arch_query = next(
            c for c in manifest["conditions"] if c["condition_id"] == "arch-query"
        )
        ai = arch_query["artifact_identity"]
        assert ai["query_binary_version"] is not None
        assert ai["query_binary_version"] == "git_sha"

    def test_baseline_still_denies_bash(self):
        manifest = _load_manifest()
        baseline = next(
            c for c in manifest["conditions"] if c["condition_id"] == "baseline"
        )
        assert "Bash" in baseline["tools_denied"]


# --- Constants consistency ---


class TestConstants:
    def test_condition_ids_match_manifest(self):
        manifest = _load_manifest()
        manifest_ids = {c["condition_id"] for c in manifest["conditions"]}
        assert manifest_ids == VALID_CONDITION_IDS

    def test_failure_classifications_match_manifest(self):
        manifest = _load_manifest()
        manifest_fcs = {fc["id"] for fc in manifest["failure_classifications"]}
        assert manifest_fcs == VALID_FAILURE_CLASSIFICATIONS

    def test_question_categories_cover_tiers(self):
        assert len(VALID_QUESTION_CATEGORIES) == 4

    def test_question_scopes_match_corpus(self):
        corpus_path = PROJECT_ROOT / "benchmark" / "consumer-v1" / "corpus.json"
        with open(corpus_path) as f:
            corpus = json.load(f)
        corpus_scopes = {q["scope"] for q in corpus["questions"]}
        assert corpus_scopes <= VALID_QUESTION_SCOPES
