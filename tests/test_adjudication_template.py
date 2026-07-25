"""Tests for the failure-adjudication template and validator.

Covers:
  - Template structure and schema compliance
  - All human_category values are null
  - Proposal identity matches corpus membership
  - Deterministic ordering by question_id
  - No duplicate question_ids
  - Summary counts match actual data
  - Validator negative cases (non-null labels, broken identities)
  - Score context presence and structure
  - Proposed category consistency
"""

from __future__ import annotations

import json
import sys
from copy import deepcopy
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

TEMPLATE_PATH = (
    PROJECT_ROOT / "benchmark" / "consumer-v1" / "adjudication_template.json"
)
SCHEMA_PATH = (
    PROJECT_ROOT / "benchmark" / "consumer-v1" / "adjudication_schema.json"
)
CORPUS_PATH = PROJECT_ROOT / "benchmark" / "consumer-v1" / "corpus.json"
SCORED_PATH = (
    PROJECT_ROOT
    / "benchmark"
    / "consumer-v1"
    / "results"
    / "v1-ab"
    / "scored-results.json"
)


def _import_validate():
    """Import the validator from its file path."""
    import importlib.util

    validate_mod = (
        PROJECT_ROOT / "benchmark" / "consumer-v1" / "validate_adjudication.py"
    )
    spec = importlib.util.spec_from_file_location(
        "validate_adjudication", validate_mod,
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.validate


validate = _import_validate()


@pytest.fixture
def template():
    with open(TEMPLATE_PATH) as f:
        return json.load(f)


@pytest.fixture
def corpus():
    with open(CORPUS_PATH) as f:
        return json.load(f)


@pytest.fixture
def scored():
    with open(SCORED_PATH) as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Template structure
# ---------------------------------------------------------------------------


class TestTemplateStructure:
    def test_required_top_level_fields(self, template):
        required = [
            "schema_version", "template_version", "source_experiment",
            "source_artifact", "generated_at", "total_corpus_questions",
            "instructions", "valid_human_categories", "proposals", "summary",
        ]
        for field in required:
            assert field in template, f"Missing field: {field}"

    def test_schema_version(self, template):
        assert template["schema_version"] == "1.0.0"

    def test_template_version_is_semver(self, template):
        import re
        assert re.match(r"^\d+\.\d+\.\d+$", template["template_version"])

    def test_source_experiment_is_v1_ab(self, template):
        assert template["source_experiment"] == "v1-ab"

    def test_total_corpus_questions(self, template):
        assert template["total_corpus_questions"] == 40

    def test_instructions_non_empty(self, template):
        assert len(template["instructions"]) > 50

    def test_valid_human_categories_listed(self, template):
        cats = template["valid_human_categories"]
        assert "infrastructure-failure" in cats
        assert "stale-context" in cats
        assert "missing-context" in cats
        assert "retrieval-failure" in cats
        assert "scoring-defect" in cats
        assert "not-a-failure" in cats


# ---------------------------------------------------------------------------
# Human category null constraint
# ---------------------------------------------------------------------------


class TestHumanCategoryNull:
    def test_all_human_categories_are_null(self, template):
        for i, p in enumerate(template["proposals"]):
            assert p["human_category"] is None, (
                f"proposals[{i}] ({p['question_id']}): "
                f"human_category must be null, got {p['human_category']!r}"
            )

    def test_proposal_count_is_35(self, template):
        assert len(template["proposals"]) == 35


# ---------------------------------------------------------------------------
# Corpus membership
# ---------------------------------------------------------------------------


class TestCorpusMembership:
    def test_all_proposal_ids_exist_in_corpus(self, template, corpus):
        corpus_ids = {q["id"] for q in corpus["questions"]}
        for p in template["proposals"]:
            assert p["question_id"] in corpus_ids, (
                f"{p['question_id']} not in corpus"
            )

    def test_perfect_score_questions_excluded(self, template, scored):
        proposal_ids = {p["question_id"] for p in template["proposals"]}
        for r in scored["results"]:
            ta_score = r.get("tree_a", {}).get("scores", {}).get("score", 1.0)
            tb_score = r.get("tree_b", {}).get("scores", {}).get("score", 1.0)
            if ta_score >= 1.0 and tb_score >= 1.0:
                assert r["question_id"] not in proposal_ids, (
                    f"{r['question_id']} has perfect score but is in template"
                )
            else:
                assert r["question_id"] in proposal_ids, (
                    f"{r['question_id']} has imperfect score but is not in template"
                )


# ---------------------------------------------------------------------------
# Deterministic ordering
# ---------------------------------------------------------------------------


class TestDeterministicOrdering:
    def test_proposals_sorted_by_question_id(self, template):
        ids = [p["question_id"] for p in template["proposals"]]
        assert ids == sorted(ids)

    def test_no_duplicate_question_ids(self, template):
        ids = [p["question_id"] for p in template["proposals"]]
        assert len(ids) == len(set(ids))


# ---------------------------------------------------------------------------
# Result identity
# ---------------------------------------------------------------------------


class TestResultIdentity:
    def test_result_id_format(self, template):
        for p in template["proposals"]:
            assert p["result_id"] == f"v1-ab/{p['question_id']}"

    def test_result_id_contains_question_id(self, template):
        for p in template["proposals"]:
            assert p["question_id"] in p["result_id"]


# ---------------------------------------------------------------------------
# Score context
# ---------------------------------------------------------------------------


class TestScoreContext:
    def test_every_proposal_has_score_context(self, template):
        for p in template["proposals"]:
            sc = p["evidence"]["score_context"]
            assert "tree_a" in sc
            assert "tree_b" in sc

    def test_score_context_has_required_fields(self, template):
        required = [
            "score", "exact_match", "source_citation",
            "gap_acknowledgment", "checks_passed", "checks_total",
        ]
        for p in template["proposals"]:
            for tree in ["tree_a", "tree_b"]:
                sc = p["evidence"]["score_context"][tree]
                for field in required:
                    assert field in sc, (
                        f"{p['question_id']} {tree}: missing {field}"
                    )

    def test_at_least_one_tree_has_imperfect_score(self, template):
        for p in template["proposals"]:
            sc = p["evidence"]["score_context"]
            ta_score = sc["tree_a"]["score"]
            tb_score = sc["tree_b"]["score"]
            assert (
                (ta_score is not None and ta_score < 1.0)
                or (tb_score is not None and tb_score < 1.0)
            ), f"{p['question_id']}: both trees have perfect score"


# ---------------------------------------------------------------------------
# Proposed category consistency
# ---------------------------------------------------------------------------


class TestProposedCategory:
    def test_all_proposals_are_unresolved(self, template):
        for p in template["proposals"]:
            assert p["proposed_category"] == "unresolved"

    def test_all_suggested_actions_are_manual_classify(self, template):
        for p in template["proposals"]:
            assert p["suggested_action"] == "manual-classify"

    def test_all_signals_empty(self, template):
        for p in template["proposals"]:
            assert p["evidence"]["signals"] == []

    def test_all_recorded_classifications_empty(self, template):
        for p in template["proposals"]:
            assert p["evidence"]["recorded_classifications"] == []


# ---------------------------------------------------------------------------
# Summary counts
# ---------------------------------------------------------------------------


class TestSummaryCounts:
    def test_total_proposals_matches(self, template):
        assert template["summary"]["total_proposals"] == len(
            template["proposals"]
        )

    def test_perfect_score_count(self, template):
        expected = template["total_corpus_questions"] - len(
            template["proposals"]
        )
        assert template["summary"]["questions_with_perfect_score"] == expected

    def test_by_proposed_category_matches(self, template):
        actual: dict[str, int] = {}
        for p in template["proposals"]:
            cat = p["proposed_category"]
            actual[cat] = actual.get(cat, 0) + 1
        assert template["summary"]["by_proposed_category"] == actual

    def test_by_tier_matches(self, template):
        actual: dict[str, int] = {}
        for p in template["proposals"]:
            tier = str(p["tier"])
            actual[tier] = actual.get(tier, 0) + 1
        assert template["summary"]["by_tier"] == actual

    def test_unresolved_count_matches(self, template):
        actual = sum(
            1
            for p in template["proposals"]
            if p["proposed_category"] == "unresolved"
        )
        assert template["summary"]["unresolved_count"] == actual


# ---------------------------------------------------------------------------
# Validator positive case
# ---------------------------------------------------------------------------


class TestValidatorPositive:
    def test_template_passes_validator(self):
        errs = validate(TEMPLATE_PATH, corpus_path=CORPUS_PATH)
        assert errs == [], f"Validation errors: {errs}"

    def test_template_passes_validator_with_schema(self):
        try:
            import jsonschema  # noqa: F401
        except ImportError:
            pytest.skip("jsonschema not installed")
        errs = validate(
            TEMPLATE_PATH, corpus_path=CORPUS_PATH, schema_path=SCHEMA_PATH,
        )
        assert errs == [], f"Validation errors: {errs}"


# ---------------------------------------------------------------------------
# Validator negative cases
# ---------------------------------------------------------------------------


class TestValidatorNegative:
    def _write_and_validate(self, template, tmp_path):
        path = tmp_path / "adj.json"
        path.write_text(json.dumps(template))
        return validate(path)

    def test_non_null_human_category_rejected(self, template, tmp_path):
        t = deepcopy(template)
        t["proposals"][0]["human_category"] = "scoring-defect"
        errs = self._write_and_validate(t, tmp_path)
        assert any("human_category" in e for e in errs)

    def test_duplicate_question_id_rejected(self, template, tmp_path):
        t = deepcopy(template)
        t["proposals"].append(deepcopy(t["proposals"][0]))
        t["summary"]["total_proposals"] += 1
        errs = self._write_and_validate(t, tmp_path)
        assert any("duplicate" in e for e in errs)

    def test_unsorted_proposals_rejected(self, template, tmp_path):
        t = deepcopy(template)
        if len(t["proposals"]) >= 2:
            t["proposals"][0], t["proposals"][1] = (
                t["proposals"][1],
                t["proposals"][0],
            )
        errs = self._write_and_validate(t, tmp_path)
        assert any("not sorted" in e for e in errs)

    def test_wrong_total_proposals_rejected(self, template, tmp_path):
        t = deepcopy(template)
        t["summary"]["total_proposals"] = 999
        errs = self._write_and_validate(t, tmp_path)
        assert any("total_proposals" in e for e in errs)

    def test_wrong_perfect_score_count_rejected(self, template, tmp_path):
        t = deepcopy(template)
        t["summary"]["questions_with_perfect_score"] = 999
        errs = self._write_and_validate(t, tmp_path)
        assert any("questions_with_perfect_score" in e for e in errs)

    def test_wrong_by_category_rejected(self, template, tmp_path):
        t = deepcopy(template)
        t["summary"]["by_proposed_category"] = {"fake": 99}
        errs = self._write_and_validate(t, tmp_path)
        assert any("by_proposed_category" in e for e in errs)

    def test_wrong_by_tier_rejected(self, template, tmp_path):
        t = deepcopy(template)
        t["summary"]["by_tier"] = {"99": 1}
        errs = self._write_and_validate(t, tmp_path)
        assert any("by_tier" in e for e in errs)

    def test_wrong_unresolved_count_rejected(self, template, tmp_path):
        t = deepcopy(template)
        t["summary"]["unresolved_count"] = 999
        errs = self._write_and_validate(t, tmp_path)
        assert any("unresolved_count" in e for e in errs)

    def test_broken_result_id_rejected(self, template, tmp_path):
        t = deepcopy(template)
        t["proposals"][0]["result_id"] = "broken/WRONG-ID"
        errs = self._write_and_validate(t, tmp_path)
        assert any("result_id" in e for e in errs)

    def test_missing_question_id_rejected(self, template, tmp_path):
        t = deepcopy(template)
        del t["proposals"][0]["question_id"]
        errs = self._write_and_validate(t, tmp_path)
        assert any("question_id" in e for e in errs)

    def test_missing_evidence_rejected(self, template, tmp_path):
        t = deepcopy(template)
        del t["proposals"][0]["evidence"]
        errs = self._write_and_validate(t, tmp_path)
        assert any("evidence" in e for e in errs)

    def test_question_not_in_corpus_rejected(self, template, tmp_path):
        t = deepcopy(template)
        t["proposals"][0]["question_id"] = "FAKE-999"
        t["proposals"][0]["result_id"] = "v1-ab/FAKE-999"
        errs = validate(
            tmp_path / "adj.json",
            corpus_path=CORPUS_PATH,
        )
        path = tmp_path / "adj.json"
        path.write_text(json.dumps(t))
        errs = validate(path, corpus_path=CORPUS_PATH)
        assert any("FAKE-999" in e and "not found" in e for e in errs)

    def test_missing_file_rejected(self, tmp_path):
        errs = validate(tmp_path / "nonexistent.json")
        assert any("not found" in e for e in errs)

    def test_invalid_json_rejected(self, tmp_path):
        path = tmp_path / "bad.json"
        path.write_text("not json")
        errs = validate(path)
        assert len(errs) > 0


# ---------------------------------------------------------------------------
# Schema validation
# ---------------------------------------------------------------------------


class TestSchemaValidation:
    def test_template_validates_against_schema(self):
        try:
            import jsonschema
        except ImportError:
            pytest.skip("jsonschema not installed")

        with open(SCHEMA_PATH) as f:
            schema = json.load(f)
        with open(TEMPLATE_PATH) as f:
            template = json.load(f)
        jsonschema.validate(template, schema)
