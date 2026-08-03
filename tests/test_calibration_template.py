"""Focused tests for the semantic-judge calibration set template.

Covers selection validity, corpus membership, null labels, deterministic
ordering, schema compliance, and validator negative cases.
"""

from __future__ import annotations

import copy
import json
from pathlib import Path

import pytest

CALIBRATION_PATH = Path("benchmark/consumer-v1/calibration_template.json")
CORPUS_PATH = Path("benchmark/consumer-v1/corpus.json")
SCHEMA_PATH = Path("benchmark/consumer-v1/calibration_schema.json")

# Import the validator
import sys
sys.path.insert(0, str(Path("benchmark/consumer-v1").resolve()))
from validate_calibration import validate_calibration_template


@pytest.fixture
def template():
    with open(CALIBRATION_PATH) as f:
        return json.load(f)


@pytest.fixture
def corpus():
    with open(CORPUS_PATH) as f:
        return json.load(f)


@pytest.fixture
def schema():
    with open(SCHEMA_PATH) as f:
        return json.load(f)


# --- File existence ---


class TestFilesExist:
    def test_template_file_exists(self):
        assert CALIBRATION_PATH.exists()

    def test_schema_file_exists(self):
        assert SCHEMA_PATH.exists()

    def test_validator_file_exists(self):
        assert Path("benchmark/consumer-v1/validate_calibration.py").exists()


# --- Template structure ---


class TestTemplateStructure:
    def test_template_version(self, template):
        assert template["template_version"] == "0.1.0"

    def test_corpus_version(self, template):
        assert template["corpus_version"] == "1.0.0"

    def test_judge_schema_version(self, template):
        assert template["judge_schema_version"] == "0.1.0"

    def test_has_selection_metadata(self, template):
        sel = template["selection"]
        assert sel["algorithm"]
        assert sel["description"]
        assert sel["rationale"]
        assert sel["deterministic"] is True

    def test_has_human_review_instructions(self, template):
        instr = template["human_review_instructions"]
        assert instr["task"]
        assert "true" in instr["label_values"]
        assert "false" in instr["label_values"]
        assert "null" in instr["label_values"]
        assert instr["gap_handling"]
        assert len(instr["notes"]) >= 1


# --- Selection validity ---


class TestSelectionValidity:
    def test_total_in_range(self, template):
        total = template["selection"]["total"]
        assert 20 <= total <= 30

    def test_question_count_matches_total(self, template):
        assert len(template["questions"]) == template["selection"]["total"]

    def test_all_tiers_represented(self, template):
        by_tier = template["selection"]["by_tier"]
        for t in ["1", "2", "3", "4"]:
            assert by_tier[t] >= 1, f"Tier {t} must have at least 1 question"

    def test_tier_counts_match_questions(self, template):
        by_tier = template["selection"]["by_tier"]
        actual = {1: 0, 2: 0, 3: 0, 4: 0}
        for q in template["questions"]:
            actual[q["tier"]] += 1
        for t in range(1, 5):
            assert actual[t] == by_tier[str(t)]

    def test_tier_sum_equals_total(self, template):
        by_tier = template["selection"]["by_tier"]
        assert sum(by_tier.values()) == template["selection"]["total"]

    def test_answerability_counts_match(self, template):
        by_ans = template["selection"]["by_answerability"]
        actual = {"answerable": 0, "answerable-as-gap": 0}
        for q in template["questions"]:
            actual[q["answerability"]] += 1
        assert actual["answerable"] == by_ans["answerable"]
        assert actual["answerable-as-gap"] == by_ans["answerable-as-gap"]

    def test_answerability_sum_equals_total(self, template):
        by_ans = template["selection"]["by_answerability"]
        assert by_ans["answerable"] + by_ans["answerable-as-gap"] == template["selection"]["total"]

    def test_gap_questions_included(self, template):
        assert template["selection"]["by_answerability"]["answerable-as-gap"] >= 1


# --- Corpus membership ---


