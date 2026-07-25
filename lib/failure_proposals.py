"""Deterministic failure-classification proposal generator.

Consumes validated result records from the analyzer-assisted evaluation and
emits reviewable, pending proposals with direct evidence and reasoning.
Proposals are non-authoritative and require human adjudication.

Classification rules (direct signals only):
  - response.success=false or response.error → infrastructure-failure
  - stale_context_detected or stale_context event → stale-context
  - missing_context_detected or missing_context event → missing-context
  - unsupported_inference_detected or event → unsupported-inference
  - No direct signal → unresolved (never infer from score alone)

Recorded failure_classifications from input records are preserved as
annotations in the evidence, not overwritten or promoted.
"""

from __future__ import annotations

import json
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

GENERATOR_VERSION = "1.1.0"
PROPOSAL_SCHEMA_VERSION = "1.0.0"

# When no input timestamps exist, use Unix epoch as a documented sentinel
# so output is deterministic and obviously not a real generation time.
_EPOCH_FALLBACK = "1970-01-01T00:00:00+00:00"

VALID_CONDITION_IDS = {"baseline", "index-md", "arch-query", "combined"}

PROPOSABLE_CATEGORIES = {
    "infrastructure-failure",
    "stale-context",
    "missing-context",
    "unsupported-inference",
    "unresolved",
}


@dataclass(frozen=True)
class Signal:
    source: str
    value: Any
    detail: str | None = None

    def to_dict(self) -> dict[str, Any]:
        d: dict[str, Any] = {"source": self.source, "value": self.value}
        d["detail"] = self.detail
        return d


@dataclass(frozen=True)
class Proposal:
    result_id: str
    question_id: str
    condition_id: str
    proposed_category: str
    review_status: str
    evidence: dict[str, Any]
    reasoning: str
    suggested_action: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def _extract_signals(result: dict[str, Any]) -> list[Signal]:
    """Extract direct classification signals from a result record."""
    signals: list[Signal] = []

    response = result.get("response", {})
    if isinstance(response, dict):
        if response.get("success") is False:
            signals.append(Signal(
                source="response.success",
                value=False,
                detail=None,
            ))
        error = response.get("error")
        if error is not None:
            signals.append(Signal(
                source="response.error",
                value=error,
                detail=str(error) if error else None,
            ))

    ctx_metrics = result.get("context_metrics")
    if isinstance(ctx_metrics, dict):
        if ctx_metrics.get("stale_context_detected") is True:
            signals.append(Signal(
                source="context_metrics.stale_context_detected",
                value=True,
            ))
        if ctx_metrics.get("missing_context_detected") is True:
            signals.append(Signal(
                source="context_metrics.missing_context_detected",
                value=True,
            ))
        if ctx_metrics.get("unsupported_inference_detected") is True:
            signals.append(Signal(
                source="context_metrics.unsupported_inference_detected",
                value=True,
            ))

    ctx_prov = result.get("context_provenance")
    if isinstance(ctx_prov, dict):
        ctx_events = ctx_prov.get("context_events")
        if isinstance(ctx_events, dict):
            events_list = ctx_events.get("events", [])
            if isinstance(events_list, list):
                for evt in events_list:
                    if not isinstance(evt, dict):
                        continue
                    kind = evt.get("kind")
                    if kind == "signal.stale_context":
                        signals.append(Signal(
                            source="context_events",
                            value="signal.stale_context",
                            detail=evt.get("detail"),
                        ))
                    elif kind == "signal.missing_context":
                        signals.append(Signal(
                            source="context_events",
                            value="signal.missing_context",
                            detail=evt.get("detail"),
                        ))
                    elif kind == "signal.unsupported_inference":
                        signals.append(Signal(
                            source="context_events",
                            value="signal.unsupported_inference",
                            detail=evt.get("detail"),
                        ))

    return signals


