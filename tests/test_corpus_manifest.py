"""Tests for the analyzer-assisted corpus manifest and its validator.

Covers: duplicate IDs, invalid statuses, missing provenance, inconsistent
aggregates, unsupported baseline claims, the 29-question active fixture,
retired/missing/unverified entries, answerability status, source evidence,
consumer-v1 cross-reference, and negative controls.
"""

import importlib.util
import json
from copy import deepcopy
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent

_validate_path = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "validate_corpus.py"
)
_spec = importlib.util.spec_from_file_location(
    "validate_corpus", _validate_path
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

validate_ids = _mod.validate_ids
validate_statuses = _mod.validate_statuses
validate_provenance = _mod.validate_provenance
validate_answerability = _mod.validate_answerability
validate_aggregates = _mod.validate_aggregates
validate_baseline_scores = _mod.validate_baseline_scores
VALID_STATUSES = _mod.VALID_STATUSES
TIER_PREFIX_MAP = _mod.TIER_PREFIX_MAP
VALID_CATEGORIES = _mod.VALID_CATEGORIES
VALID_DIFFICULTIES = _mod.VALID_DIFFICULTIES
VALID_ANSWERABILITY = _mod.VALID_ANSWERABILITY


MANIFEST_PATH = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "corpus_manifest.json"
)
SCHEMA_PATH = (
    PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "corpus_schema.json"
)
CONSUMER_V1_CORPUS_PATH = (
    PROJECT_ROOT / "benchmark" / "consumer-v1" / "corpus.json"
)
V1_AB_RESULTS_PATH = (
    PROJECT_ROOT / "benchmark" / "consumer-v1"
    / "results" / "v1-ab" / "raw-results.json"
)


@pytest.fixture
def manifest():
    with open(MANIFEST_PATH) as f:
        return json.load(f)


@pytest.fixture
def consumer_v1_corpus():
    with open(CONSUMER_V1_CORPUS_PATH) as f:
        return json.load(f)


@pytest.fixture
def v1_ab_results():
    with open(V1_AB_RESULTS_PATH) as f:
        return json.load(f)


class TestManifestStructure:
    def test_manifest_loads(self, manifest):
        assert manifest["manifest_version"] == "1.1.0"
        assert manifest["corpus_id"] == "analyzer-assisted-v1"

    def test_required_top_level_keys(self, manifest):
        required = {
            "manifest_version", "corpus_id", "created", "description",
            "source_artifacts", "questions", "gaps", "aggregates",
        }
        assert required.issubset(manifest.keys())

    def test_schema_validates(self, manifest):
        schema = json.loads(SCHEMA_PATH.read_text())
        import jsonschema
        v = jsonschema.Draft202012Validator(schema)
        errors = list(v.iter_errors(manifest))
        assert errors == [], [e.message for e in errors]


