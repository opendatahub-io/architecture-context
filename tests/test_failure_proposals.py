"""Tests for lib.failure_proposals — deterministic proposal generation.

Covers:
  - Deterministic output for identical inputs
  - Evidence and reasoning presence in every proposal
  - Malformed input rejection
  - Negative controls: ambiguous failures stay unresolved
  - Direct signal classification (infrastructure, stale, missing, unsupported)
  - Recorded classifications preserved as annotations
  - Schema validation of output
"""

from __future__ import annotations

import json
import sys
from copy import deepcopy
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from lib.failure_proposals import (  # noqa: E402
    _EPOCH_FALLBACK,
    GENERATOR_VERSION,
    PROPOSAL_SCHEMA_VERSION,
    generate_proposal,
    generate_proposals,
)


def _minimal_result(
    *,
    question_id: str = "INV-001",
    condition_id: str = "baseline",
    success: bool = True,
    error: str | None = None,
    failure_classifications: list[str] | None = None,
    context_metrics: dict | None = None,
    context_provenance: dict | None = None,
) -> dict:
    """Build a minimal valid result record for testing."""
    result: dict = {
        "question_id": question_id,
        "condition_id": condition_id,
        "response": {
            "success": success,
            "text": "Some answer" if success else None,
            "error": error,
        },
    }
    if failure_classifications is not None:
        result["failure_classifications"] = failure_classifications
    if context_metrics is not None:
        result["context_metrics"] = context_metrics
    if context_provenance is not None:
        result["context_provenance"] = context_provenance
    return result


# ---------------------------------------------------------------------------
# Deterministic output
# ---------------------------------------------------------------------------


class TestDeterministicOutput:
    def test_identical_inputs_produce_identical_proposals(self):
        r1 = _minimal_result(success=False, error="timeout")
        r2 = deepcopy(r1)
        p1 = generate_proposal(r1)
        p2 = generate_proposal(r2)
        assert p1 == p2

    def test_batch_output_deterministic(self):
        results = [
            _minimal_result(question_id="INV-001", success=False),
            _minimal_result(question_id="INV-002"),
        ]
        ts = "2026-07-25T00:00:00+00:00"
        o1 = generate_proposals(deepcopy(results), experiment_id="test", timestamp=ts)
        o2 = generate_proposals(deepcopy(results), experiment_id="test", timestamp=ts)
        assert json.dumps(o1, sort_keys=True) == json.dumps(o2, sort_keys=True)

    def test_proposal_result_id_is_condition_slash_question(self):
        r = _minimal_result(question_id="FACT-003", condition_id="arch-query")
        p = generate_proposal(r)
        assert p.result_id == "arch-query/FACT-003"

    def test_default_timestamp_deterministic_without_input_timestamps(self):
        """Regression: repeated calls without explicit timestamp must produce
        identical output — no wall-clock dependency (datetime.now)."""
        results = [_minimal_result(question_id="INV-001")]
        o1 = generate_proposals(deepcopy(results), experiment_id="det")
        o2 = generate_proposals(deepcopy(results), experiment_id="det")
        assert o1["generated_at"] == o2["generated_at"]
        assert o1["generated_at"] == _EPOCH_FALLBACK
        assert json.dumps(o1, sort_keys=True) == json.dumps(o2, sort_keys=True)

    def test_default_timestamp_derived_from_input_timestamps(self):
        """When results carry timestamps, generated_at uses the latest."""
        results = [
            {
                **_minimal_result(question_id="INV-001"),
                "timestamp": "2026-07-20T10:00:00+00:00",
            },
            {
                **_minimal_result(question_id="INV-002"),
                "timestamp": "2026-07-25T12:00:00+00:00",
            },
        ]
        o1 = generate_proposals(deepcopy(results), experiment_id="ts")
        o2 = generate_proposals(deepcopy(results), experiment_id="ts")
        assert o1["generated_at"] == "2026-07-25T12:00:00+00:00"
        assert o1["generated_at"] == o2["generated_at"]

    def test_explicit_timestamp_overrides_derivation(self):
        """Explicit timestamp kwarg always wins."""
        results = [
            {**_minimal_result(), "timestamp": "2026-07-20T10:00:00+00:00"},
        ]
        output = generate_proposals(
            results,
            timestamp="2026-01-01T00:00:00+00:00",
        )
        assert output["generated_at"] == "2026-01-01T00:00:00+00:00"


# ---------------------------------------------------------------------------
# Evidence and reasoning
# ---------------------------------------------------------------------------


