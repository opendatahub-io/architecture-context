"""Tests for the condition-aware canary report and validator.

Validates deterministic ordering, absent-result safety, pending condition
handling, provenance coverage, no-fallback violations, and explicit
no-score behavior without launching agents or running evaluations.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

_report_path = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "canary_report.py"
)
_spec = importlib.util.spec_from_file_location("canary_report", _report_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

load_canary_manifest = _mod.load_canary_manifest
load_experiment_manifest = _mod.load_experiment_manifest
generate_report = _mod.generate_report
main = _mod.main
_determine_state = _mod._determine_state
_check_provenance = _mod._check_provenance
_check_context_telemetry = _mod._check_context_telemetry
_load_results = _mod._load_results
CONTRACT_VERSION = _mod.CONTRACT_VERSION

CANARY_PATH = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "canary_manifest.json"
)
EXPERIMENT_PATH = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "experiment.json"
)
CORPUS_PATH = (
    PROJECT_ROOT
    / "benchmark"
    / "analyzer-assisted-v1"
    / "corpus_manifest.json"
)


def _minimal_canary(
    *,
    question_ids: list[str] | None = None,
    condition_ids: list[str] | None = None,
) -> dict:
    if question_ids is None:
        question_ids = ["FACT-001", "INV-001"]
    if condition_ids is None:
        condition_ids = ["arch-query", "baseline", "combined", "index-md"]
    return {
        "manifest_version": "1.0.0",
        "canary_id": "test-canary",
        "corpus_ref": {
            "corpus_id": "test-corpus",
            "corpus_version": "1.0.0",
        },
        "experiment_ref": {
            "experiment_id": "test-experiment",
            "manifest_version": "1.0.0",
        },
        "condition_ids": sorted(condition_ids),
        "question_ids": sorted(question_ids),
    }


def _minimal_experiment(
    *,
    baseline_available: bool = True,
    conditions: list[dict] | None = None,
) -> dict:
    if conditions is not None:
        return {
            "manifest_version": "1.0.0",
            "experiment_id": "test-experiment",
            "conditions": conditions,
            "failure_classifications": [],
        }
    return {
        "manifest_version": "1.0.0",
        "experiment_id": "test-experiment",
        "conditions": [
            {
                "condition_id": "baseline",
                "name": "Baseline",
                "description": "Control",
                "status": "available" if baseline_available else "pending",
                "available": baseline_available,
                "context_sources": ["architecture/*.md"],
                "tools_permitted": ["Read"],
                "tools_denied": ["Write"],
                "artifact_identity": {
                    "type": "architecture-tree",
                    "revision_source": "git_sha",
                },
                "access_boundary": "Read-only.",
                **(
                    {}
                    if baseline_available
                    else {"unavailable_reason": "Not ready."}
                ),
            },
            {
                "condition_id": "index-md",
                "name": "INDEX.md",
                "description": "With INDEX.md",
                "status": "pending",
                "available": False,
                "unavailable_reason": "INDEX.md not implemented.",
                "context_sources": ["architecture/*.md", "INDEX.md"],
                "tools_permitted": ["Read"],
                "tools_denied": ["Write"],
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
                "unavailable_reason": "Query not implemented.",
                "context_sources": ["architecture/*.md"],
                "tools_permitted": ["Read", "arch-query"],
                "tools_denied": ["Write"],
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
                "unavailable_reason": "Requires both.",
                "context_sources": ["architecture/*.md", "INDEX.md"],
                "tools_permitted": ["Read", "arch-query"],
                "tools_denied": ["Write"],
                "artifact_identity": {
                    "type": "architecture-tree-with-index-and-query",
                    "revision_source": "git_sha",
                    "index_revision_source": "index_generation_sha",
                    "query_binary_version": None,
                },
                "access_boundary": "Full context.",
            },
        ],
        "failure_classifications": [],
    }


def _make_result(
    condition_id: str,
    question_id: str,
    *,
    provenance: dict | None = None,
) -> dict:
    if provenance is None:
        provenance = {
            "architecture_context_sha": "abc123",
            "corpus_version": "1.0.0",
            "experiment_manifest_version": "1.0.0",
        }
    return {
        "condition_id": condition_id,
        "question_id": question_id,
        "provenance": provenance,
        "response": {"success": True},
    }


def _all_available_experiment() -> dict:
    """Experiment fixture where all four conditions are available."""
    return {
        "manifest_version": "1.0.0",
        "experiment_id": "test-experiment",
        "conditions": [
            {
                "condition_id": "baseline",
                "name": "Baseline",
                "description": "Control",
                "status": "available",
                "available": True,
                "context_sources": ["architecture/*.md"],
                "tools_permitted": ["Read"],
                "tools_denied": ["Write"],
                "artifact_identity": {
                    "type": "architecture-tree",
                    "revision_source": "git_sha",
                },
                "access_boundary": "Read-only.",
            },
            {
                "condition_id": "index-md",
                "name": "INDEX.md",
                "description": "With INDEX.md",
                "status": "available",
                "available": True,
                "context_sources": ["architecture/*.md", "INDEX.md"],
                "tools_permitted": ["Read"],
                "tools_denied": ["Write"],
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
                "tools_permitted": ["Read", "arch-query"],
                "tools_denied": ["Write"],
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
                "status": "available",
                "available": True,
                "context_sources": ["architecture/*.md", "INDEX.md"],
                "tools_permitted": ["Read", "arch-query"],
                "tools_denied": ["Write"],
                "artifact_identity": {
                    "type": "architecture-tree-with-index-and-query",
                    "revision_source": "git_sha",
                    "index_revision_source": "index_generation_sha",
                    "query_binary_version": "git_sha",
                },
                "access_boundary": "Full context.",
            },
        ],
        "failure_classifications": [],
    }


def _make_result_with_telemetry(
    condition_id: str,
    question_id: str,
    *,
    provenance: dict | None = None,
    context_provenance: dict | None = None,
) -> dict:
    if provenance is None:
        provenance = {
            "architecture_context_sha": "abc123",
            "corpus_version": "1.0.0",
            "experiment_manifest_version": "1.0.0",
            "context_telemetry_version": "1.0.0",
            "context_provenance": {
                "context_telemetry_version": "1.0.0",
                "events_attached_per_tree": True,
            },
        }
    if context_provenance is None:
        context_provenance = {
            "context_telemetry_version": "1.0.0",
            "context_events": [],
        }
    return {
        "condition_id": condition_id,
        "question_id": question_id,
        "provenance": provenance,
        "context_provenance": context_provenance,
        "response": {"success": True},
    }


def _write_results(results_dir: Path, results: list[dict]) -> None:
    results_dir.mkdir(parents=True, exist_ok=True)
    by_condition: dict[str, list[dict]] = {}
    for r in results:
        by_condition.setdefault(r["condition_id"], []).append(r)
    for cid, records in by_condition.items():
        with open(results_dir / f"{cid}.json", "w") as f:
            json.dump(records, f)


# --- Deterministic Ordering ---


class TestDeterministicOrdering:
    def test_entries_sorted_by_question_then_condition(self):
        canary = _minimal_canary(
            question_ids=["INV-001", "FACT-001"],
            condition_ids=["baseline", "index-md"],
        )
        experiment = _minimal_experiment()
        report = generate_report(canary, experiment, corpus_manifest_path=None)
        pairs = [
            (e["question_id"], e["condition_id"]) for e in report["entries"]
        ]
        assert pairs == [
            ("FACT-001", "baseline"),
            ("FACT-001", "index-md"),
            ("INV-001", "baseline"),
            ("INV-001", "index-md"),
        ]

    def test_repeated_calls_identical(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        r1 = generate_report(canary, experiment, corpus_manifest_path=None)
        r2 = generate_report(canary, experiment, corpus_manifest_path=None)
        assert r1 == r2

    def test_json_round_trip_stable(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(canary, experiment, corpus_manifest_path=None)
        serialized = json.dumps(report, sort_keys=True)
        roundtripped = json.loads(serialized)
        assert roundtripped == report

    def test_condition_ids_sorted_in_output(self):
        canary = _minimal_canary(
            condition_ids=["combined", "baseline", "arch-query", "index-md"]
        )
        experiment = _minimal_experiment()
        report = generate_report(canary, experiment, corpus_manifest_path=None)
        assert report["condition_ids"] == sorted(report["condition_ids"])

    def test_question_ids_sorted_in_output(self):
        canary = _minimal_canary(question_ids=["INV-001", "FACT-001"])
        experiment = _minimal_experiment()
        report = generate_report(canary, experiment, corpus_manifest_path=None)
        assert report["question_ids"] == sorted(report["question_ids"])

    def test_violations_sorted(self):
        canary = _minimal_canary(
            condition_ids=["baseline", "index-md"],
            question_ids=["INV-001", "FACT-001"],
        )
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, corpus_manifest_path=CORPUS_PATH
        )
        violations = report["violations"]
        keys = [
            (v["type"], v.get("condition_id") or "", v.get("question_id") or "")
            for v in violations
        ]
        assert keys == sorted(keys)


# --- Absent Results ---


class TestAbsentResults:
    def test_no_results_dir_all_planned_or_unavailable(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        for e in report["entries"]:
            assert e["state"] in ("planned", "unavailable")
            assert e["result_found"] is False

    def test_no_results_dir_no_crash(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        assert "entries" in report
        assert "violations" in report
        assert "summary" in report

    def test_nonexistent_results_dir(self, tmp_path):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        bogus = tmp_path / "nonexistent"
        report = generate_report(
            canary, experiment, results_dir=bogus, corpus_manifest_path=None
        )
        for e in report["entries"]:
            assert e["state"] in ("planned", "unavailable")

    def test_empty_results_dir(self, tmp_path):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        empty_dir = tmp_path / "empty"
        empty_dir.mkdir()
        report = generate_report(
            canary, experiment, results_dir=empty_dir, corpus_manifest_path=None
        )
        for e in report["entries"]:
            if e["state"] != "unavailable":
                assert e["state"] == "missing-result"

    def test_provenance_null_when_no_results(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        for e in report["entries"]:
            assert e["provenance"] is None

    def test_report_valid_json_structure(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        assert isinstance(report["report_version"], str)
        assert isinstance(report["entries"], list)
        assert isinstance(report["violations"], list)
        assert isinstance(report["summary"], dict)
        assert isinstance(report["summary"]["total_cells"], int)
        assert isinstance(report["summary"]["by_state"], dict)


# --- Pending Conditions ---


class TestPendingConditions:
    def test_pending_conditions_are_unavailable(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        for e in report["entries"]:
            if e["condition_id"] != "baseline":
                assert e["state"] == "unavailable"

    def test_baseline_available_others_unavailable(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        states_by_condition: dict[str, set[str]] = {}
        for e in report["entries"]:
            states_by_condition.setdefault(e["condition_id"], set()).add(
                e["state"]
            )
        assert states_by_condition["baseline"] == {"planned"}
        for cid in ("index-md", "arch-query", "combined"):
            assert states_by_condition[cid] == {"unavailable"}

    def test_unavailable_count_in_summary(self):
        canary = _minimal_canary(
            question_ids=["FACT-001", "INV-001"],
            condition_ids=["baseline", "index-md", "arch-query", "combined"],
        )
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        assert report["summary"]["by_state"]["unavailable"] == 6
        assert report["summary"]["by_state"]["planned"] == 2

    def test_all_conditions_pending(self):
        canary = _minimal_canary(
            condition_ids=["baseline", "index-md"],
        )
        experiment = _minimal_experiment(baseline_available=False)
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        for e in report["entries"]:
            assert e["state"] == "unavailable"

    def test_unknown_condition_treated_as_unavailable(self):
        canary = _minimal_canary(condition_ids=["nonexistent"])
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        for e in report["entries"]:
            assert e["state"] == "unavailable"


# --- Provenance Coverage ---


class TestProvenanceCoverage:
    def test_complete_provenance_no_violation(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        prov_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-provenance"
        ]
        assert len(prov_violations) == 0

    def test_missing_sha_violation(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result(
                "baseline", "FACT-001",
                provenance={
                    "corpus_version": "1.0.0",
                    "experiment_manifest_version": "1.0.0",
                },
            ),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        prov_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-provenance"
        ]
        assert len(prov_violations) == 1
        assert "architecture_context_sha" in prov_violations[0]["message"]

    def test_missing_provenance_object_violation(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001", provenance=None),
        ])
        # Manually patch the written file to have null provenance
        result_file = results_dir / "baseline.json"
        data = json.loads(result_file.read_text())
        data[0]["provenance"] = None
        result_file.write_text(json.dumps(data))

        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        prov_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-provenance"
        ]
        assert len(prov_violations) == 1
        assert "missing provenance object" in prov_violations[0]["message"]

    def test_missing_corpus_version_violation(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result(
                "baseline", "FACT-001",
                provenance={
                    "architecture_context_sha": "abc123",
                    "experiment_manifest_version": "1.0.0",
                },
            ),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        prov_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-provenance"
        ]
        assert len(prov_violations) == 1
        assert "corpus_version" in prov_violations[0]["message"]

    def test_result_provenance_included_in_entry(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        prov = {
            "architecture_context_sha": "sha256abc",
            "corpus_version": "1.0.0",
            "experiment_manifest_version": "1.0.0",
        }
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001", provenance=prov),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        entry = report["entries"][0]
        assert entry["provenance"] == prov

    def test_coverage_violation_for_inactive_question(self, tmp_path):
        corpus = {
            "manifest_version": "1.0.0",
            "corpus_id": "test",
            "created": "2026-07-25",
            "description": "test",
            "source_artifacts": {
                "test": {
                    "verification_status": "audited",
                    "description": "test",
                },
            },
            "questions": [
                {
                    "id": "FACT-001",
                    "status": "retired",
                    "tier": 2,
                    "category": "deployment",
                    "difficulty": "unknown",
                    "scope": "unknown",
                    "source_corpus": "test",
                    "answerability_status": "undetermined",
                    "retirement_reason": "test",
                },
            ],
            "gaps": [],
            "aggregates": {
                "by_status": {"active": 0, "retired": 1},
                "by_tier": {"2": {"active": 0, "total": 1}},
                "by_category": {"deployment": {"retired": 1}},
                "by_difficulty": {"unknown": {"retired": 1}},
                "by_scope": {"unknown": {"retired": 1}},
                "by_answerability_status": {"undetermined": 1},
                "total_entries": 1,
                "total_active": 0,
                "total_retired": 1,
            },
        }
        corpus_path = tmp_path / "corpus_manifest.json"
        corpus_path.write_text(json.dumps(corpus))

        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, corpus_manifest_path=corpus_path,
        )
        coverage_violations = [
            v for v in report["violations"] if v["type"] == "coverage"
        ]
        assert len(coverage_violations) == 1
        assert "FACT-001" in coverage_violations[0]["message"]
        assert "not active" in coverage_violations[0]["message"]


# --- No-Fallback Violations ---


class TestNoFallbackViolations:
    def test_result_for_unavailable_condition(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline", "index-md"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("index-md", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        nf_violations = [
            v for v in report["violations"] if v["type"] == "no-fallback"
        ]
        assert len(nf_violations) == 1
        assert nf_violations[0]["condition_id"] == "index-md"
        assert nf_violations[0]["question_id"] == "FACT-001"

    def test_multiple_no_fallback_violations(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001", "INV-001"],
            condition_ids=["baseline", "index-md"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("index-md", "FACT-001"),
            _make_result("index-md", "INV-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        nf_violations = [
            v for v in report["violations"] if v["type"] == "no-fallback"
        ]
        assert len(nf_violations) == 2

    def test_unavailable_entry_state_despite_result(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["index-md"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("index-md", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        entry = report["entries"][0]
        assert entry["state"] == "unavailable"
        assert entry["result_found"] is True

    def test_no_violation_for_available_condition_result(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        nf_violations = [
            v for v in report["violations"] if v["type"] == "no-fallback"
        ]
        assert len(nf_violations) == 0

    def test_result_for_available_condition_shows_available_state(
        self, tmp_path
    ):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        entry = report["entries"][0]
        assert entry["state"] == "available"
        assert entry["result_found"] is True


# --- Explicit No-Score Behavior ---


class TestExplicitNoScore:
    def test_score_status_always_unavailable(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        for e in report["entries"]:
            assert e["score_status"] == "unavailable"

    def test_score_status_unavailable_even_with_results(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        for e in report["entries"]:
            assert e["score_status"] == "unavailable"

    def test_summary_score_status_unavailable(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        assert report["summary"]["score_status"] == "unavailable"

    def test_summary_score_status_unavailable_with_results(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        assert report["summary"]["score_status"] == "unavailable"

    def test_no_score_key_in_entries(self):
        canary = _minimal_canary()
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, results_dir=None, corpus_manifest_path=None
        )
        for e in report["entries"]:
            assert "score" not in e
            assert "score_value" not in e


# --- State Determination Unit Tests ---


class TestDetermineState:
    def test_unavailable_condition(self):
        assert _determine_state(False, False, False) == "unavailable"

    def test_unavailable_ignores_result(self):
        assert _determine_state(False, True, True) == "unavailable"

    def test_available_with_result(self):
        assert _determine_state(True, True, True) == "available"

    def test_available_no_result_no_dir(self):
        assert _determine_state(True, False, False) == "planned"

    def test_available_no_result_with_dir(self):
        assert _determine_state(True, False, True) == "missing-result"


# --- Invalid Condition Status ---


class TestInvalidConditionStatus:
    def test_missing_condition_in_experiment(self):
        canary = _minimal_canary(condition_ids=["nonexistent"])
        experiment = _minimal_experiment()
        report = generate_report(
            canary, experiment, corpus_manifest_path=None
        )
        status_violations = [
            v for v in report["violations"]
            if v["type"] == "invalid-condition-status"
        ]
        assert len(status_violations) == 1
        assert "not found" in status_violations[0]["message"]

    def test_available_true_but_status_pending(self):
        conditions = [
            {
                "condition_id": "baseline",
                "name": "Baseline",
                "description": "Control",
                "status": "pending",
                "available": True,
                "context_sources": ["architecture/*.md"],
                "tools_permitted": ["Read"],
                "tools_denied": ["Write"],
                "artifact_identity": {
                    "type": "architecture-tree",
                    "revision_source": "git_sha",
                },
                "access_boundary": "Read-only.",
            },
        ]
        canary = _minimal_canary(condition_ids=["baseline"])
        experiment = _minimal_experiment(conditions=conditions)
        report = generate_report(
            canary, experiment, corpus_manifest_path=None
        )
        status_violations = [
            v for v in report["violations"]
            if v["type"] == "invalid-condition-status"
        ]
        assert len(status_violations) == 1
        assert "available=true" in status_violations[0]["message"]
        assert "pending" in status_violations[0]["message"]

    def test_unavailable_without_reason(self):
        conditions = [
            {
                "condition_id": "baseline",
                "name": "Baseline",
                "description": "Control",
                "status": "pending",
                "available": False,
                "context_sources": ["architecture/*.md"],
                "tools_permitted": ["Read"],
                "tools_denied": ["Write"],
                "artifact_identity": {
                    "type": "architecture-tree",
                    "revision_source": "git_sha",
                },
                "access_boundary": "Read-only.",
            },
        ]
        canary = _minimal_canary(condition_ids=["baseline"])
        experiment = _minimal_experiment(conditions=conditions)
        report = generate_report(
            canary, experiment, corpus_manifest_path=None
        )
        status_violations = [
            v for v in report["violations"]
            if v["type"] == "invalid-condition-status"
        ]
        assert any(
            "unavailable_reason" in v["message"] for v in status_violations
        )


# --- Real Manifest Integration ---


class TestRealManifest:
    def test_load_real_canary_manifest(self):
        canary = load_canary_manifest(CANARY_PATH)
        assert canary["canary_id"] == "analyzer-assisted-v1-canary"
        assert len(canary["question_ids"]) == 10
        assert len(canary["condition_ids"]) == 4

    def test_canary_question_ids_sorted(self):
        canary = load_canary_manifest(CANARY_PATH)
        assert canary["question_ids"] == sorted(canary["question_ids"])

    def test_canary_condition_ids_sorted(self):
        canary = load_canary_manifest(CANARY_PATH)
        assert canary["condition_ids"] == sorted(canary["condition_ids"])

    def test_real_report_no_results(self):
        canary = load_canary_manifest(CANARY_PATH)
        experiment = load_experiment_manifest(EXPERIMENT_PATH)
        report = generate_report(
            canary, experiment,
            results_dir=None,
            corpus_manifest_path=CORPUS_PATH,
        )
        assert report["summary"]["total_cells"] == 40
        assert report["summary"]["by_state"]["planned"] == 40
        assert report["summary"]["by_state"]["unavailable"] == 0

    def test_real_report_all_canary_questions_in_active_corpus(self):
        canary = load_canary_manifest(CANARY_PATH)
        experiment = load_experiment_manifest(EXPERIMENT_PATH)
        report = generate_report(
            canary, experiment,
            results_dir=None,
            corpus_manifest_path=CORPUS_PATH,
        )
        coverage_violations = [
            v for v in report["violations"] if v["type"] == "coverage"
        ]
        assert len(coverage_violations) == 0

    def test_real_report_no_score_computed(self):
        canary = load_canary_manifest(CANARY_PATH)
        experiment = load_experiment_manifest(EXPERIMENT_PATH)
        report = generate_report(
            canary, experiment,
            results_dir=None,
            corpus_manifest_path=CORPUS_PATH,
        )
        assert report["summary"]["score_status"] == "unavailable"
        for e in report["entries"]:
            assert e["score_status"] == "unavailable"

    def test_real_report_tier_coverage(self):
        canary = load_canary_manifest(CANARY_PATH)
        tiers = canary.get("tier_coverage", {})
        assert "1" in tiers
        assert "2" in tiers
        assert "3" in tiers
        assert "4" in tiers
        all_ids = []
        for ids in tiers.values():
            all_ids.extend(ids)
        assert sorted(all_ids) == sorted(canary["question_ids"])


# --- CLI ---


class TestCLI:
    def test_cli_default_report(self):
        result = subprocess.run(
            [sys.executable, str(_report_path)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"stderr: {result.stderr}"
        report = json.loads(result.stdout)
        assert report["canary_id"] == "analyzer-assisted-v1-canary"
        assert len(report["entries"]) == 40

    def test_cli_validate_only(self):
        result = subprocess.run(
            [sys.executable, str(_report_path), "--validate-only"],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0

    def test_cli_bad_canary_path(self):
        result = subprocess.run(
            [
                sys.executable, str(_report_path),
                "--canary", "/nonexistent/canary.json",
            ],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 1

    def test_cli_output_is_valid_json(self):
        result = subprocess.run(
            [sys.executable, str(_report_path)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        report = json.loads(result.stdout)
        assert isinstance(report, dict)

    def test_cli_main_function(self):
        rc = main([
            "--canary", str(CANARY_PATH),
            "--experiment", str(EXPERIMENT_PATH),
            "--corpus-manifest", str(CORPUS_PATH),
        ])
        assert rc == 0


# --- Consumer-v1 Nested Results ---


class TestNestedResultsEnvelope:
    """Tests for consumer-v1 raw-results.json with records under a
    top-level ``results`` array."""

    def _write_nested_results(
        self, results_dir: Path, records: list[dict], filename: str = "raw-results.json"
    ) -> None:
        results_dir.mkdir(parents=True, exist_ok=True)
        with open(results_dir / filename, "w") as f:
            json.dump({"results": records}, f)

    def test_nested_envelope_produces_available_entries(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        self._write_nested_results(results_dir, [
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        entry = report["entries"][0]
        assert entry["state"] == "available"
        assert entry["result_found"] is True
        assert entry["score_status"] == "unavailable"

    def test_nested_envelope_multiple_records(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001", "INV-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        self._write_nested_results(results_dir, [
            _make_result("baseline", "FACT-001"),
            _make_result("baseline", "INV-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        available = [e for e in report["entries"] if e["state"] == "available"]
        assert len(available) == 2

    def test_nested_envelope_preserves_deterministic_order(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["INV-001", "FACT-001"],
            condition_ids=["baseline", "index-md"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        self._write_nested_results(results_dir, [
            _make_result("baseline", "INV-001"),
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        pairs = [
            (e["question_id"], e["condition_id"]) for e in report["entries"]
        ]
        assert pairs == [
            ("FACT-001", "baseline"),
            ("FACT-001", "index-md"),
            ("INV-001", "baseline"),
            ("INV-001", "index-md"),
        ]

    def test_nested_envelope_missing_provenance_violation(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        self._write_nested_results(results_dir, [
            _make_result(
                "baseline", "FACT-001",
                provenance={
                    "corpus_version": "1.0.0",
                    "experiment_manifest_version": "1.0.0",
                },
            ),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        prov_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-provenance"
        ]
        assert len(prov_violations) == 1
        assert "architecture_context_sha" in prov_violations[0]["message"]

    def test_nested_envelope_no_fallback_violation(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["index-md"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        self._write_nested_results(results_dir, [
            _make_result("index-md", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        nf_violations = [
            v for v in report["violations"] if v["type"] == "no-fallback"
        ]
        assert len(nf_violations) == 1

    def test_nested_envelope_provenance_in_entry(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _minimal_experiment()
        prov = {
            "architecture_context_sha": "sha256nested",
            "corpus_version": "1.0.0",
            "experiment_manifest_version": "1.0.0",
        }
        results_dir = tmp_path / "results"
        self._write_nested_results(results_dir, [
            _make_result("baseline", "FACT-001", provenance=prov),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        entry = report["entries"][0]
        assert entry["provenance"] == prov

    def test_load_results_nested_envelope(self, tmp_path):
        results_dir = tmp_path / "results"
        results_dir.mkdir()
        with open(results_dir / "raw-results.json", "w") as f:
            json.dump({
                "results": [
                    {"condition_id": "baseline", "question_id": "Q1"},
                    {"condition_id": "baseline", "question_id": "Q2"},
                ]
            }, f)
        loaded = _load_results(results_dir)
        assert "baseline" in loaded
        assert "Q1" in loaded["baseline"]
        assert "Q2" in loaded["baseline"]

    def test_load_results_flat_array_still_works(self, tmp_path):
        results_dir = tmp_path / "results"
        results_dir.mkdir()
        with open(results_dir / "baseline.json", "w") as f:
            json.dump([
                {"condition_id": "baseline", "question_id": "Q1"},
            ], f)
        loaded = _load_results(results_dir)
        assert "baseline" in loaded
        assert "Q1" in loaded["baseline"]

    def test_load_results_single_record_still_works(self, tmp_path):
        results_dir = tmp_path / "results"
        results_dir.mkdir()
        with open(results_dir / "baseline.json", "w") as f:
            json.dump(
                {"condition_id": "baseline", "question_id": "Q1"}, f
            )
        loaded = _load_results(results_dir)
        assert "baseline" in loaded
        assert "Q1" in loaded["baseline"]


# --- Context Telemetry Validation ---


class TestCheckContextTelemetryUnit:
    """Unit tests for _check_context_telemetry."""

    def test_valid_complete_record_no_issues(self):
        record = _make_result_with_telemetry("baseline", "FACT-001")
        assert _check_context_telemetry(record) == []

    def test_missing_context_provenance(self):
        record = _make_result_with_telemetry("baseline", "FACT-001")
        del record["context_provenance"]
        issues = _check_context_telemetry(record)
        assert len(issues) == 1
        assert "missing per-tree context_provenance" in issues[0]

    def test_empty_context_provenance(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001", context_provenance={},
        )
        issues = _check_context_telemetry(record)
        assert any("context_telemetry_version" in i for i in issues)

    def test_context_provenance_not_a_dict(self):
        record = _make_result_with_telemetry("baseline", "FACT-001")
        record["context_provenance"] = "not-a-dict"
        issues = _check_context_telemetry(record)
        assert any("missing per-tree context_provenance" in i for i in issues)

    def test_missing_telemetry_version_in_per_tree(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001",
            context_provenance={"context_events": []},
        )
        issues = _check_context_telemetry(record)
        assert any(
            "context_telemetry_version" in i and "per-tree" in i
            for i in issues
        )

    def test_empty_telemetry_version_in_per_tree(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001",
            context_provenance={
                "context_telemetry_version": "",
                "context_events": [],
            },
        )
        issues = _check_context_telemetry(record)
        assert any("context_telemetry_version" in i for i in issues)

    def test_non_string_telemetry_version_in_per_tree(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001",
            context_provenance={
                "context_telemetry_version": 1,
                "context_events": [],
            },
        )
        issues = _check_context_telemetry(record)
        assert any("context_telemetry_version" in i for i in issues)

    def test_missing_provenance_level_telemetry_version(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001",
            provenance={
                "architecture_context_sha": "abc123",
                "corpus_version": "1.0.0",
                "experiment_manifest_version": "1.0.0",
                "context_provenance": {
                    "context_telemetry_version": "1.0.0",
                    "events_attached_per_tree": True,
                },
            },
        )
        issues = _check_context_telemetry(record)
        assert any(
            "context_telemetry_version" in i and "provenance" in i
            for i in issues
        )

    def test_missing_condition_level_context_provenance(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001",
            provenance={
                "architecture_context_sha": "abc123",
                "corpus_version": "1.0.0",
                "experiment_manifest_version": "1.0.0",
                "context_telemetry_version": "1.0.0",
            },
        )
        issues = _check_context_telemetry(record)
        assert any(
            "condition-level context_provenance" in i for i in issues
        )

    def test_missing_events_attached_per_tree(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001",
            provenance={
                "architecture_context_sha": "abc123",
                "corpus_version": "1.0.0",
                "experiment_manifest_version": "1.0.0",
                "context_telemetry_version": "1.0.0",
                "context_provenance": {
                    "context_telemetry_version": "1.0.0",
                },
            },
        )
        issues = _check_context_telemetry(record)
        assert any("events_attached_per_tree" in i for i in issues)

    def test_events_attached_per_tree_false(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001",
            provenance={
                "architecture_context_sha": "abc123",
                "corpus_version": "1.0.0",
                "experiment_manifest_version": "1.0.0",
                "context_telemetry_version": "1.0.0",
                "context_provenance": {
                    "context_telemetry_version": "1.0.0",
                    "events_attached_per_tree": False,
                },
            },
        )
        issues = _check_context_telemetry(record)
        assert any("events_attached_per_tree" in i for i in issues)

    def test_missing_provenance_flags_envelope(self):
        record = {
            "condition_id": "baseline",
            "question_id": "FACT-001",
            "context_provenance": {
                "context_telemetry_version": CONTRACT_VERSION,
                "context_events": [],
            },
            "response": {"success": True},
        }
        issues = _check_context_telemetry(record)
        assert len(issues) == 1
        assert "missing provenance envelope" in issues[0]

    def test_wrong_version_in_per_tree(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001",
            context_provenance={
                "context_telemetry_version": "0.9.0",
                "context_events": [],
            },
        )
        issues = _check_context_telemetry(record)
        assert any(
            "does not match contract" in i and "per-tree" in i
            for i in issues
        )

    def test_wrong_version_in_provenance(self):
        record = _make_result_with_telemetry(
            "baseline", "FACT-001",
            provenance={
                "architecture_context_sha": "abc123",
                "corpus_version": "1.0.0",
                "experiment_manifest_version": "1.0.0",
                "context_telemetry_version": "99.0.0",
                "context_provenance": {
                    "context_telemetry_version": CONTRACT_VERSION,
                    "events_attached_per_tree": True,
                },
            },
        )
        issues = _check_context_telemetry(record)
        assert any(
            "does not match contract" in i and "provenance" in i
            for i in issues
        )


class TestContextTelemetryViolations:
    """Integration tests for missing-context-telemetry violations."""

    def test_valid_telemetry_no_violations(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _all_available_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result_with_telemetry("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        assert len(ctx_violations) == 0

    def test_missing_telemetry_produces_violation(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _all_available_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        assert len(ctx_violations) > 0
        assert all(v["condition_id"] == "baseline" for v in ctx_violations)
        assert all(v["question_id"] == "FACT-001" for v in ctx_violations)

    def test_all_four_conditions_valid(self, tmp_path):
        condition_ids = ["arch-query", "baseline", "combined", "index-md"]
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=condition_ids,
        )
        experiment = _all_available_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result_with_telemetry(cid, "FACT-001")
            for cid in condition_ids
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        assert len(ctx_violations) == 0

    def test_all_four_conditions_missing_telemetry(self, tmp_path):
        condition_ids = ["arch-query", "baseline", "combined", "index-md"]
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=condition_ids,
        )
        experiment = _all_available_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result(cid, "FACT-001") for cid in condition_ids
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        affected_conditions = {v["condition_id"] for v in ctx_violations}
        assert affected_conditions == set(condition_ids)

    def test_unavailable_condition_no_telemetry_check(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline", "index-md"],
        )
        experiment = _minimal_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        assert len(ctx_violations) >= 1
        assert all(v["condition_id"] == "baseline" for v in ctx_violations)
        assert not any(
            v["condition_id"] == "index-md" for v in ctx_violations
        )

    def test_no_results_no_telemetry_violations(self):
        canary = _minimal_canary()
        experiment = _all_available_experiment()
        report = generate_report(
            canary, experiment, results_dir=None,
            corpus_manifest_path=None,
        )
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        assert len(ctx_violations) == 0

    def test_malformed_per_tree_provenance(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _all_available_experiment()
        results_dir = tmp_path / "results"
        result = _make_result_with_telemetry("baseline", "FACT-001")
        result["context_provenance"] = "not-a-dict"
        _write_results(results_dir, [result])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        assert len(ctx_violations) >= 1
        assert any("per-tree" in v["message"] for v in ctx_violations)

    def test_violation_ordering_deterministic(self, tmp_path):
        condition_ids = ["arch-query", "baseline", "combined", "index-md"]
        canary = _minimal_canary(
            question_ids=["FACT-001", "INV-001"],
            condition_ids=condition_ids,
        )
        experiment = _all_available_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result(cid, qid)
            for cid in condition_ids
            for qid in ["FACT-001", "INV-001"]
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        keys = [
            (v["type"], v["condition_id"], v["question_id"])
            for v in ctx_violations
        ]
        assert keys == sorted(keys)

    def test_mixed_valid_and_invalid_telemetry(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline", "index-md"],
        )
        experiment = _all_available_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result_with_telemetry("baseline", "FACT-001"),
            _make_result("index-md", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        assert all(v["condition_id"] == "index-md" for v in ctx_violations)

    def test_existing_provenance_checks_preserved(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _all_available_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result(
                "baseline", "FACT-001",
                provenance={"corpus_version": "1.0.0"},
            ),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        prov_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-provenance"
        ]
        ctx_violations = [
            v for v in report["violations"]
            if v["type"] == "missing-context-telemetry"
        ]
        assert len(prov_violations) >= 1
        assert len(ctx_violations) >= 1

    def test_all_violations_sorted_globally(self, tmp_path):
        canary = _minimal_canary(
            question_ids=["FACT-001"],
            condition_ids=["baseline"],
        )
        experiment = _all_available_experiment()
        results_dir = tmp_path / "results"
        _write_results(results_dir, [
            _make_result("baseline", "FACT-001"),
        ])
        report = generate_report(
            canary, experiment, results_dir=results_dir,
            corpus_manifest_path=None,
        )
        violations = report["violations"]
        keys = [
            (v["type"], v.get("condition_id") or "", v.get("question_id") or "")
            for v in violations
        ]
        assert keys == sorted(keys)
