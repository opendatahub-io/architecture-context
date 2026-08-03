#!/usr/bin/env python3
"""Canary report and validator for the analyzer-assisted condition experiment.

Loads the canary manifest, experiment manifest, and optional result artifacts,
then emits a deterministic, machine-readable JSON report distinguishing
planned, available, unavailable, and missing-result states for each
question x condition cell.

Detects:
  - no-fallback violations (results for unavailable conditions)
  - missing-provenance violations (results without required provenance)
  - invalid-condition-status (condition status inconsistencies)
  - coverage violations (canary questions not in active corpus)

Safe when result artifacts are absent. Reports score_status as
"unavailable" rather than calculating scores.

Usage:
    python canary_report.py
    python canary_report.py --results-dir results/run-01/
    python canary_report.py --validate-only
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR.parent.parent))

from lib.context_telemetry import CONTRACT_VERSION  # noqa: E402

VALID_STATES = frozenset({"planned", "available", "unavailable", "missing-result"})


def load_json(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def load_canary_manifest(path: Path | None = None) -> dict:
    if path is None:
        path = SCRIPT_DIR / "canary_manifest.json"
    return load_json(path)


def load_experiment_manifest(path: Path | None = None) -> dict:
    if path is None:
        path = SCRIPT_DIR / "experiment.json"
    return load_json(path)


def _build_condition_map(experiment: dict) -> dict[str, dict]:
    return {
        c["condition_id"]: c
        for c in experiment.get("conditions", [])
        if "condition_id" in c
    }


def _load_results(results_dir: Path | None) -> dict[str, dict[str, dict]]:
    """Load result artifacts from a results directory.

    Returns {condition_id: {question_id: result_record}}.

    Each JSON file in the directory may contain a single result record,
    an array of result records, or a consumer-v1 envelope with records
    nested under a top-level ``results`` array. Records must have
    condition_id and question_id fields.
    """
    results: dict[str, dict[str, dict]] = {}
    if results_dir is None or not results_dir.is_dir():
        return results

    for json_file in sorted(results_dir.glob("*.json")):
        try:
            with open(json_file) as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue

        if isinstance(data, list):
            records = data
        elif isinstance(data, dict) and isinstance(data.get("results"), list):
            records = data["results"]
        else:
            records = [data]
        for record in records:
            if not isinstance(record, dict):
                continue
            cid = record.get("condition_id")
            qid = record.get("question_id")
            if cid and qid:
                results.setdefault(cid, {})[qid] = record

    return results


def _determine_state(
    condition_available: bool,
    result_found: bool,
    has_results_dir: bool,
) -> str:
    if not condition_available:
        return "unavailable"
    if result_found:
        return "available"
    if has_results_dir:
        return "missing-result"
    return "planned"


def _check_provenance(result: dict, condition: dict) -> list[str]:
    issues: list[str] = []
    provenance = result.get("provenance")
    if not provenance or not isinstance(provenance, dict):
        issues.append("missing provenance object")
        return issues

    if not provenance.get("architecture_context_sha"):
        issues.append("missing architecture_context_sha")
    if not provenance.get("corpus_version"):
        issues.append("missing corpus_version")
    if not provenance.get("experiment_manifest_version"):
        issues.append("missing experiment_manifest_version")

    artifact_identity = condition.get("artifact_identity", {})
    if (
        artifact_identity.get("index_revision_source")
        and not provenance.get("index_generation_sha")
    ):
        issues.append("missing index_generation_sha (required by condition)")
    if (
        artifact_identity.get("query_binary_version") is not None
        and artifact_identity.get("query_binary_version")
        and not provenance.get("query_binary_version")
    ):
        issues.append("missing query_binary_version (required by condition)")

    return issues


def _check_context_telemetry(result: dict) -> list[str]:
    """Check that a result record carries valid context telemetry evidence.

    Validates three layers:
      1. Per-tree context_provenance with context_telemetry_version
      2. Provenance-level context_telemetry_version
      3. Condition-level attachment evidence (events_attached_per_tree)
    """
    issues: list[str] = []

    ctx_prov = result.get("context_provenance")
    if ctx_prov is None or not isinstance(ctx_prov, dict):
        issues.append("missing per-tree context_provenance")
    else:
        ver = ctx_prov.get("context_telemetry_version")
        if not ver or not isinstance(ver, str):
            issues.append(
                "missing context_telemetry_version in per-tree "
                "context_provenance"
            )
        elif ver != CONTRACT_VERSION:
            issues.append(
                f"per-tree context_telemetry_version '{ver}' "
                f"does not match contract '{CONTRACT_VERSION}'"
            )

    provenance = result.get("provenance")
    if not provenance or not isinstance(provenance, dict):
        issues.append("missing provenance envelope for context telemetry")
    else:
        prov_ver = provenance.get("context_telemetry_version")
        if not prov_ver or not isinstance(prov_ver, str):
            issues.append(
                "missing context_telemetry_version in provenance"
            )
        elif prov_ver != CONTRACT_VERSION:
            issues.append(
                f"provenance context_telemetry_version '{prov_ver}' "
                f"does not match contract '{CONTRACT_VERSION}'"
            )

        cond_prov = provenance.get("context_provenance")
        if not cond_prov or not isinstance(cond_prov, dict):
            issues.append(
                "missing condition-level context_provenance in provenance"
            )
        elif not cond_prov.get("events_attached_per_tree"):
            issues.append(
                "missing events_attached_per_tree in condition-level "
                "context_provenance"
            )

    return issues


def _detect_violations(
    canary: dict,
    experiment: dict,
    condition_map: dict[str, dict],
    results: dict[str, dict[str, dict]],
    corpus_manifest_path: Path | None = None,
) -> list[dict]:
    violations: list[dict] = []
    canary_condition_ids = canary.get("condition_ids", [])
    canary_question_ids = canary.get("question_ids", [])

    for cid in sorted(canary_condition_ids):
        condition = condition_map.get(cid)
        if condition is None:
            continue
        if condition.get("available", False):
            continue
        cid_results = results.get(cid, {})
        for qid in sorted(canary_question_ids):
            if qid in cid_results:
                violations.append({
                    "type": "no-fallback",
                    "condition_id": cid,
                    "question_id": qid,
                    "message": (
                        f"Result found for unavailable condition '{cid}' "
                        f"on question '{qid}'. Unavailable conditions must "
                        f"not be evaluated."
                    ),
                })

    for cid in sorted(results.keys()):
        if cid not in canary_condition_ids:
            continue
        condition = condition_map.get(cid)
        if condition is None:
            continue
        for qid in sorted(results[cid].keys()):
            if qid not in canary_question_ids:
                continue
            result = results[cid][qid]
            issues = _check_provenance(result, condition)
            for issue in issues:
                violations.append({
                    "type": "missing-provenance",
                    "condition_id": cid,
                    "question_id": qid,
                    "message": (
                        f"Provenance issue for {cid}/{qid}: {issue}"
                    ),
                })

    for cid in sorted(results.keys()):
        if cid not in canary_condition_ids:
            continue
        condition = condition_map.get(cid)
        if condition is None or not condition.get("available", False):
            continue
        for qid in sorted(results[cid].keys()):
            if qid not in canary_question_ids:
                continue
            result = results[cid][qid]
            ctx_issues = _check_context_telemetry(result)
            for issue in ctx_issues:
                violations.append({
                    "type": "missing-context-telemetry",
                    "condition_id": cid,
                    "question_id": qid,
                    "message": (
                        f"Context telemetry issue for {cid}/{qid}: "
                        f"{issue}"
                    ),
                })

    for cid in sorted(canary_condition_ids):
        condition = condition_map.get(cid)
        if condition is None:
            violations.append({
                "type": "invalid-condition-status",
                "condition_id": cid,
                "question_id": None,
                "message": (
                    f"Condition '{cid}' is in canary manifest but not found "
                    f"in experiment manifest."
                ),
            })
            continue
        status = condition.get("status", "")
        is_available = condition.get("available", False)
        if is_available and status != "available":
            violations.append({
                "type": "invalid-condition-status",
                "condition_id": cid,
                "question_id": None,
                "message": (
                    f"Condition '{cid}' has available=true but "
                    f"status='{status}' (expected 'available')."
                ),
            })
        if not is_available and status == "available":
            violations.append({
                "type": "invalid-condition-status",
                "condition_id": cid,
                "question_id": None,
                "message": (
                    f"Condition '{cid}' has available=false but "
                    f"status='available' (inconsistent)."
                ),
            })
        if not is_available and not condition.get("unavailable_reason"):
            violations.append({
                "type": "invalid-condition-status",
                "condition_id": cid,
                "question_id": None,
                "message": (
                    f"Condition '{cid}' is unavailable but has no "
                    f"unavailable_reason."
                ),
            })

    if corpus_manifest_path and corpus_manifest_path.exists():
        try:
            corpus = load_json(corpus_manifest_path)
            active_ids = {
                q["id"]
                for q in corpus.get("questions", [])
                if q.get("status") == "active"
            }
            for qid in sorted(canary_question_ids):
                if qid not in active_ids:
                    violations.append({
                        "type": "coverage",
                        "condition_id": None,
                        "question_id": qid,
                        "message": (
                            f"Canary question '{qid}' is not active in "
                            f"the corpus manifest."
                        ),
                    })
        except (json.JSONDecodeError, OSError):
            pass

    violations.sort(key=lambda v: (
        v.get("type", ""),
        v.get("condition_id") or "",
        v.get("question_id") or "",
    ))

    return violations


def generate_report(
    canary: dict,
    experiment: dict,
    results_dir: Path | None = None,
    corpus_manifest_path: Path | None = None,
) -> dict:
    """Generate the canary readiness report."""
    condition_map = _build_condition_map(experiment)
    results = _load_results(results_dir)
    has_results_dir = results_dir is not None and results_dir.is_dir()

    canary_condition_ids = sorted(canary.get("condition_ids", []))
    canary_question_ids = sorted(canary.get("question_ids", []))

    entries: list[dict] = []
    for qid in canary_question_ids:
        for cid in canary_condition_ids:
            condition = condition_map.get(cid)
            is_available = (
                condition.get("available", False) if condition else False
            )
            result = results.get(cid, {}).get(qid)

            state = _determine_state(
                is_available, result is not None, has_results_dir
            )

            entries.append({
                "question_id": qid,
                "condition_id": cid,
                "state": state,
                "result_found": result is not None,
                "score_status": "unavailable",
                "provenance": result.get("provenance") if result else None,
            })

    if corpus_manifest_path is None:
        corpus_manifest_path = SCRIPT_DIR / "corpus_manifest.json"

    violations = _detect_violations(
        canary, experiment, condition_map, results, corpus_manifest_path
    )

    state_counts: dict[str, int] = {}
    for e in entries:
        s = e["state"]
        state_counts[s] = state_counts.get(s, 0) + 1

    return {
        "report_version": "1.0.0",
        "canary_id": canary.get("canary_id", ""),
        "corpus_id": canary.get("corpus_ref", {}).get("corpus_id", ""),
        "condition_ids": canary_condition_ids,
        "question_ids": canary_question_ids,
        "entries": entries,
        "violations": violations,
        "summary": {
            "total_cells": len(entries),
            "by_state": {
                state: state_counts.get(state, 0)
                for state in sorted(VALID_STATES)
            },
            "score_status": "unavailable",
            "violation_count": len(violations),
        },
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Canary readiness report for analyzer-assisted conditions."
        ),
    )
    parser.add_argument(
        "--canary",
        type=Path,
        default=SCRIPT_DIR / "canary_manifest.json",
    )
    parser.add_argument(
        "--experiment",
        type=Path,
        default=SCRIPT_DIR / "experiment.json",
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=None,
    )
    parser.add_argument(
        "--corpus-manifest",
        type=Path,
        default=None,
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
    )

    args = parser.parse_args(argv)

    try:
        canary = load_canary_manifest(args.canary)
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        print(f"Error loading canary manifest: {exc}", file=sys.stderr)
        return 1

    try:
        experiment = load_experiment_manifest(args.experiment)
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        print(f"Error loading experiment manifest: {exc}", file=sys.stderr)
        return 1

    corpus_path = args.corpus_manifest
    if corpus_path is None:
        corpus_path = SCRIPT_DIR / "corpus_manifest.json"

    report = generate_report(
        canary,
        experiment,
        results_dir=args.results_dir,
        corpus_manifest_path=corpus_path,
    )

    if args.validate_only:
        violations = report.get("violations", [])
        if violations:
            print(
                f"FAIL: {len(violations)} violation(s):",
                file=sys.stderr,
            )
            for v in violations:
                print(
                    f"  - [{v['type']}] {v['message']}",
                    file=sys.stderr,
                )
            return 1
        print("PASS: No violations detected.")
        return 0

    json.dump(report, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