def _classify_from_signals(
    signals: list[Signal],
) -> tuple[str, str, str]:
    """Determine proposed_category, reasoning, and suggested_action from signals.

    Returns (proposed_category, reasoning, suggested_action).
    """
    has_infra = any(
        s.source in ("response.success", "response.error") for s in signals
    )
    has_stale = any(
        (s.source == "context_metrics.stale_context_detected" and s.value is True)
        or (s.source == "context_events" and s.value == "signal.stale_context")
        for s in signals
    )
    has_missing = any(
        (s.source == "context_metrics.missing_context_detected" and s.value is True)
        or (s.source == "context_events" and s.value == "signal.missing_context")
        for s in signals
    )
    has_unsupported = any(
        (
            s.source == "context_metrics.unsupported_inference_detected"
            and s.value is True
        )
        or (
            s.source == "context_events"
            and s.value == "signal.unsupported_inference"
        )
        for s in signals
    )

    if has_infra:
        return (
            "infrastructure-failure",
            "Response indicates infrastructure failure: "
            "session did not complete successfully or returned an error.",
            "accept",
        )

    if has_stale:
        return (
            "stale-context",
            "Explicit stale-context signal detected in telemetry: "
            "architecture documentation contains outdated information.",
            "investigate",
        )

    if has_missing:
        return (
            "missing-context",
            "Explicit missing-context signal detected in telemetry: "
            "required information was not present in architecture documentation.",
            "investigate",
        )

    if has_unsupported:
        return (
            "unsupported-inference",
            "Explicit unsupported-inference signal detected in telemetry: "
            "agent reasoning exceeded what the available context supports.",
            "investigate",
        )

    return (
        "unresolved",
        "No direct signal supports a specific failure classification. "
        "The result may reflect a retrieval failure, scoring defect, or "
        "other cause, but this cannot be determined from telemetry alone.",
        "manual-classify",
    )


def _validate_input_record(result: dict[str, Any]) -> list[str]:
    """Validate minimum required fields for proposal generation."""
    errors: list[str] = []

    if not isinstance(result, dict):
        return ["Input is not a dict"]

    qid = result.get("question_id")
    if not qid or not isinstance(qid, str):
        errors.append("Missing or invalid question_id")

    cid = result.get("condition_id")
    if not cid or not isinstance(cid, str):
        errors.append("Missing or invalid condition_id")
    elif cid not in VALID_CONDITION_IDS:
        errors.append(f"Unknown condition_id: {cid}")

    if "response" not in result:
        errors.append("Missing response field")

    return errors


def generate_proposal(result: dict[str, Any]) -> Proposal:
    """Generate a single failure-classification proposal from a result record.

    Raises ValueError if the input record is structurally invalid.
    """
    errors = _validate_input_record(result)
    if errors:
        raise ValueError(f"Invalid result record: {'; '.join(errors)}")

    question_id = result["question_id"]
    condition_id = result["condition_id"]
    result_id = f"{condition_id}/{question_id}"

    signals = _extract_signals(result)
    proposed_category, reasoning, suggested_action = _classify_from_signals(signals)

    recorded = result.get("failure_classifications", [])
    if not isinstance(recorded, list):
        recorded = []

    evidence = {
        "signals": [s.to_dict() for s in signals],
        "recorded_classifications": list(recorded),
    }

    return Proposal(
        result_id=result_id,
        question_id=question_id,
        condition_id=condition_id,
        proposed_category=proposed_category,
        review_status="pending",
        evidence=evidence,
        reasoning=reasoning,
        suggested_action=suggested_action,
    )


def _derive_timestamp(results: list[dict[str, Any]]) -> str:
    """Derive a deterministic generated_at from input result timestamps.

    Uses the lexicographically greatest (latest) ISO 8601 timestamp found
    among result records. Falls back to _EPOCH_FALLBACK when no valid
    timestamps exist, producing a sentinel that is deterministic and
    obviously not a real generation time.
    """
    timestamps: list[str] = []
    for r in results:
        ts = r.get("timestamp")
        if isinstance(ts, str) and ts:
            timestamps.append(ts)
    if timestamps:
        return max(timestamps)
    return _EPOCH_FALLBACK