class TestEvidenceAndReasoning:
    def test_every_proposal_has_evidence_and_reasoning(self):
        results = [
            _minimal_result(success=False, error="crash"),
            _minimal_result(context_metrics={"stale_context_detected": True}),
            _minimal_result(),
        ]
        for r in results:
            p = generate_proposal(r)
            assert p.evidence is not None
            assert "signals" in p.evidence
            assert isinstance(p.evidence["signals"], list)
            assert isinstance(p.reasoning, str)
            assert len(p.reasoning) > 0

    def test_infrastructure_failure_evidence_includes_response_signals(self):
        r = _minimal_result(success=False, error="agent session timeout")
        p = generate_proposal(r)
        sources = [s["source"] for s in p.evidence["signals"]]
        assert "response.success" in sources
        assert "response.error" in sources

    def test_stale_context_evidence_from_metrics(self):
        r = _minimal_result(
            context_metrics={
                "stale_context_detected": True,
                "missing_context_detected": None,
                "unsupported_inference_detected": None,
            }
        )
        p = generate_proposal(r)
        assert p.proposed_category == "stale-context"
        sources = [s["source"] for s in p.evidence["signals"]]
        assert "context_metrics.stale_context_detected" in sources

    def test_stale_context_evidence_from_events(self):
        r = _minimal_result(
            context_provenance={
                "context_telemetry_version": "1.0.0",
                "context_events": {
                    "contract_version": "1.0.0",
                    "events": [
                        {
                            "kind": "signal.stale_context",
                            "detail": "version outdated",
                            "file": None,
                            "component": None,
                            "route": None,
                        }
                    ],
                    "context_metrics": {},
                },
            }
        )
        p = generate_proposal(r)
        assert p.proposed_category == "stale-context"
        sources = [s["source"] for s in p.evidence["signals"]]
        assert "context_events" in sources

    def test_missing_context_evidence(self):
        r = _minimal_result(
            context_metrics={
                "missing_context_detected": True,
                "stale_context_detected": None,
                "unsupported_inference_detected": None,
            }
        )
        p = generate_proposal(r)
        assert p.proposed_category == "missing-context"

    def test_unsupported_inference_evidence(self):
        r = _minimal_result(
            context_metrics={
                "unsupported_inference_detected": True,
                "stale_context_detected": None,
                "missing_context_detected": None,
            }
        )
        p = generate_proposal(r)
        assert p.proposed_category == "unsupported-inference"

    def test_missing_context_from_context_events_only(self):
        """Regression: signal.missing_context in context events must classify
        as missing-context from direct evidence, without a context_metrics flag.
        """
        r = _minimal_result(
            context_provenance={
                "context_telemetry_version": "1.0.0",
                "context_events": {
                    "contract_version": "1.0.0",
                    "events": [
                        {
                            "kind": "signal.missing_context",
                            "detail": "no deployment architecture found",
                            "file": None,
                            "component": "dashboard",
                            "route": None,
                        },
                    ],
                    "context_metrics": {},
                },
            }
        )
        p = generate_proposal(r)
        assert p.proposed_category == "missing-context"
        sources = [s["source"] for s in p.evidence["signals"]]
        assert "context_events" in sources
        signal = next(
            s for s in p.evidence["signals"] if s["source"] == "context_events"
        )
        assert signal["value"] == "signal.missing_context"
        assert signal["detail"] == "no deployment architecture found"

    def test_unsupported_inference_from_context_events_only(self):
        """Regression: signal.unsupported_inference in
        context_provenance.context_events.events must classify as
        unsupported-inference from direct evidence alone."""
        r = _minimal_result(
            context_provenance={
                "context_telemetry_version": "1.0.0",
                "context_events": {
                    "contract_version": "1.0.0",
                    "events": [
                        {
                            "kind": "signal.unsupported_inference",
                            "detail": "inferred HA from single-replica manifest",
                            "file": None,
                            "component": None,
                            "route": None,
                        },
                    ],
                    "context_metrics": {},
                },
            }
        )
        p = generate_proposal(r)
        assert p.proposed_category == "unsupported-inference"
        sources = [s["source"] for s in p.evidence["signals"]]
        assert "context_events" in sources
        signal = next(
            s for s in p.evidence["signals"] if s["source"] == "context_events"
        )
        assert signal["value"] == "signal.unsupported_inference"
        assert signal["detail"] == "inferred HA from single-replica manifest"

    def test_recorded_classifications_preserved_as_annotations(self):
        r = _minimal_result(
            failure_classifications=["retrieval-failure", "scoring-defect"],
        )
        p = generate_proposal(r)
        assert p.evidence["recorded_classifications"] == [
            "retrieval-failure",
            "scoring-defect",
        ]


# ---------------------------------------------------------------------------
# Review status
# ---------------------------------------------------------------------------


