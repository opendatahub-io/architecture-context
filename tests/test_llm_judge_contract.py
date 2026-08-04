"""Tests for the LLM-as-judge semantic evaluation contract/protocol.

Covers: schema validation, semantic match, mismatch, abstention, malformed
output, disagreement with deterministic scores, provenance, calibration-set
accounting, and explicit 90% acceptance calculation.

No model calls — all fixtures are deterministic offline data.
"""

import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "benchmark" / "consumer-v1"))

from validate_judge_result import (  # noqa: E402
    ACCEPTANCE_THRESHOLD,
    SCHEMA_VERSION,
    validate_judge_result,
)


def _base_judgment(
    qid, *, sem=True, conf=0.95, det=True, abstained=False, human_label=None
):
    """Build a single judgment entry."""
    j = {
        "question_id": qid,
        "semantic_match": None if abstained else sem,
        "confidence": None if abstained else conf,
        "rationale": (
            f"Abstained: insufficient context for {qid}"
            if abstained
            else f"Test rationale for {qid}"
        ),
        "abstained": abstained,
        "deterministic_match": det,
        "disagreement": (not abstained and sem != det),
        "human_label": human_label,
    }
    return j


def _valid_result(judgments=None, *, human_labeled_count=0, judge_agreed_count=0):
    """Build a structurally valid judge result."""
    if judgments is None:
        judgments = [
            _base_judgment("INV-001", sem=True, det=True, human_label=True),
            _base_judgment("INV-002", sem=True, det=False, human_label=True),
            _base_judgment("INV-003", sem=False, det=False),
        ]
        human_labeled_count = 2
        judge_agreed_count = 2

    sem_match = sum(
        1 for j in judgments if not j["abstained"] and j["semantic_match"] is True
    )
    sem_mismatch = sum(
        1 for j in judgments if not j["abstained"] and j["semantic_match"] is False
    )
    abstentions = sum(1 for j in judgments if j["abstained"])
    disagreements = sum(1 for j in judgments if j.get("disagreement"))

    rate = (
        round(judge_agreed_count / human_labeled_count, 4)
        if human_labeled_count > 0
        else None
    )

    return {
        "schema_version": SCHEMA_VERSION,
        "judge_model": {
            "model_id": "claude-sonnet-5",
            "model_version": "claude-sonnet-5-20260514",
        },
        "corpus_version": "1.0.0",
        "timestamp": "2026-07-25T12:00:00Z",
        "authorization": {
            "authorized_by": "offline-fixture",
            "authorized_question_count": len(judgments),
            "estimated_cost_usd": 0.0,
            "estimated_duration_seconds": 0.0,
            "calibration_set_path": "benchmark/consumer-v1/calibration/test-set.json",
        },
        "judgments": judgments,
        "calibration": {
            "human_labeled_count": human_labeled_count,
            "judge_agreed_count": judge_agreed_count,
            "agreement_rate": rate,
            "acceptance_threshold": ACCEPTANCE_THRESHOLD,
            "acceptance_met": rate is not None and rate >= ACCEPTANCE_THRESHOLD,
        },
        "summary": {
            "total_judged": len(judgments),
            "semantic_match_count": sem_match,
            "semantic_mismatch_count": sem_mismatch,
            "abstention_count": abstentions,
            "disagreement_count": disagreements,
        },
    }


class TestSchemaVersion:
    def test_valid_version_passes(self):
        result = _valid_result()
        assert validate_judge_result(result) == []

    def test_wrong_version_fails(self):
        result = _valid_result()
        result["schema_version"] = "0.0.1"
        errors = validate_judge_result(result)
        assert any("schema_version" in e for e in errors)

    def test_missing_version_fails(self):
        result = _valid_result()
        del result["schema_version"]
        errors = validate_judge_result(result)
        assert any("schema_version" in e for e in errors)