class TestCorpusMembership:
    def test_all_ids_exist_in_corpus(self, template, corpus):
        corpus_ids = {q["id"] for q in corpus["questions"]}
        for q in template["questions"]:
            assert q["question_id"] in corpus_ids, f"{q['question_id']} not in corpus"

    def test_no_duplicate_ids(self, template):
        ids = [q["question_id"] for q in template["questions"]]
        assert len(ids) == len(set(ids))

    def test_question_text_matches_corpus(self, template, corpus):
        corpus_map = {q["id"]: q for q in corpus["questions"]}
        for q in template["questions"]:
            cq = corpus_map[q["question_id"]]
            assert q["question"] == cq["question"], f"{q['question_id']} question mismatch"

    def test_expected_answer_matches_corpus(self, template, corpus):
        corpus_map = {q["id"]: q for q in corpus["questions"]}
        for q in template["questions"]:
            cq = corpus_map[q["question_id"]]
            assert q["expected_answer"] == cq["expected_answer"], f"{q['question_id']} answer mismatch"

    def test_tier_matches_corpus(self, template, corpus):
        corpus_map = {q["id"]: q for q in corpus["questions"]}
        for q in template["questions"]:
            cq = corpus_map[q["question_id"]]
            assert q["tier"] == cq["tier"], f"{q['question_id']} tier mismatch"

    def test_source_file_matches_corpus(self, template, corpus):
        corpus_map = {q["id"]: q for q in corpus["questions"]}
        for q in template["questions"]:
            cq = corpus_map[q["question_id"]]
            assert q["source_file"] == cq["source_file"], f"{q['question_id']} source_file mismatch"

    def test_not_documented_matches_corpus(self, template, corpus):
        corpus_map = {q["id"]: q for q in corpus["questions"]}
        for q in template["questions"]:
            cq = corpus_map[q["question_id"]]
            assert q["not_documented_expected"] == cq["not_documented_expected"], \
                f"{q['question_id']} not_documented_expected mismatch"


# --- Null labels ---


class TestNullLabels:
    def test_all_labels_are_null(self, template):
        for q in template["questions"]:
            assert q["human_label"] is None, f"{q['question_id']} human_label must be null"


# --- Deterministic ordering ---


class TestDeterministicOrdering:
    def test_ordered_by_tier(self, template):
        tiers = [q["tier"] for q in template["questions"]]
        assert tiers == sorted(tiers), "Questions must be ordered by tier"

    def test_ordered_by_id_within_tier(self, template):
        prev_tier = 0
        prev_id = ""
        for q in template["questions"]:
            if q["tier"] == prev_tier:
                assert q["question_id"] > prev_id, \
                    f"{q['question_id']} not in ID order within tier {q['tier']}"
            prev_tier = q["tier"]
            prev_id = q["question_id"]


# --- Answerability consistency ---


class TestAnswerabilityConsistency:
    def test_gap_questions_have_not_documented_true(self, template):
        for q in template["questions"]:
            if q["answerability"] == "answerable-as-gap":
                assert q["not_documented_expected"] is True, \
                    f"{q['question_id']}: gap must have not_documented_expected=true"

    def test_answerable_questions_have_not_documented_false(self, template):
        for q in template["questions"]:
            if q["answerability"] == "answerable":
                assert q["not_documented_expected"] is False, \
                    f"{q['question_id']}: answerable must have not_documented_expected=false"


# --- Selection rationale ---


class TestSelectionRationale:
    def test_all_questions_have_rationale(self, template):
        for q in template["questions"]:
            assert q.get("selection_rationale"), f"{q['question_id']} missing rationale"


# --- Schema compliance ---


class TestSchemaCompliance:
    def test_schema_loads(self, schema):
        assert schema["$defs"]["calibration_question"]["required"]

    def test_schema_version_matches(self, schema, template):
        assert schema["properties"]["template_version"]["const"] == template["template_version"]

    def test_schema_requires_null_label(self, schema):
        label_schema = schema["$defs"]["calibration_question"]["properties"]["human_label"]
        assert label_schema["type"] == "null"

    def test_schema_total_range(self, schema):
        total_schema = schema["properties"]["selection"]["properties"]["total"]
        assert total_schema["minimum"] == 20
        assert total_schema["maximum"] == 30