class TestReviewStatus:
    def test_review_status_always_pending(self):
        for success in (True, False):
            r = _minimal_result(success=success)
            p = generate_proposal(r)
            assert p.review_status == "pending"

    def test_batch_proposals_all_pending(self):
        results = [_minimal_result(question_id=f"INV-{i:03d}") for i in range(5)]
        output = generate_proposals(results, timestamp="2026-07-25T00:00:00+00:00")
        for p in output["proposals"]:
            assert p["review_status"] == "pending"


# ---------------------------------------------------------------------------
# Suggested action
# ---------------------------------------------------------------------------


class TestSuggestedAction:
    def test_infrastructure_failure_suggests_accept(self):
        r = _minimal_result(success=False)
        p = generate_proposal(r)
        assert p.suggested_action == "accept"

    def test_telemetry_signal_suggests_investigate(self):
        for metric, cat in [
            ("stale_context_detected", "stale-context"),
            ("missing_context_detected", "missing-context"),
            ("unsupported_inference_detected", "unsupported-inference"),
        ]:
            r = _minimal_result(context_metrics={metric: True})
            p = generate_proposal(r)
            assert p.suggested_action == "investigate"

    def test_unresolved_suggests_manual_classify(self):
        r = _minimal_result()
        p = generate_proposal(r)
        assert p.suggested_action == "manual-classify"


# ---------------------------------------------------------------------------
# Malformed input rejection
# ---------------------------------------------------------------------------


class TestMalformedInputRejection:
    def test_missing_question_id_raises(self):
        r = {"condition_id": "baseline", "response": {"success": True}}
        with pytest.raises(ValueError, match="question_id"):
            generate_proposal(r)

    def test_missing_condition_id_raises(self):
        r = {"question_id": "INV-001", "response": {"success": True}}
        with pytest.raises(ValueError, match="condition_id"):
            generate_proposal(r)

    def test_unknown_condition_id_raises(self):
        r = _minimal_result(condition_id="unknown-condition")
        with pytest.raises(ValueError, match="Unknown condition_id"):
            generate_proposal(r)

    def test_missing_response_raises(self):
        r = {"question_id": "INV-001", "condition_id": "baseline"}
        with pytest.raises(ValueError, match="response"):
            generate_proposal(r)

    def test_non_dict_input_raises(self):
        with pytest.raises(ValueError, match="not a dict"):
            generate_proposal("not a dict")  # type: ignore[arg-type]

    def test_batch_non_list_raises(self):
        with pytest.raises(ValueError, match="must be a list"):
            generate_proposals("not a list")  # type: ignore[arg-type]

    def test_batch_propagates_individual_validation_errors(self):
        results = [
            _minimal_result(),
            {"invalid": True},
        ]
        with pytest.raises(ValueError):
            generate_proposals(results)


# ---------------------------------------------------------------------------
# Negative controls: no retrieval/scoring over-inference
# ---------------------------------------------------------------------------


class TestNegativeControls:
    """Verify that ambiguous failures remain unresolved rather than being
    classified as retrieval-failure or scoring-defect from score alone."""

    def test_successful_response_without_signals_is_unresolved(self):
        r = _minimal_result(success=True)
        p = generate_proposal(r)
        assert p.proposed_category == "unresolved"
        assert "retrieval" not in p.proposed_category
        assert "scoring" not in p.proposed_category

    def test_no_retrieval_failure_from_empty_telemetry(self):
        r = _minimal_result(
            context_metrics={
                "context_fetches": 0,
                "useful_reads": 0,
                "navigation_reads": 0,
                "queries_issued": 0,
                "missing_context_detected": None,
                "stale_context_detected": None,
                "unsupported_inference_detected": None,
            },
        )
        p = generate_proposal(r)
        assert p.proposed_category == "unresolved"
        assert p.proposed_category != "retrieval-failure"

    def test_no_scoring_defect_from_existing_classification(self):
        """Even if the input record has scoring-defect in failure_classifications,
        the proposal must not infer scoring-defect — it preserves it as annotation."""
        r = _minimal_result(failure_classifications=["scoring-defect"])
        p = generate_proposal(r)
        assert p.proposed_category == "unresolved"
        assert "scoring-defect" in p.evidence["recorded_classifications"]

    def test_no_retrieval_failure_from_low_useful_reads(self):
        """Low useful_reads alone does not imply retrieval failure."""
        r = _minimal_result(
            context_metrics={
                "context_fetches": 10,
                "useful_reads": 1,
                "navigation_reads": 9,
                "queries_issued": 0,
                "missing_context_detected": None,
                "stale_context_detected": None,
                "unsupported_inference_detected": None,
            },
        )
        p = generate_proposal(r)
        assert p.proposed_category == "unresolved"

    def test_no_infrastructure_from_null_error(self):
        """response.error=null with success=true should not trigger infrastructure."""
        r = _minimal_result(success=True, error=None)
        p = generate_proposal(r)
        assert p.proposed_category != "infrastructure-failure"

    def test_unresolved_reasoning_mentions_ambiguity(self):
        r = _minimal_result()
        p = generate_proposal(r)
        assert (
            "cannot be determined" in p.reasoning or "No direct signal" in p.reasoning
        )

    def test_multiple_conditions_same_question_independent(self):
        """Each condition/question pair generates independently."""
        r_base = _minimal_result(condition_id="baseline", success=False)
        r_index = _minimal_result(condition_id="index-md", success=True)
        p_base = generate_proposal(r_base)
        p_index = generate_proposal(r_index)
        assert p_base.proposed_category == "infrastructure-failure"
        assert p_index.proposed_category == "unresolved"