class TestActiveQuestions:
    def test_active_count_is_36(self, manifest):
        active = [q for q in manifest["questions"] if q["status"] == "active"]
        assert len(active) == 36

    def test_active_ids_match_consumer_v1(self, manifest, consumer_v1_corpus):
        manifest_active_ids = sorted(
            q["id"] for q in manifest["questions"] if q["status"] == "active"
        )
        corpus_ids = sorted(q["id"] for q in consumer_v1_corpus["questions"])
        assert manifest_active_ids == corpus_ids

    def test_active_questions_have_known_difficulty(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "active":
                assert q["difficulty"] != "unknown", f"{q['id']} has unknown difficulty"

    def test_active_questions_have_known_scope(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "active":
                assert q["scope"] != "unknown", f"{q['id']} has unknown scope"

    def test_active_questions_source_is_consumer_v1(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "active":
                assert q["source_corpus"] == "consumer-v1", (
                    f"{q['id']} source is {q['source_corpus']}"
                )


class TestRetiredQuestions:
    def test_retired_count_is_4(self, manifest):
        retired = [q for q in manifest["questions"] if q["status"] == "retired"]
        assert len(retired) == 4

    def test_retired_ids_match_removed_from_v1_ab(
        self, manifest, consumer_v1_corpus, v1_ab_results
    ):
        manifest_retired_ids = sorted(
            q["id"] for q in manifest["questions"] if q["status"] == "retired"
        )
        v1_ab_ids = sorted(r["question_id"] for r in v1_ab_results["results"])
        corpus_ids = {q["id"] for q in consumer_v1_corpus["questions"]}
        expected_retired = sorted(set(v1_ab_ids) - corpus_ids)
        assert manifest_retired_ids == expected_retired

    def test_retired_have_retirement_reason(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "retired":
                assert q.get("retirement_reason"), (
                    f"{q['id']} is retired but has no retirement_reason"
                )

    def test_retired_have_source_provenance(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "retired":
                assert q.get("source_corpus"), (
                    f"{q['id']} is retired but has no source_corpus"
                )


class TestMissingAndUnverifiedEntries:
    def test_no_missing_status_entries(self, manifest):
        missing = [q for q in manifest["questions"] if q["status"] == "missing"]
        assert len(missing) == 0

    def test_no_unverified_status_entries(self, manifest):
        unverified = [q for q in manifest["questions"] if q["status"] == "unverified"]
        assert len(unverified) == 0


class TestAnswerabilityStatus:
    def test_all_active_have_answerability_status(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "active":
                assert "answerability_status" in q, (
                    f"{q['id']}: missing answerability_status"
                )
                assert q["answerability_status"] in ("answerable", "answerable-as-gap"), (
                    f"{q['id']}: invalid answerability_status '{q['answerability_status']}'"
                )

    def test_all_active_have_source_evidence(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "active":
                assert "source_evidence" in q, (
                    f"{q['id']}: missing source_evidence"
                )
                ev = q["source_evidence"]
                assert ev.get("source_file"), f"{q['id']}: empty source_file"
                assert ev.get("source_line") is not None, f"{q['id']}: missing source_line"
                assert "not_documented_expected" in ev, (
                    f"{q['id']}: missing not_documented_expected"
                )

    def test_answerable_as_gap_have_not_documented_true(self, manifest):
        gap_questions = [
            q for q in manifest["questions"]
            if q.get("answerability_status") == "answerable-as-gap"
        ]
        assert len(gap_questions) == 2
        for q in gap_questions:
            assert q["source_evidence"]["not_documented_expected"] is True, (
                f"{q['id']}: answerable-as-gap but not_documented_expected is not true"
            )

    def test_answerable_have_not_documented_false(self, manifest):
        for q in manifest["questions"]:
            if q.get("answerability_status") == "answerable":
                assert q["source_evidence"]["not_documented_expected"] is False, (
                    f"{q['id']}: answerable but not_documented_expected is not false"
                )

    def test_retired_have_undetermined_answerability(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "retired":
                assert q.get("answerability_status") == "undetermined", (
                    f"{q['id']}: retired but answerability_status is "
                    f"'{q.get('answerability_status')}'"
                )

    def test_retired_have_no_source_evidence(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "retired":
                assert "source_evidence" not in q, (
                    f"{q['id']}: retired question should not have source_evidence"
                )

    def test_answerability_aggregate_counts(self, manifest):
        ans_counts = {}
        for q in manifest["questions"]:
            a = q.get("answerability_status")
            ans_counts[a] = ans_counts.get(a, 0) + 1
        by_ans = manifest["aggregates"]["by_answerability_status"]
        assert by_ans["answerable"] == ans_counts.get("answerable", 0)
        assert by_ans["answerable-as-gap"] == ans_counts.get("answerable-as-gap", 0)
        assert by_ans["undetermined"] == ans_counts.get("undetermined", 0)

    def test_gap_question_ids(self, manifest):
        gap_ids = sorted(
            q["id"] for q in manifest["questions"]
            if q.get("answerability_status") == "answerable-as-gap"
        )
        assert gap_ids == ["FACT-008", "INV-006"]


class TestSourceEvidenceCrossReference:
    def test_source_evidence_matches_corpus(self, manifest, consumer_v1_corpus):
        corpus_by_id = {q["id"]: q for q in consumer_v1_corpus["questions"]}
        for q in manifest["questions"]:
            if q["status"] != "active":
                continue
            qid = q["id"]
            corpus_q = corpus_by_id[qid]
            ev = q["source_evidence"]
            assert ev["source_file"] == corpus_q["source_file"], (
                f"{qid}: source_file mismatch"
            )
            corpus_line = corpus_q["source_line"]
            if isinstance(corpus_line, int):
                assert ev["source_line"] == corpus_line, (
                    f"{qid}: source_line mismatch"
                )
            else:
                assert str(ev["source_line"]) == str(corpus_line), (
                    f"{qid}: source_line mismatch"
                )
            assert ev["not_documented_expected"] == corpus_q["not_documented_expected"], (
                f"{qid}: not_documented_expected mismatch"
            )


class TestValidatorDuplicateIDs:
    def test_no_duplicates_in_manifest(self, manifest):
        errors = validate_ids(manifest["questions"])
        assert errors == []

    def test_detects_duplicate_id(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "answerable",
             "source_evidence": {"source_file": "x", "source_line": 1, "not_documented_expected": False}},
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "answerable",
             "source_evidence": {"source_file": "x", "source_line": 1, "not_documented_expected": False}},
        ]
        errors = validate_ids(questions)
        assert any("Duplicate ID: INV-001" in e for e in errors)


class TestValidatorInvalidStatuses:
    def test_manifest_statuses_valid(self, manifest):
        errors = validate_statuses(manifest["questions"])
        assert errors == []

    def test_detects_invalid_status(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "bogus", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "undetermined"},
        ]
        errors = validate_statuses(questions)
        assert any("invalid status 'bogus'" in e for e in errors)

    def test_detects_retired_without_reason(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "retired", "category": "inventory",
             "difficulty": "unknown", "scope": "unknown", "source_corpus": "test",
             "answerability_status": "undetermined"},
        ]
        errors = validate_statuses(questions)
        assert any("missing retirement_reason" in e for e in errors)


class TestValidatorProvenance:
    def test_manifest_provenance_valid(self, manifest):
        errors = validate_provenance(manifest["questions"])
        assert errors == []

    def test_detects_missing_source_corpus(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "",
             "answerability_status": "answerable",
             "source_evidence": {"source_file": "x", "source_line": 1, "not_documented_expected": False}},
        ]
        errors = validate_provenance(questions)
        assert any("missing source_corpus" in e for e in errors)

    def test_detects_active_with_unknown_difficulty(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "unknown", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "answerable",
             "source_evidence": {"source_file": "x", "source_line": 1, "not_documented_expected": False}},
        ]
        errors = validate_provenance(questions)
        assert any("unknown difficulty" in e for e in errors)

    def test_detects_active_with_unknown_scope(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "unknown", "source_corpus": "test",
             "answerability_status": "answerable",
             "source_evidence": {"source_file": "x", "source_line": 1, "not_documented_expected": False}},
        ]
        errors = validate_provenance(questions)
        assert any("unknown scope" in e for e in errors)


class TestValidatorAnswerability:
    def test_manifest_answerability_valid(self, manifest):
        errors = validate_answerability(manifest["questions"])
        assert errors == []

    def test_detects_active_missing_answerability(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test"},
        ]
        errors = validate_answerability(questions)
        assert any("invalid answerability_status" in e for e in errors)

    def test_detects_active_missing_source_evidence(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "answerable"},
        ]
        errors = validate_answerability(questions)
        assert any("missing source_evidence" in e for e in errors)

    def test_detects_active_with_undetermined(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "undetermined",
             "source_evidence": {"source_file": "x", "source_line": 1, "not_documented_expected": False}},
        ]
        errors = validate_answerability(questions)
        assert any("must have answerability_status" in e for e in errors)

    def test_detects_invalid_answerability_value(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "bogus"},
        ]
        errors = validate_answerability(questions)
        assert any("invalid answerability_status 'bogus'" in e for e in errors)

    def test_detects_answerable_as_gap_with_nde_false(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "answerable-as-gap",
             "source_evidence": {"source_file": "x", "source_line": 1, "not_documented_expected": False}},
        ]
        errors = validate_answerability(questions)
        assert any("answerable-as-gap" in e and "not_documented_expected" in e for e in errors)

    def test_detects_answerable_with_nde_true(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "answerable",
             "source_evidence": {"source_file": "x", "source_line": 1, "not_documented_expected": True}},
        ]
        errors = validate_answerability(questions)
        assert any("answerable" in e and "not_documented_expected" in e for e in errors)

    def test_detects_retired_with_answerable(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "retired", "category": "inventory",
             "difficulty": "unknown", "scope": "unknown", "source_corpus": "test",
             "retirement_reason": "bad",
             "answerability_status": "answerable"},
        ]
        errors = validate_answerability(questions)
        assert any("retired question should have" in e for e in errors)

    def test_detects_missing_source_file_in_evidence(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "answerable",
             "source_evidence": {"source_file": "", "source_line": 1, "not_documented_expected": False}},
        ]
        errors = validate_answerability(questions)
        assert any("missing source_file" in e for e in errors)

    def test_detects_missing_source_line_in_evidence(self):
        questions = [
            {"id": "INV-001", "tier": 1, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "answerable",
             "source_evidence": {"source_file": "x", "source_line": None, "not_documented_expected": False}},
        ]
        errors = validate_answerability(questions)
        assert any("missing source_line" in e for e in errors)


