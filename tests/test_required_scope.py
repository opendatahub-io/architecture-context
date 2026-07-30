"""Tests for required_scope tagging in consumer-v1 corpus.

Covers: schema validation, corpus scope counts, validator acceptance,
score_results per-scope aggregates, and generate_report scope section.
"""

import importlib.util
import json
import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CONSUMER_V1_DIR = PROJECT_ROOT / "benchmark" / "consumer-v1"

sys.path.insert(0, str(PROJECT_ROOT))

_validate_path = CONSUMER_V1_DIR / "validate.py"
_validate_spec = importlib.util.spec_from_file_location("validate", _validate_path)
_validate_mod = importlib.util.module_from_spec(_validate_spec)
_validate_spec.loader.exec_module(_validate_mod)

validate_scopes = _validate_mod.validate_scopes
validate_fields = _validate_mod.validate_fields
VALID_SCOPES = _validate_mod.VALID_SCOPES

_score_path = CONSUMER_V1_DIR / "score_results.py"
_score_spec = importlib.util.spec_from_file_location("score_results", _score_path)
_score_mod = importlib.util.module_from_spec(_score_spec)
_score_spec.loader.exec_module(_score_mod)

score_response = _score_mod.score_response
compute_aggregates = _score_mod.compute_aggregates

_report_path = CONSUMER_V1_DIR / "generate_report.py"
_report_spec = importlib.util.spec_from_file_location("generate_report", _report_path)
_report_mod = importlib.util.module_from_spec(_report_spec)
_report_spec.loader.exec_module(_report_mod)

generate_report = _report_mod.generate_report


@pytest.fixture
def corpus():
    with open(CONSUMER_V1_DIR / "corpus.json") as f:
        return json.load(f)


@pytest.fixture
def schema():
    with open(CONSUMER_V1_DIR / "schema.json") as f:
        return json.load(f)


class TestSchemaRequiresScope:
    def test_required_scope_in_schema_required_fields(self, schema):
        required = schema["properties"]["questions"]["items"]["required"]
        assert "required_scope" in required

    def test_required_scope_enum_values(self, schema):
        props = schema["properties"]["questions"]["items"]["properties"]
        assert "required_scope" in props
        assert set(props["required_scope"]["enum"]) == {
            "architecture", "architecture+overlays", "full-repo"
        }


class TestCorpusScopeTags:
    def test_every_question_has_required_scope(self, corpus):
        for q in corpus["questions"]:
            assert "required_scope" in q, f"{q['id']}: missing required_scope"

    def test_all_scopes_are_valid(self, corpus):
        for q in corpus["questions"]:
            assert q["required_scope"] in VALID_SCOPES, (
                f"{q['id']}: invalid scope '{q['required_scope']}'"
            )

    def test_scope_counts(self, corpus):
        counts = {}
        for q in corpus["questions"]:
            s = q["required_scope"]
            counts[s] = counts.get(s, 0) + 1
        assert counts["architecture"] == 37
        assert counts.get("full-repo", 0) == 3
        assert counts.get("architecture+overlays", 0) == 0

    def test_full_repo_questions_have_docs_source(self, corpus):
        for q in corpus["questions"]:
            if q["required_scope"] == "full-repo":
                assert q["source_file"].startswith("docs/"), (
                    f"{q['id']}: full-repo scope but source_file "
                    f"is '{q['source_file']}'"
                )

    def test_architecture_questions_have_architecture_source(self, corpus):
        for q in corpus["questions"]:
            if q["required_scope"] == "architecture":
                assert q["source_file"].startswith("architecture/"), (
                    f"{q['id']}: architecture scope but source_file "
                    f"is '{q['source_file']}'"
                )

    def test_full_repo_ids(self, corpus):
        full_repo_ids = sorted(
            q["id"] for q in corpus["questions"]
            if q["required_scope"] == "full-repo"
        )
        assert full_repo_ids == ["INV-002", "INV-007", "NAV-004"]


class TestValidatorScopes:
    def test_valid_scopes_accepted(self):
        questions = [
            {"id": "INV-001", "required_scope": "architecture"},
            {"id": "INV-002", "required_scope": "full-repo"},
            {"id": "INV-003", "required_scope": "architecture+overlays"},
        ]
        assert validate_scopes(questions) == []

    def test_missing_scope_detected(self):
        questions = [{"id": "INV-001"}]
        errors = validate_scopes(questions)
        assert any("missing required_scope" in e for e in errors)

    def test_invalid_scope_detected(self):
        questions = [{"id": "INV-001", "required_scope": "bogus"}]
        errors = validate_scopes(questions)
        assert any("invalid required_scope 'bogus'" in e for e in errors)

    def test_required_scope_in_required_fields(self):
        questions = [{"id": "INV-001", "tier": 1, "consumer": "component-lookup",
                       "question": "test question", "expected_answer": "test answer",
                       "acceptable_variants": [], "source_file": "x",
                       "source_line": 1, "scope": "rhoai.next",
                       "not_documented_expected": False}]
        errors = validate_fields(questions)
        assert any("missing required field 'required_scope'" in e for e in errors)