# ---------------------------------------------------------------------------
# Infrastructure failure priority
# ---------------------------------------------------------------------------


class TestInfrastructurePriority:
    def test_infrastructure_takes_priority_over_telemetry_signals(self):
        """If the response failed, classify as infrastructure regardless of
        telemetry signals (telemetry from a crashed session is unreliable)."""
        r = _minimal_result(
            success=False,
            error="session crashed",
            context_metrics={"stale_context_detected": True},
        )
        p = generate_proposal(r)
        assert p.proposed_category == "infrastructure-failure"

    def test_error_without_success_false_still_signals(self):
        """response.error present with success=true is unusual but the error
        signal should still be captured in evidence."""
        r = _minimal_result(success=True, error="partial error")
        p = generate_proposal(r)
        sources = [s["source"] for s in p.evidence["signals"]]
        assert "response.error" in sources


# ---------------------------------------------------------------------------
# Batch output structure
# ---------------------------------------------------------------------------


class TestBatchOutput:
    def test_batch_output_has_required_fields(self):
        results = [_minimal_result()]
        output = generate_proposals(
            results,
            experiment_id="test-exp",
            timestamp="2026-07-25T00:00:00+00:00",
        )
        assert output["schema_version"] == PROPOSAL_SCHEMA_VERSION
        assert output["generator_version"] == GENERATOR_VERSION
        assert output["source_experiment_id"] == "test-exp"
        assert output["generated_at"] == "2026-07-25T00:00:00+00:00"
        assert output["input_record_count"] == 1
        assert len(output["proposals"]) == 1

    def test_batch_summary_counts(self):
        results = [
            _minimal_result(question_id="INV-001", success=False),
            _minimal_result(question_id="INV-002"),
            _minimal_result(
                question_id="INV-003",
                context_metrics={"stale_context_detected": True},
            ),
        ]
        output = generate_proposals(results, timestamp="2026-07-25T00:00:00+00:00")
        summary = output["summary"]
        assert summary["total_proposals"] == 3
        assert summary["by_category"]["infrastructure-failure"] == 1
        assert summary["by_category"]["unresolved"] == 1
        assert summary["by_category"]["stale-context"] == 1
        assert summary["unresolved_count"] == 1

    def test_empty_input_produces_empty_proposals(self):
        output = generate_proposals([], timestamp="2026-07-25T00:00:00+00:00")
        assert output["proposals"] == []
        assert output["input_record_count"] == 0
        assert output["summary"]["total_proposals"] == 0


# ---------------------------------------------------------------------------
# Schema validation
# ---------------------------------------------------------------------------


class TestSchemaValidation:
    def test_output_validates_against_proposal_schema(self):
        try:
            import jsonschema
        except ImportError:
            pytest.skip("jsonschema not installed")

        schema_path = (
            PROJECT_ROOT / "benchmark" / "analyzer-assisted-v1" / "proposal_schema.json"
        )
        with open(schema_path) as f:
            schema = json.load(f)

        results = [
            _minimal_result(question_id="INV-001", success=False, error="crash"),
            _minimal_result(question_id="INV-002"),
            _minimal_result(
                question_id="INV-003",
                context_metrics={"stale_context_detected": True},
            ),
            _minimal_result(
                question_id="INV-004",
                context_metrics={"missing_context_detected": True},
            ),
            _minimal_result(
                question_id="INV-005",
                context_metrics={"unsupported_inference_detected": True},
            ),
        ]
        output = generate_proposals(
            results,
            experiment_id="test",
            timestamp="2026-07-25T00:00:00+00:00",
        )
        jsonschema.validate(output, schema)

    def test_individual_proposal_structure(self):
        r = _minimal_result(success=False, error="timeout")
        p = generate_proposal(r)
        d = p.to_dict()
        assert set(d.keys()) == {
            "result_id",
            "question_id",
            "condition_id",
            "proposed_category",
            "review_status",
            "evidence",
            "reasoning",
            "suggested_action",
        }