class TestSemanticMatch:
    """Verify that a clear semantic match passes validation."""

    def test_semantic_match_fixture(self):
        j = _base_judgment("INV-001", sem=True, conf=0.98, det=True)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert errors == []
        assert result["judgments"][0]["semantic_match"] is True
        assert result["judgments"][0]["disagreement"] is False

    def test_high_confidence_match(self):
        j = _base_judgment("FACT-001", sem=True, conf=1.0, det=True)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        assert validate_judge_result(result) == []

    def test_match_with_human_label_agreement(self):
        j = _base_judgment("INV-001", sem=True, conf=0.95, det=True, human_label=True)
        result = _valid_result([j], human_labeled_count=1, judge_agreed_count=1)
        assert validate_judge_result(result) == []
        assert result["calibration"]["acceptance_met"] is True


class TestSemanticMismatch:
    """Verify that a clear semantic mismatch passes validation."""

    def test_semantic_mismatch_fixture(self):
        j = _base_judgment("INV-001", sem=False, conf=0.92, det=False)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert errors == []
        assert result["judgments"][0]["semantic_match"] is False
        assert result["judgments"][0]["disagreement"] is False

    def test_mismatch_with_low_confidence(self):
        j = _base_judgment("INTG-001", sem=False, conf=0.55, det=False)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        assert validate_judge_result(result) == []


class TestAbstention:
    """Verify that abstention produces null semantic fields."""

    def test_abstention_fixture(self):
        j = _base_judgment("NAV-001", abstained=True, det=False)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert errors == []
        assert result["judgments"][0]["semantic_match"] is None
        assert result["judgments"][0]["confidence"] is None
        assert result["judgments"][0]["abstained"] is True

    def test_abstention_not_counted_as_match_or_mismatch(self):
        j = _base_judgment("NAV-002", abstained=True, det=True)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        assert result["summary"]["semantic_match_count"] == 0
        assert result["summary"]["semantic_mismatch_count"] == 0
        assert result["summary"]["abstention_count"] == 1

    def test_abstention_with_non_null_semantic_match_fails(self):
        j = _base_judgment("NAV-003", abstained=True, det=False)
        j["semantic_match"] = True
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        result["summary"]["abstention_count"] = 1
        result["summary"]["semantic_match_count"] = 0
        errors = validate_judge_result(result)
        assert any("semantic_match must be null when abstained" in e for e in errors)

    def test_abstention_with_non_null_confidence_fails(self):
        j = _base_judgment("NAV-004", abstained=True, det=False)
        j["confidence"] = 0.5
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        result["summary"]["abstention_count"] = 1
        errors = validate_judge_result(result)
        assert any("confidence must be null when abstained" in e for e in errors)

    def test_abstention_requires_rationale(self):
        j = _base_judgment("NAV-005", abstained=True, det=False)
        assert isinstance(j["rationale"], str) and len(j["rationale"]) > 0
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert errors == []