class TestValidatorAggregates:
    def test_manifest_aggregates_consistent(self, manifest):
        errors = validate_aggregates(manifest)
        assert errors == []

    def test_detects_wrong_total_entries(self, manifest):
        bad = deepcopy(manifest)
        bad["aggregates"]["total_entries"] = 999
        errors = validate_aggregates(bad)
        assert any("total_entries" in e for e in errors)

    def test_detects_wrong_active_count(self, manifest):
        bad = deepcopy(manifest)
        bad["aggregates"]["total_active"] = 0
        errors = validate_aggregates(bad)
        assert any("total_active" in e for e in errors)

    def test_detects_wrong_retired_count(self, manifest):
        bad = deepcopy(manifest)
        bad["aggregates"]["total_retired"] = 0
        errors = validate_aggregates(bad)
        assert any("total_retired" in e for e in errors)

    def test_detects_wrong_status_breakdown(self, manifest):
        bad = deepcopy(manifest)
        bad["aggregates"]["by_status"]["active"] = 999
        errors = validate_aggregates(bad)
        assert any("by_status.active" in e for e in errors)

    def test_detects_wrong_tier_active(self, manifest):
        bad = deepcopy(manifest)
        bad["aggregates"]["by_tier"]["1"]["active"] = 999
        errors = validate_aggregates(bad)
        assert any("by_tier.1.active" in e for e in errors)

    def test_detects_wrong_answerability_count(self, manifest):
        bad = deepcopy(manifest)
        bad["aggregates"]["by_answerability_status"]["answerable"] = 999
        errors = validate_aggregates(bad)
        assert any("by_answerability_status.answerable" in e for e in errors)