def _make_scored_question(qid, tier, consumer, scope, passed_exact=True):
    scores = {
        "exact_match": {"passed": passed_exact},
        "source_citation": {"passed": True},
        "gap_acknowledgment": {"passed": True, "applicable": False},
        "checks_passed": 2 if passed_exact else 1,
        "checks_total": 2,
        "score": 1.0 if passed_exact else 0.5,
    }
    return {
        "question_id": qid,
        "tier": tier,
        "consumer": consumer,
        "required_scope": scope,
        "tree_a": {"success": True, "scores": scores},
    }


class TestScorerScopeAggregates:
    def test_by_scope_present_in_aggregates(self):
        questions = [
            _make_scored_question(
                "INV-001", 1, "component-lookup", "architecture",
            ),
            _make_scored_question(
                "INV-002", 1, "component-lookup", "full-repo",
                passed_exact=False,
            ),
            _make_scored_question(
                "FACT-001", 2, "architecture-review", "architecture",
            ),
        ]
        agg = compute_aggregates(questions, "tree_a")
        assert "by_scope" in agg
        assert "architecture" in agg["by_scope"]
        assert "full-repo" in agg["by_scope"]

    def test_scope_aggregate_counts(self):
        questions = [
            _make_scored_question("INV-001", 1, "component-lookup", "architecture"),
            _make_scored_question("INV-002", 1, "component-lookup", "full-repo"),
            _make_scored_question("FACT-001", 2, "architecture-review", "architecture"),
        ]
        agg = compute_aggregates(questions, "tree_a")
        assert agg["by_scope"]["architecture"]["count"] == 2
        assert agg["by_scope"]["full-repo"]["count"] == 1

    def test_scope_aggregate_scores(self):
        questions = [
            _make_scored_question(
                "INV-001", 1, "component-lookup", "architecture",
            ),
            _make_scored_question(
                "INV-002", 1, "component-lookup", "full-repo",
                passed_exact=False,
            ),
        ]
        agg = compute_aggregates(questions, "tree_a")
        assert agg["by_scope"]["architecture"]["exact_match_rate"] == 1.0
        assert agg["by_scope"]["full-repo"]["exact_match_rate"] == 0.0

    def test_primary_overall_uses_architecture_scope(self):
        questions = [
            _make_scored_question("INV-001", 1, "component-lookup", "architecture"),
            _make_scored_question(
                "INV-002", 1, "component-lookup", "full-repo",
                passed_exact=False,
            ),
        ]
        agg = compute_aggregates(questions, "tree_a")
        assert agg["primary_scope"] == "architecture"
        assert agg["primary_overall"]["count"] == 1
        assert agg["primary_overall"]["average_score"] == 1.0
        assert agg["overall"]["count"] == 2
        assert agg["overall"]["average_score"] == 0.75