class TestMalformedOutput:
    """Verify that structurally invalid judge results are rejected."""

    def test_not_a_dict_fails(self):
        errors = validate_judge_result("not a dict")
        assert errors == ["Root must be a JSON object"]

    def test_missing_judge_model_fails(self):
        result = _valid_result()
        del result["judge_model"]
        errors = validate_judge_result(result)
        assert any("judge_model" in e for e in errors)

    def test_empty_model_id_fails(self):
        result = _valid_result()
        result["judge_model"]["model_id"] = ""
        errors = validate_judge_result(result)
        assert any("model_id must be non-empty" in e for e in errors)

    def test_empty_model_version_fails(self):
        result = _valid_result()
        result["judge_model"]["model_version"] = ""
        errors = validate_judge_result(result)
        assert any("model_version must be non-empty" in e for e in errors)

    def test_missing_authorization_fails(self):
        result = _valid_result()
        del result["authorization"]
        errors = validate_judge_result(result)
        assert any("authorization" in e for e in errors)

    def test_missing_authorization_fields_fails(self):
        result = _valid_result()
        result["authorization"] = {}
        errors = validate_judge_result(result)
        assert any("authorized_by" in e for e in errors)
        assert any("calibration_set_path" in e for e in errors)

    def test_negative_cost_fails(self):
        result = _valid_result()
        result["authorization"]["estimated_cost_usd"] = -1.0
        errors = validate_judge_result(result)
        assert any("estimated_cost_usd" in e for e in errors)

    def test_zero_authorized_question_count_fails(self):
        result = _valid_result()
        result["authorization"]["authorized_question_count"] = 0
        errors = validate_judge_result(result)
        assert any("authorized_question_count" in e for e in errors)

    def test_judgment_not_a_dict_fails(self):
        result = _valid_result()
        result["judgments"] = ["not a dict"]
        result["summary"]["total_judged"] = 1
        errors = validate_judge_result(result)
        assert any("must be an object" in e for e in errors)

    def test_missing_question_id_fails(self):
        j = _base_judgment("INV-001")
        del j["question_id"]
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert any("question_id" in e for e in errors)

    def test_duplicate_question_id_fails(self):
        j1 = _base_judgment("INV-001", sem=True, det=True)
        j2 = _base_judgment("INV-001", sem=False, det=False)
        result = _valid_result([j1, j2], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert any("duplicate" in e for e in errors)

    def test_confidence_out_of_range_fails(self):
        j = _base_judgment("INV-001", sem=True, conf=1.5, det=True)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert any("confidence must be in [0, 1]" in e for e in errors)

    def test_negative_confidence_fails(self):
        j = _base_judgment("INV-001", sem=True, conf=-0.1, det=True)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert any("confidence must be in [0, 1]" in e for e in errors)

    def test_non_boolean_semantic_match_when_not_abstained_fails(self):
        j = _base_judgment("INV-001", sem=True, det=True)
        j["semantic_match"] = "yes"
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        result["summary"]["semantic_match_count"] = 0
        errors = validate_judge_result(result)
        assert any("semantic_match must be boolean" in e for e in errors)

    def test_summary_count_mismatch_fails(self):
        j = _base_judgment("INV-001", sem=True, det=True)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        result["summary"]["semantic_match_count"] = 5
        errors = validate_judge_result(result)
        assert any("semantic_match_count" in e for e in errors)

    def test_missing_rationale_fails(self):
        j = _base_judgment("INV-001", sem=True, det=True)
        del j["rationale"]
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert any("rationale" in e for e in errors)

    def test_empty_rationale_fails(self):
        j = _base_judgment("INV-001", sem=True, det=True)
        j["rationale"] = ""
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert any("rationale must be a non-empty string" in e for e in errors)

    def test_null_rationale_fails(self):
        j = _base_judgment("INV-001", sem=True, det=True)
        j["rationale"] = None
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert any("rationale must be a non-empty string" in e for e in errors)

    def test_null_rationale_on_abstention_fails(self):
        j = _base_judgment("NAV-001", abstained=True, det=False)
        j["rationale"] = None
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert any("rationale must be a non-empty string" in e for e in errors)


class TestDisagreement:
    """Verify semantic vs deterministic disagreement detection."""

    def test_semantic_yes_deterministic_no_is_disagreement(self):
        j = _base_judgment("INV-001", sem=True, det=False)
        assert j["disagreement"] is True
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        assert validate_judge_result(result) == []
        assert result["summary"]["disagreement_count"] == 1

    def test_semantic_no_deterministic_yes_is_disagreement(self):
        j = _base_judgment("INV-002", sem=False, det=True)
        assert j["disagreement"] is True
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        assert validate_judge_result(result) == []
        assert result["summary"]["disagreement_count"] == 1

    def test_both_match_no_disagreement(self):
        j = _base_judgment("FACT-001", sem=True, det=True)
        assert j["disagreement"] is False
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        assert validate_judge_result(result) == []
        assert result["summary"]["disagreement_count"] == 0

    def test_both_mismatch_no_disagreement(self):
        j = _base_judgment("FACT-002", sem=False, det=False)
        assert j["disagreement"] is False

    def test_wrong_disagreement_flag_fails(self):
        j = _base_judgment("INV-001", sem=True, det=False)
        j["disagreement"] = False
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        result["summary"]["disagreement_count"] = 0
        errors = validate_judge_result(result)
        assert any("disagreement must be True" in e for e in errors)

    def test_wrong_agreement_flag_fails(self):
        j = _base_judgment("INV-001", sem=True, det=True)
        j["disagreement"] = True
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        result["summary"]["disagreement_count"] = 1
        errors = validate_judge_result(result)
        assert any("disagreement must be False" in e for e in errors)


class TestProvenance:
    """Verify judge model and authorization provenance requirements."""

    def test_valid_provenance_passes(self):
        result = _valid_result()
        errors = validate_judge_result(result)
        assert errors == []
        assert result["judge_model"]["model_id"] == "claude-sonnet-5"
        assert result["judge_model"]["model_version"] == "claude-sonnet-5-20260514"

    def test_authorization_fields_all_present(self):
        result = _valid_result()
        auth = result["authorization"]
        assert auth["authorized_by"] == "offline-fixture"
        assert auth["authorized_question_count"] == 3
        assert auth["estimated_cost_usd"] == 0.0
        assert auth["estimated_duration_seconds"] == 0.0
        assert auth["calibration_set_path"].endswith(".json")

    def test_corpus_version_present(self):
        result = _valid_result()
        assert result["corpus_version"] == "1.0.0"


class TestCalibrationSetAccounting:
    """Verify calibration set agreement accounting and human labels."""

    def test_calibration_with_full_agreement(self):
        judgments = [
            _base_judgment("INV-001", sem=True, det=True, human_label=True),
            _base_judgment("INV-002", sem=False, det=False, human_label=False),
            _base_judgment("INV-003", sem=True, det=True, human_label=True),
        ]
        result = _valid_result(judgments, human_labeled_count=3, judge_agreed_count=3)
        errors = validate_judge_result(result)
        assert errors == []
        assert result["calibration"]["agreement_rate"] == 1.0
        assert result["calibration"]["acceptance_met"] is True

    def test_calibration_with_partial_agreement(self):
        judgments = [
            _base_judgment("INV-001", sem=True, det=True, human_label=True),
            _base_judgment("INV-002", sem=True, det=False, human_label=False),
        ]
        result = _valid_result(judgments, human_labeled_count=2, judge_agreed_count=1)
        errors = validate_judge_result(result)
        assert errors == []
        assert result["calibration"]["agreement_rate"] == 0.5
        assert result["calibration"]["acceptance_met"] is False

    def test_no_human_labels_rate_is_null(self):
        judgments = [_base_judgment("INV-001", sem=True, det=True)]
        result = _valid_result(judgments, human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert errors == []
        assert result["calibration"]["agreement_rate"] is None
        assert result["calibration"]["acceptance_met"] is False

    def test_human_label_count_mismatch_fails(self):
        judgments = [
            _base_judgment("INV-001", sem=True, det=True, human_label=True),
        ]
        result = _valid_result(judgments, human_labeled_count=5, judge_agreed_count=3)
        errors = validate_judge_result(result)
        assert any("human_labeled_count" in e and "does not match" in e for e in errors)

    def test_agreed_exceeds_labeled_fails(self):
        judgments = [
            _base_judgment("INV-001", sem=True, det=True, human_label=True),
        ]
        result = _valid_result(judgments, human_labeled_count=1, judge_agreed_count=5)
        errors = validate_judge_result(result)
        assert any("cannot exceed" in e for e in errors)

    def test_wrong_agreement_rate_fails(self):
        judgments = [
            _base_judgment("INV-001", sem=True, det=True, human_label=True),
            _base_judgment("INV-002", sem=False, det=False, human_label=False),
        ]
        result = _valid_result(judgments, human_labeled_count=2, judge_agreed_count=1)
        result["calibration"]["agreement_rate"] = 0.9
        errors = validate_judge_result(result)
        assert any("agreement_rate" in e for e in errors)

    def test_non_null_rate_with_zero_labels_fails(self):
        judgments = [_base_judgment("INV-001", sem=True, det=True)]
        result = _valid_result(judgments, human_labeled_count=0, judge_agreed_count=0)
        result["calibration"]["agreement_rate"] = 0.5
        errors = validate_judge_result(result)
        assert any("agreement_rate must be null" in e for e in errors)


class TestAcceptanceCalculation:
    """Verify the explicit 90% acceptance threshold calculation."""

    def test_exactly_90_percent_passes(self):
        judgments = []
        for i in range(10):
            judgments.append(
                _base_judgment(
                    f"INV-{i + 1:03d}",
                    sem=True,
                    det=True,
                    human_label=True,
                )
            )
        result = _valid_result(judgments, human_labeled_count=10, judge_agreed_count=9)
        assert result["calibration"]["agreement_rate"] == 0.9
        assert result["calibration"]["acceptance_met"] is True

    def test_89_percent_fails_acceptance(self):
        judgments = []
        for i in range(100):
            judgments.append(
                _base_judgment(
                    (
                        f"INV-{i + 1:03d}"
                        if i < 10
                        else f"FACT-{i - 9:03d}"
                        if i < 20
                        else f"INTG-{i - 19:03d}"
                        if i < 30
                        else f"NAV-{i - 29:03d}"
                    ),
                    sem=True,
                    det=True,
                    human_label=True,
                )
            )
        result = _valid_result(
            judgments, human_labeled_count=100, judge_agreed_count=89
        )
        assert result["calibration"]["agreement_rate"] == 0.89
        assert result["calibration"]["acceptance_met"] is False

    def test_threshold_is_0_9(self):
        assert ACCEPTANCE_THRESHOLD == 0.9

    def test_wrong_acceptance_met_flag_fails(self):
        judgments = [
            _base_judgment("INV-001", sem=True, det=True, human_label=True),
            _base_judgment("INV-002", sem=True, det=True, human_label=True),
        ]
        result = _valid_result(judgments, human_labeled_count=2, judge_agreed_count=2)
        result["calibration"]["acceptance_met"] = False
        errors = validate_judge_result(result)
        assert any("acceptance_met must be True" in e for e in errors)

    def test_wrong_threshold_value_fails(self):
        result = _valid_result()
        result["calibration"]["acceptance_threshold"] = 0.8
        errors = validate_judge_result(result)
        assert any("acceptance_threshold" in e for e in errors)


class TestSchemaFileExists:
    """Verify the schema file is valid JSON."""

    def test_schema_file_loads(self):
        schema_path = (
            PROJECT_ROOT / "benchmark" / "consumer-v1" / "judge_result_schema.json"
        )
        assert schema_path.exists(), f"Schema file not found: {schema_path}"
        with open(schema_path) as f:
            schema = json.load(f)
        assert schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"
        assert schema["properties"]["schema_version"]["const"] == SCHEMA_VERSION

    def test_schema_version_matches_validator(self):
        schema_path = (
            PROJECT_ROOT / "benchmark" / "consumer-v1" / "judge_result_schema.json"
        )
        with open(schema_path) as f:
            schema = json.load(f)
        assert schema["properties"]["schema_version"]["const"] == SCHEMA_VERSION

    def test_schema_requires_authorization(self):
        schema_path = (
            PROJECT_ROOT / "benchmark" / "consumer-v1" / "judge_result_schema.json"
        )
        with open(schema_path) as f:
            schema = json.load(f)
        assert "authorization" in schema["required"]
        auth_props = schema["properties"]["authorization"]["properties"]
        assert "authorized_by" in auth_props
        assert "authorized_question_count" in auth_props
        assert "estimated_cost_usd" in auth_props
        assert "estimated_duration_seconds" in auth_props
        assert "calibration_set_path" in auth_props

    def test_schema_defines_judgment_with_abstention(self):
        schema_path = (
            PROJECT_ROOT / "benchmark" / "consumer-v1" / "judge_result_schema.json"
        )
        with open(schema_path) as f:
            schema = json.load(f)
        judgment_def = schema["$defs"]["judgment"]
        assert "abstained" in judgment_def["required"]
        assert "semantic_match" in judgment_def["required"]
        assert "confidence" in judgment_def["required"]
        assert "disagreement" in judgment_def["required"]

    def test_schema_requires_rationale_non_empty(self):
        schema_path = (
            PROJECT_ROOT / "benchmark" / "consumer-v1" / "judge_result_schema.json"
        )
        with open(schema_path) as f:
            schema = json.load(f)
        judgment_def = schema["$defs"]["judgment"]
        assert "rationale" in judgment_def["required"]
        rationale_prop = judgment_def["properties"]["rationale"]
        assert rationale_prop["type"] == "string"
        assert rationale_prop["minLength"] == 1


class TestDeterministicScoresPreserved:
    """Verify that judge results carry deterministic scores without modifying them."""

    def test_deterministic_match_field_is_readonly(self):
        j = _base_judgment("INV-001", sem=True, det=True)
        assert j["deterministic_match"] is True
        j2 = _base_judgment("INV-002", sem=True, det=False)
        assert j2["deterministic_match"] is False

    def test_judge_does_not_alter_deterministic_value(self):
        j = _base_judgment("INV-001", sem=True, det=False)
        result = _valid_result([j], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert errors == []
        assert result["judgments"][0]["deterministic_match"] is False
        assert result["judgments"][0]["semantic_match"] is True


class TestMixedJudgments:
    """Integration test with a mix of match, mismatch, abstention, and disagreement."""

    def test_mixed_result_validates(self):
        judgments = [
            _base_judgment("INV-001", sem=True, det=True, human_label=True),
            _base_judgment("INV-002", sem=True, det=False, human_label=True),
            _base_judgment("FACT-001", sem=False, det=False, human_label=False),
            _base_judgment("FACT-002", sem=False, det=True, human_label=None),
            _base_judgment("INTG-001", abstained=True, det=False),
        ]
        result = _valid_result(judgments, human_labeled_count=3, judge_agreed_count=3)
        errors = validate_judge_result(result)
        assert errors == [], f"Unexpected errors: {errors}"

        s = result["summary"]
        assert s["total_judged"] == 5
        assert s["semantic_match_count"] == 2
        assert s["semantic_mismatch_count"] == 2
        assert s["abstention_count"] == 1
        assert s["disagreement_count"] == 2

    def test_empty_judgments_requires_authorization_count(self):
        result = _valid_result([], human_labeled_count=0, judge_agreed_count=0)
        errors = validate_judge_result(result)
        assert any("authorized_question_count" in e for e in errors)
        assert result["summary"]["total_judged"] == 0


class TestFutureAuthorizationGate:
    """Document the required authorization fields for future execution."""

    def test_authorization_fields_required(self):
        required_fields = {
            "authorized_by",
            "authorized_question_count",
            "estimated_cost_usd",
            "estimated_duration_seconds",
            "calibration_set_path",
        }
        result = _valid_result()
        auth = result["authorization"]
        assert set(auth.keys()) == required_fields

    def test_offline_fixture_authorized_by(self):
        result = _valid_result()
        assert result["authorization"]["authorized_by"] == "offline-fixture"

    def test_offline_fixture_zero_cost(self):
        result = _valid_result()
        assert result["authorization"]["estimated_cost_usd"] == 0.0