class TestValidatorIDPrefixTier:
    def test_manifest_prefixes_match_tiers(self, manifest):
        errors = validate_ids(manifest["questions"])
        assert errors == []

    def test_detects_prefix_tier_mismatch(self):
        questions = [
            {"id": "INV-001", "tier": 3, "status": "active", "category": "inventory",
             "difficulty": "basic", "scope": "rhoai.next", "source_corpus": "test",
             "answerability_status": "answerable",
             "source_evidence": {"source_file": "x", "source_line": 1, "not_documented_expected": False}},
        ]
        errors = validate_ids(questions)
        assert any("implies tier 1 but tier is 3" in e for e in errors)


class TestGapAccounting:
    def test_plan_94q_gap_recorded(self, manifest):
        gap_ids = [g["gap_id"] for g in manifest["gaps"]]
        assert "plan-94-question-artifact" in gap_ids

    def test_plan_94q_marked_unverified(self, manifest):
        gap = next(
            g for g in manifest["gaps"]
            if g["gap_id"] == "plan-94-question-artifact"
        )
        assert gap["verification_status"] == "unverified"
        assert gap["claimed_total"] == 94
        assert gap["claimed_correct"] == 79

    def test_consumer_v1_below_minimum_gap_recorded(self, manifest):
        gap_ids = [g["gap_id"] for g in manifest["gaps"]]
        assert "consumer-v1-below-minimum" in gap_ids

    def test_missing_ids_in_gap_match_retired_ids(self, manifest):
        gap = next(
            g for g in manifest["gaps"]
            if g["gap_id"] == "consumer-v1-below-minimum"
        )
        retired_ids = sorted(
            q["id"] for q in manifest["questions"] if q["status"] == "retired"
        )
        assert sorted(gap["missing_ids"]) == retired_ids