class TestReportScopeSection:
    def test_report_contains_scope_section(self, tmp_path):
        scored = {
            "corpus_version": "1.0.0",
            "total_questions": 2,
            "aggregates": {
                "tree_a": {
                    "by_tier": {},
                    "by_consumer": {},
                    "by_scope": {
                        "architecture": {
                            "count": 1,
                            "exact_match_rate": 1.0,
                            "source_citation_rate": 1.0,
                            "gap_acknowledgment_rate": None,
                            "average_score": 1.0,
                        },
                        "full-repo": {
                            "count": 1,
                            "exact_match_rate": 0.5,
                            "source_citation_rate": 0.5,
                            "gap_acknowledgment_rate": None,
                            "average_score": 0.5,
                        },
                    },
                    "overall": {"count": 2, "exact_match_rate": 0.75,
                                "source_citation_rate": 0.75,
                                "gap_acknowledgment_rate": None,
                                "average_score": 0.75},
                },
                "tree_b": {
                    "by_tier": {},
                    "by_consumer": {},
                    "by_scope": {},
                    "overall": {"count": 0},
                },
            },
            "efficiency": {"tree_a": {}, "tree_b": {}},
            "results": [],
        }
        scored_path = tmp_path / "scored-results.json"
        scored_path.write_text(json.dumps(scored))
        report_path = tmp_path / "report.md"

        generate_report(scored_path, report_path)

        report = report_path.read_text()
        assert "## Primary Architecture Summary" in report
        assert "## All-Question Summary" in report
        assert "## Per-Scope Scores" in report
        assert "primary quality metric" in report
        assert "architecture" in report
        assert "full-repo" in report

    def test_non_primary_regression_is_diagnostic_not_flagged(self, tmp_path):
        non_primary_result = {
            "question_id": "NAV-004",
            "tier": 4,
            "consumer": "platform-navigator",
            "required_scope": "full-repo",
            "question": "Is there a components/ directory?",
            "tree_a": {
                "success": True,
                "scores": {
                    "exact_match": {"passed": True},
                    "source_citation": {"passed": True},
                    "gap_acknowledgment": {"passed": True, "applicable": False},
                    "score": 1.0,
                },
            },
            "tree_b": {
                "success": True,
                "scores": {
                    "exact_match": {"passed": False},
                    "source_citation": {"passed": True},
                    "gap_acknowledgment": {"passed": True, "applicable": False},
                    "score": 0.5,
                },
            },
        }
        scored = {
            "corpus_version": "1.0.0",
            "total_questions": 1,
            "aggregates": {
                "tree_a": {
                    "by_tier": {},
                    "by_consumer": {},
                    "by_scope": {},
                    "primary_overall": {"count": 0},
                    "overall": {"count": 1},
                },
                "tree_b": {
                    "by_tier": {},
                    "by_consumer": {},
                    "by_scope": {},
                    "primary_overall": {"count": 0},
                    "overall": {"count": 1},
                },
            },
            "efficiency": {"tree_a": {}, "tree_b": {}},
            "results": [non_primary_result],
        }
        scored_path = tmp_path / "scored-results.json"
        scored_path.write_text(json.dumps(scored))
        report_path = tmp_path / "report.md"

        generate_report(scored_path, report_path)

        report = report_path.read_text()
        flagged = report.split("## Non-Primary Regression Diagnostics")[0]
        diagnostics = report.split("## Non-Primary Regression Diagnostics")[1]
        assert "No regressions detected" in flagged
        assert "NAV-004" in diagnostics


class TestScopedRescore:
    """Validate the deterministic re-score artifact against the scoped corpus."""

    SCOPED_RESULTS = (
        PROJECT_ROOT
        / "benchmark"
        / "consumer-v1"
        / "results"
        / "v1-ab"
        / "scored-results-scoped.json"
    )
    SCOPED_REPORT = (
        PROJECT_ROOT
        / "benchmark"
        / "consumer-v1"
        / "results"
        / "v1-ab"
        / "report-scoped.md"
    )

    def test_scoped_results_artifact_exists(self):
        assert self.SCOPED_RESULTS.exists(), (
            "scored-results-scoped.json not found"
        )

    def test_scoped_report_artifact_exists(self):
        assert self.SCOPED_REPORT.exists(), "report-scoped.md not found"

    def test_scoped_results_total_questions(self):
        with open(self.SCOPED_RESULTS) as f:
            data = json.load(f)
        assert data["total_questions"] == 31

    def test_scoped_results_scope_counts(self):
        with open(self.SCOPED_RESULTS) as f:
            data = json.load(f)
        for tree in ("tree_a", "tree_b"):
            scopes = data["aggregates"][tree]["by_scope"]
            assert scopes["architecture"]["count"] == 28
            assert scopes["full-repo"]["count"] == 3

    def test_scoped_results_every_question_has_scope(self):
        with open(self.SCOPED_RESULTS) as f:
            data = json.load(f)
        for r in data["results"]:
            assert r["required_scope"] in VALID_SCOPES, (
                f"{r['question_id']}: missing or invalid scope"
            )

    def test_scoped_results_architecture_primary_metric(self):
        with open(self.SCOPED_RESULTS) as f:
            data = json.load(f)
        for tree in ("tree_a", "tree_b"):
            arch = data["aggregates"][tree]["by_scope"]["architecture"]
            assert "average_score" in arch
            assert 0.0 <= arch["average_score"] <= 1.0

    def test_scoped_report_contains_scope_section(self):
        report = self.SCOPED_REPORT.read_text()
        assert "## Per-Scope Scores" in report
        assert "primary quality metric" in report

    def test_historical_scored_results_unchanged(self):
        historical = (
            PROJECT_ROOT
            / "benchmark"
            / "consumer-v1"
            / "results"
            / "v1-ab"
            / "scored-results.json"
        )
        with open(historical) as f:
            data = json.load(f)
        assert data["total_questions"] == 40, (
            "historical scored-results.json was modified"
        )