def generate_proposals(
    results: list[dict[str, Any]],
    *,
    experiment_id: str = "",
    timestamp: str | None = None,
) -> dict[str, Any]:
    """Generate proposals for a batch of result records.

    Returns a proposal document matching proposal_schema.json.
    Raises ValueError on malformed individual records.

    When timestamp is None, derived deterministically from input record
    timestamps (latest wins), falling back to Unix epoch sentinel.
    """
    if not isinstance(results, list):
        raise ValueError("Input must be a list of result records")

    if timestamp is None:
        timestamp = _derive_timestamp(results)

    proposals: list[dict[str, Any]] = []
    for result in results:
        proposal = generate_proposal(result)
        proposals.append(proposal.to_dict())

    by_category: dict[str, int] = {}
    for p in proposals:
        cat = p["proposed_category"]
        by_category[cat] = by_category.get(cat, 0) + 1

    return {
        "schema_version": PROPOSAL_SCHEMA_VERSION,
        "generator_version": GENERATOR_VERSION,
        "source_experiment_id": experiment_id,
        "generated_at": timestamp,
        "input_record_count": len(results),
        "proposals": proposals,
        "summary": {
            "total_proposals": len(proposals),
            "by_category": by_category,
            "unresolved_count": by_category.get("unresolved", 0),
        },
    }


def main() -> int:
    """CLI entry point: reads result records from JSON file, writes proposals."""
    import argparse

    parser = argparse.ArgumentParser(
        description=(
            "Generate failure-classification proposals "
            "from evaluation results."
        ),
    )
    parser.add_argument(
        "input_file",
        type=Path,
        help="Path to JSON file containing an array of result records.",
    )
    parser.add_argument(
        "-o", "--output",
        type=Path,
        default=None,
        help="Output file path (default: stdout).",
    )
    parser.add_argument(
        "--experiment-id",
        type=str,
        default="",
        help="Experiment ID to record in output.",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate output against proposal_schema.json.",
    )
    args = parser.parse_args()

    if not args.input_file.exists():
        print(f"Error: input file not found: {args.input_file}", file=sys.stderr)
        return 1

    with open(args.input_file) as f:
        data = json.load(f)

    if isinstance(data, dict) and "results" in data:
        results = data["results"]
    elif isinstance(data, list):
        results = data
    else:
        print(
            "Error: input must be a JSON array or "
            "object with 'results' key",
            file=sys.stderr,
        )
        return 1

    experiment_id = args.experiment_id
    if not experiment_id and isinstance(data, dict):
        experiment_id = data.get("experiment_id", "")

    try:
        output = generate_proposals(results, experiment_id=experiment_id)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    if args.validate:
        schema_path = (
            Path(__file__).resolve().parent.parent
            / "benchmark"
            / "analyzer-assisted-v1"
            / "proposal_schema.json"
        )
        if not schema_path.exists():
            print(
                f"Warning: proposal schema not found "
                f"at {schema_path}",
                file=sys.stderr,
            )
        else:
            try:
                import jsonschema
                with open(schema_path) as f:
                    schema = json.load(f)
                jsonschema.validate(output, schema)
                print(
                    "Proposal output validates against schema.",
                    file=sys.stderr,
                )
            except ImportError:
                print(
                    "Warning: jsonschema not installed; "
                    "skipping validation",
                    file=sys.stderr,
                )
            except jsonschema.ValidationError as e:
                print(f"Schema validation error: {e.message}", file=sys.stderr)
                return 1

    json_output = json.dumps(output, indent=2, sort_keys=False)
    if args.output:
        args.output.write_text(json_output + "\n")
        print(f"Proposals written to {args.output}", file=sys.stderr)
    else:
        print(json_output)

    return 0


if __name__ == "__main__":
    sys.exit(main())