# --- Validator positive ---


class TestValidatorPositive:
    def test_template_validates_without_corpus(self, template):
        errors = validate_calibration_template(template)
        assert errors == [], f"Validation errors: {errors}"

    def test_template_validates_with_corpus(self, template, corpus):
        errors = validate_calibration_template(template, corpus)
        assert errors == [], f"Validation errors: {errors}"


# --- Validator negative cases ---


class TestValidatorNegative:
    def test_wrong_version_fails(self, template):
        data = copy.deepcopy(template)
        data["template_version"] = "9.9.9"
        errors = validate_calibration_template(data)
        assert any("template_version" in e for e in errors)

    def test_non_null_label_fails(self, template, corpus):
        data = copy.deepcopy(template)
        data["questions"][0]["human_label"] = True
        errors = validate_calibration_template(data, corpus)
        assert any("human_label must be null" in e for e in errors)

    def test_duplicate_id_fails(self, template):
        data = copy.deepcopy(template)
        data["questions"][1]["question_id"] = data["questions"][0]["question_id"]
        errors = validate_calibration_template(data)
        assert any("duplicate" in e for e in errors)

    def test_missing_rationale_fails(self, template):
        data = copy.deepcopy(template)
        data["questions"][0]["selection_rationale"] = ""
        errors = validate_calibration_template(data)
        assert any("selection_rationale" in e for e in errors)

    def test_total_out_of_range_fails(self, template):
        data = copy.deepcopy(template)
        data["selection"]["total"] = 10
        errors = validate_calibration_template(data)
        assert any("20-30" in e for e in errors)

    def test_tier_count_mismatch_fails(self, template):
        data = copy.deepcopy(template)
        data["selection"]["by_tier"]["1"] = 99
        errors = validate_calibration_template(data)
        assert any("Tier 1" in e for e in errors)

    def test_answerability_mismatch_fails(self, template):
        data = copy.deepcopy(template)
        data["selection"]["by_answerability"]["answerable"] = 99
        errors = validate_calibration_template(data)
        assert any("does not match total" in e for e in errors)

    def test_non_deterministic_fails(self, template):
        data = copy.deepcopy(template)
        data["selection"]["deterministic"] = False
        errors = validate_calibration_template(data)
        assert any("deterministic" in e for e in errors)

    def test_invalid_answerability_fails(self, template):
        data = copy.deepcopy(template)
        data["questions"][0]["answerability"] = "unknown"
        errors = validate_calibration_template(data)
        assert any("answerability" in e for e in errors)

    def test_gap_without_not_documented_fails(self, template):
        data = copy.deepcopy(template)
        for q in data["questions"]:
            if q["answerability"] == "answerable-as-gap":
                q["not_documented_expected"] = False
                break
        errors = validate_calibration_template(data)
        assert any("not_documented_expected" in e for e in errors)

    def test_corpus_id_mismatch_fails(self, template, corpus):
        data = copy.deepcopy(template)
        data["questions"][0]["question_id"] = "FAKE-999"
        errors = validate_calibration_template(data, corpus)
        assert any("not found in corpus" in e for e in errors)

    def test_question_text_mismatch_fails(self, template, corpus):
        data = copy.deepcopy(template)
        data["questions"][0]["question"] = "Wrong question text?"
        errors = validate_calibration_template(data, corpus)
        assert any("question text does not match" in e for e in errors)

    def test_out_of_order_tier_fails(self, template):
        data = copy.deepcopy(template)
        q0 = data["questions"][0]
        q_last = data["questions"][-1]
        data["questions"][0] = q_last
        data["questions"][-1] = q0
        errors = validate_calibration_template(data)
        assert any("ordered by tier" in e for e in errors)

    def test_zero_gap_questions_fails(self, template):
        data = copy.deepcopy(template)
        data["selection"]["by_answerability"]["answerable-as-gap"] = 0
        errors = validate_calibration_template(data)
        assert any("answerable-as-gap" in e for e in errors)