class TestBaselineScores:
    def test_plan_claim_marked_unverified(self, manifest):
        scores = manifest.get("baseline_scores", {})
        plan = scores.get("plan_claim_94q", {})
        assert plan["verification_status"] == "unverified"
        assert plan["claimed_total"] == 94

    def test_v1_ab_evaluation_marked_evaluated(self, manifest):
        scores = manifest.get("baseline_scores", {})
        v1ab = scores.get("v1_ab_evaluation", {})
        assert v1ab["verification_status"] == "evaluated"
        assert v1ab["questions_evaluated"] == 40


class TestConsumerV1Compatibility:
    """Ensure consumer-v1 files are not modified."""

    def test_consumer_v1_corpus_has_36_questions(self, consumer_v1_corpus):
        assert len(consumer_v1_corpus["questions"]) == 36

    def test_consumer_v1_corpus_version_unchanged(self, consumer_v1_corpus):
        assert consumer_v1_corpus["corpus_version"] == "1.0.0"

    def test_v1_ab_results_has_40_entries(self, v1_ab_results):
        assert len(v1_ab_results["results"]) == 40

    def test_consumer_v1_schema_requires_40_questions(self):
        schema = json.loads(
            (PROJECT_ROOT / "benchmark" / "consumer-v1" / "schema.json").read_text()
        )
        min_items = schema["properties"]["questions"]["minItems"]
        assert min_items == 40


class TestTotalCoverage:
    def test_total_entries_is_40(self, manifest):
        assert len(manifest["questions"]) == 40

    def test_all_v1_ab_ids_accounted(self, manifest, v1_ab_results):
        manifest_ids = {q["id"] for q in manifest["questions"]}
        v1_ab_ids = {r["question_id"] for r in v1_ab_results["results"]}
        assert v1_ab_ids.issubset(manifest_ids)

    def test_no_ids_outside_v1_ab(self, manifest, v1_ab_results):
        manifest_ids = {q["id"] for q in manifest["questions"]}
        v1_ab_ids = {r["question_id"] for r in v1_ab_results["results"]}
        assert manifest_ids == v1_ab_ids


class TestNegativeControls:
    def test_no_fabricated_questions_beyond_v1_ab(self, manifest, v1_ab_results):
        manifest_ids = {q["id"] for q in manifest["questions"]}
        v1_ab_ids = {r["question_id"] for r in v1_ab_results["results"]}
        extra = manifest_ids - v1_ab_ids
        assert extra == set(), f"Fabricated IDs found: {extra}"

    def test_retired_not_counted_as_incorrect(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "retired":
                reason = q.get("retirement_reason", "").lower()
                ok = (
                    "incorrect answer" not in reason
                    or "source reference" in reason
                )
                assert ok, (
                    f"{q['id']}: retirement reason should "
                    "not treat missing as incorrect"
                )

    def test_plan_94q_not_promoted_to_verified(self, manifest):
        scores = manifest.get("baseline_scores", {})
        plan = scores.get("plan_claim_94q", {})
        assert plan["verification_status"] != "verified"

    def test_no_active_question_missing_answerability(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "active":
                assert "answerability_status" in q, (
                    f"{q['id']}: active question lacks answerability_status"
                )

    def test_no_active_question_missing_source_evidence(self, manifest):
        for q in manifest["questions"]:
            if q["status"] == "active":
                assert "source_evidence" in q, (
                    f"{q['id']}: active question lacks source_evidence"
                )

    def test_no_fabricated_source_evidence(self, manifest, consumer_v1_corpus):
        corpus_files = {q["source_file"] for q in consumer_v1_corpus["questions"]}
        for q in manifest["questions"]:
            if q["status"] == "active":
                ev = q["source_evidence"]
                assert ev["source_file"] in corpus_files, (
                    f"{q['id']}: source_file '{ev['source_file']}' "
                    f"not found in consumer-v1 corpus"
                )
