#!/usr/bin/env python3
"""Validate experiment manifest and result records for the analyzer-assisted evaluation.

Checks for experiment.json:
  1. Required top-level fields present.
  2. Each condition has a valid condition_id.
  3. Unavailable conditions have unavailable_reason.
  4. No duplicate condition IDs.
  5. All four required conditions are defined.
  6. Failure classification IDs are valid.

Checks for result records:
  1. condition_id is a known condition from the manifest.
  2. Provenance fields are present and non-empty.
  3. Failure classifications use only valid IDs.
  4. Telemetry values are non-negative.
  5. Unavailable conditions are not evaluated (condition_available=false).
  6. question_id matches expected pattern.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:
    jsonschema = None

SCRIPT_DIR = Path(__file__).resolve().parent

sys.path.insert(0, str(SCRIPT_DIR.parent.parent))
from lib.context_telemetry import (  # noqa: E402
    CONTRACT_VERSION as _CTX_CONTRACT_VERSION,
)

VALID_CONDITION_IDS = {"baseline", "index-md", "arch-query", "combined"}

VALID_FAILURE_CLASSIFICATIONS = {
    "stale-context",
    "missing-context",
    "retrieval-failure",
    "unsupported-inference",
    "scoring-defect",
    "infrastructure-failure",
}

VALID_QUESTION_CATEGORIES = {
    "inventory",
    "component-facts",
    "cross-component-integration",
    "navigation-structure",
}

VALID_QUESTION_DIFFICULTIES = {
    "direct-lookup",
    "multi-doc",
    "synthesis",
    "gap-detection",
}

VALID_QUESTION_SCOPES = {"rhoai", "rhoai.next", "cross-product", "platform-meta"}

VALID_EVENT_KINDS = {
    "read.useful",
    "read.navigation",
    "read.denied",
    "query.issued",
    "query.denied",
    "signal.missing_context",
    "signal.stale_context",
    "signal.unsupported_inference",
}


def validate_experiment_manifest(manifest: dict) -> list[str]:
    """Validate an experiment manifest dictionary. Returns a list of errors."""
    errors: list[str] = []

    for field in (
        "manifest_version",
        "experiment_id",
        "conditions",
        "failure_classifications",
    ):
        if field not in manifest:
            errors.append(f"Missing required field: {field}")

    conditions = manifest.get("conditions", [])
    if not isinstance(conditions, list):
        errors.append("conditions must be a list")
        return errors

    seen_ids: set[str] = set()
    for i, cond in enumerate(conditions):
        cid = cond.get("condition_id")
        if not cid:
            errors.append(f"conditions[{i}]: missing condition_id")
            continue

        if cid not in VALID_CONDITION_IDS:
            errors.append(
                f"conditions[{i}]: unknown condition_id '{cid}' "
                f"(valid: {sorted(VALID_CONDITION_IDS)})"
            )

        if cid in seen_ids:
            errors.append(f"conditions[{i}]: duplicate condition_id '{cid}'")
        seen_ids.add(cid)

        if not cond.get("available", True) and not cond.get("unavailable_reason"):
            errors.append(
                f"conditions[{i}] ({cid}): unavailable condition must have "
                "unavailable_reason"
            )

        for field in ("name", "description", "context_sources", "tools_permitted"):
            if field not in cond:
                errors.append(f"conditions[{i}] ({cid}): missing field '{field}'")

    missing_conditions = VALID_CONDITION_IDS - seen_ids
    if missing_conditions:
        errors.append(
            f"Missing required conditions: {sorted(missing_conditions)}"
        )

    fc_list = manifest.get("failure_classifications", [])
    if isinstance(fc_list, list):
        fc_ids = set()
        for fc in fc_list:
            fc_id = fc.get("id")
            if fc_id and fc_id not in VALID_FAILURE_CLASSIFICATIONS:
                errors.append(f"Unknown failure classification: '{fc_id}'")
            if fc_id:
                fc_ids.add(fc_id)
        missing_fc = VALID_FAILURE_CLASSIFICATIONS - fc_ids
        if missing_fc:
            errors.append(
                f"Missing failure classifications: {sorted(missing_fc)}"
            )

    return errors


def validate_result_record(
    result: dict,
    known_condition_ids: set[str] | None = None,
) -> list[str]:
    """Validate a single result record. Returns a list of errors."""
    errors: list[str] = []
    if known_condition_ids is None:
        known_condition_ids = VALID_CONDITION_IDS

    cid = result.get("condition_id")
    if not cid:
        errors.append("Missing condition_id")
    elif cid not in known_condition_ids:
        errors.append(
            f"Unknown condition_id '{cid}' "
            f"(valid: {sorted(known_condition_ids)})"
        )

    qid = result.get("question_id")
    if not qid:
        errors.append("Missing question_id")
    elif not isinstance(qid, str):
        errors.append(f"question_id must be a string, got {type(qid).__name__}")
    else:
        import re
        if not re.match(r"^[A-Z]+-\d{3}$", qid):
            errors.append(
                f"question_id '{qid}' does not match pattern ^[A-Z]+-\\d{{3}}$"
            )

    category = result.get("question_category")
    if category and category not in VALID_QUESTION_CATEGORIES:
        errors.append(f"Unknown question_category '{category}'")

    difficulty = result.get("question_difficulty")
    if difficulty and difficulty not in VALID_QUESTION_DIFFICULTIES:
        errors.append(f"Unknown question_difficulty '{difficulty}'")

    scope = result.get("question_scope")
    if scope and scope not in VALID_QUESTION_SCOPES:
        errors.append(f"Unknown question_scope '{scope}'")

    provenance = result.get("provenance")
    if not provenance:
        errors.append("Missing provenance")
    elif isinstance(provenance, dict):
        sha = provenance.get("architecture_context_sha")
        if not sha or (isinstance(sha, str) and not sha.strip()):
            errors.append(
                "provenance.architecture_context_sha is required "
                "and must be non-empty"
            )
        corpus_v = provenance.get("corpus_version")
        if not corpus_v:
            errors.append("provenance.corpus_version is required")
        manifest_v = provenance.get("experiment_manifest_version")
        if not manifest_v:
            errors.append("provenance.experiment_manifest_version is required")

    if not result.get("model"):
        errors.append("Missing model")
    if not result.get("runner_version"):
        errors.append("Missing runner_version")
    if not result.get("timestamp"):
        errors.append("Missing timestamp")

    condition_available = result.get("condition_available", True)
    response = result.get("response")
    if not condition_available and response and response.get("success"):
        errors.append(
            "condition_available is false but response.success is true; "
            "unavailable conditions must not produce successful results"
        )

    classifications = result.get("failure_classifications", [])
    if not isinstance(classifications, list):
        errors.append("failure_classifications must be a list")
    else:
        for fc in classifications:
            if fc not in VALID_FAILURE_CLASSIFICATIONS:
                errors.append(f"Unknown failure classification: '{fc}'")
        if len(classifications) != len(set(classifications)):
            errors.append("failure_classifications contains duplicates")

    telemetry = result.get("telemetry")
    if isinstance(telemetry, dict):
        numeric_fields = [
            "duration_seconds",
            "input_tokens",
            "output_tokens",
            "total_cost_usd",
            "num_turns",
        ]
        for field in numeric_fields:
            value = telemetry.get(field)
            if value is not None and isinstance(value, (int, float)) and value < 0:
                errors.append(
                    f"telemetry.{field} must be non-negative, got {value}"
                )

        tool_calls = telemetry.get("tool_calls")
        if isinstance(tool_calls, dict):
            for tool_name, count in tool_calls.items():
                if isinstance(count, (int, float)) and count < 0:
                    errors.append(
                        f"telemetry.tool_calls[{tool_name}] must be non-negative, "
                        f"got {count}"
                    )

    context_metrics = result.get("context_metrics")
    if isinstance(context_metrics, dict):
        for field in (
            "context_fetches",
            "useful_reads",
            "navigation_reads",
            "queries_issued",
        ):
            value = context_metrics.get(field)
            if value is not None and isinstance(value, (int, float)) and value < 0:
                errors.append(
                    f"context_metrics.{field} must be non-negative, got {value}"
                )

    ctx_prov = result.get("context_provenance")
    if ctx_prov is not None:
        if not isinstance(ctx_prov, dict):
            errors.append("context_provenance must be an object")
        else:
            ctv = ctx_prov.get("context_telemetry_version")
            if ctv != _CTX_CONTRACT_VERSION:
                errors.append(
                    f"context_provenance.context_telemetry_version must be "
                    f"'{_CTX_CONTRACT_VERSION}', got '{ctv}'"
                )
            ctx_events = ctx_prov.get("context_events")
            if not isinstance(ctx_events, dict):
                errors.append(
                    "context_provenance.context_events is required "
                    "and must be an object"
                )
            else:
                cv = ctx_events.get("contract_version")
                if cv != _CTX_CONTRACT_VERSION:
                    errors.append(
                        f"context_provenance.context_events.contract_version "
                        f"must be '{_CTX_CONTRACT_VERSION}', got '{cv}'"
                    )
                events_list = ctx_events.get("events")
                if not isinstance(events_list, list):
                    errors.append(
                        "context_provenance.context_events.events must be a list"
                    )
                else:
                    for i, evt in enumerate(events_list):
                        if not isinstance(evt, dict):
                            errors.append(
                                f"context_provenance.context_events.events[{i}] "
                                "must be an object"
                            )
                            continue
                        kind = evt.get("kind")
                        if kind not in VALID_EVENT_KINDS:
                            errors.append(
                                f"context_provenance.context_events.events[{i}].kind "
                                f"'{kind}' is not a valid EventKind"
                            )
                if not isinstance(ctx_events.get("context_metrics"), dict):
                    errors.append(
                        "context_provenance.context_events.context_metrics "
                        "is required and must be an object"
                    )

    if isinstance(provenance, dict):
        prov_ctv = provenance.get("context_telemetry_version")
        prov_ctx = provenance.get("context_provenance")
        has_ctv = prov_ctv is not None
        has_ctx = prov_ctx is not None
        if has_ctv != has_ctx:
            missing = (
                "context_provenance" if has_ctv else "context_telemetry_version"
            )
            errors.append(
                f"provenance.context_telemetry_version and "
                f"provenance.context_provenance must both be present or both "
                f"absent; missing {missing}"
            )
        if prov_ctv is not None and prov_ctv != _CTX_CONTRACT_VERSION:
            errors.append(
                f"provenance.context_telemetry_version must be "
                f"'{_CTX_CONTRACT_VERSION}', got '{prov_ctv}'"
            )
        if prov_ctx is not None:
            if not isinstance(prov_ctx, dict):
                errors.append(
                    "provenance.context_provenance must be an object"
                )
            else:
                inner_ctv = prov_ctx.get("context_telemetry_version")
                if inner_ctv != _CTX_CONTRACT_VERSION:
                    errors.append(
                        f"provenance.context_provenance."
                        f"context_telemetry_version must be "
                        f"'{_CTX_CONTRACT_VERSION}', got '{inner_ctv}'"
                    )
                eapt = prov_ctx.get("events_attached_per_tree")
                if eapt is not True:
                    errors.append(
                        "provenance.context_provenance."
                        "events_attached_per_tree must be true"
                    )

    return errors


def validate_result_schema(result: dict) -> list[str]:
    """Validate a result record against the JSON Schema. Returns errors."""
    if jsonschema is None:
        return [
            "WARN: jsonschema not installed; skipping JSON Schema validation "
            "(pip install jsonschema)"
        ]
    schema_path = SCRIPT_DIR / "result_schema.json"
    if not schema_path.exists():
        return [f"result_schema.json not found at {schema_path}"]
    with open(schema_path) as f:
        schema = json.load(f)
    errors = []
    v = jsonschema.Draft202012Validator(schema)
    for err in sorted(v.iter_errors(result), key=lambda e: list(e.path)):
        path = ".".join(str(p) for p in err.absolute_path)
        errors.append(f"Schema: {path}: {err.message}")
    return errors


def load_and_validate_manifest(
    path: Path | None = None,
) -> tuple[dict, list[str]]:
    """Load and validate the experiment manifest. Returns (manifest, errors)."""
    if path is None:
        path = SCRIPT_DIR / "experiment.json"
    if not path.exists():
        return {}, [f"Manifest not found: {path}"]
    with open(path) as f:
        manifest = json.load(f)
    errors = validate_experiment_manifest(manifest)
    return manifest, errors


def main() -> int:
    manifest_path = SCRIPT_DIR / "experiment.json"
    result_schema_path = SCRIPT_DIR / "result_schema.json"

    print("Validating experiment manifest...")
    manifest, manifest_errors = load_and_validate_manifest(manifest_path)

    warnings = [e for e in manifest_errors if e.startswith("WARN:")]
    errors = [e for e in manifest_errors if not e.startswith("WARN:")]

    for w in warnings:
        print(f"  {w}")

    if errors:
        print(f"\nFAIL: {len(errors)} manifest error(s):\n")
        for e in errors:
            print(f"  - {e}")
        return 1

    conditions = manifest.get("conditions", [])
    available = [c for c in conditions if c.get("available", True)]
    pending = [c for c in conditions if not c.get("available", True)]

    avail_ids = ", ".join(c["condition_id"] for c in available)
    pend_ids = ", ".join(c["condition_id"] for c in pending)
    fc_count = len(manifest.get("failure_classifications", []))
    print("PASS: Manifest validated")
    print(f"  Version: {manifest.get('manifest_version')}")
    print(f"  Experiment: {manifest.get('experiment_id')}")
    print(f"  Conditions: {len(conditions)} total")
    print(f"    Available: {len(available)} ({avail_ids})")
    print(f"    Pending: {len(pending)} ({pend_ids})")
    print(f"  Failure classifications: {fc_count}")

    if result_schema_path.exists():
        print(f"\n  Result schema: {result_schema_path.name} present")
    else:
        print(f"\n  WARN: Result schema not found at {result_schema_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
