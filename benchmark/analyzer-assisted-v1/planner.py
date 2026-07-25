#!/usr/bin/env python3
"""Condition-aware evaluation planner for the analyzer-assisted experiment.

Loads experiment.json and corpus_manifest.json, then produces deterministic
evaluation plans for a given condition without launching any agents or
running paid evaluations.

Usage as library:
    manifest = load_manifest(Path("experiment.json"))
    plan = plan_condition(manifest, "baseline", artifact_identity={...})

Usage as CLI:
    python planner.py --manifest experiment.json --condition baseline \
        --artifact-json '{"architecture_context_sha": "abc123"}'
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

QUESTION_ID_PATTERN = re.compile(r"^[A-Z]+-\d{3}$")


def load_manifest(manifest_path: Path) -> dict:
    """Load experiment.json and resolve the sibling corpus_manifest.json.

    Returns the experiment manifest dict enriched with
    ``_active_question_ids`` — a sorted list of active question IDs from
    the corpus manifest.
    """
    manifest_path = Path(manifest_path)
    with open(manifest_path) as f:
        manifest = json.load(f)

    corpus_path = manifest_path.parent / "corpus_manifest.json"
    active_ids: list[str] = []
    if corpus_path.exists():
        with open(corpus_path) as f:
            corpus = json.load(f)
        active_ids = sorted(
            q["id"]
            for q in corpus.get("questions", [])
            if q.get("status") == "active"
        )

    manifest["_active_question_ids"] = active_ids
    return manifest


_PROVENANCE_METADATA_KEYS = frozenset({"description"})


def _validate_artifact_identity(
    artifact_identity: dict,
    condition: dict,
) -> None:
    """Validate artifact_identity keys against manifest-declared requirements.

    Always requires non-empty ``type`` and ``revision_source``.  Additionally
    requires any condition-specific key whose manifest value is non-null
    (e.g. ``index_revision_source``, ``query_binary_version``).
    """
    for key in ("type", "revision_source"):
        if not artifact_identity.get(key):
            raise ValueError(
                f"artifact_identity is missing required key '{key}'. "
                f"Available conditions require non-empty "
                f"'type' and 'revision_source'."
            )

    provenance_reqs = condition.get("artifact_identity", {})
    for key, req_val in provenance_reqs.items():
        if key in _PROVENANCE_METADATA_KEYS:
            continue
        if key in ("type", "revision_source"):
            continue
        if req_val is None:
            continue
        if not artifact_identity.get(key):
            raise ValueError(
                f"artifact_identity is missing required key '{key}'. "
                f"Condition '{condition.get('condition_id', '')}' requires "
                f"'{key}' (manifest declares: {req_val!r})."
            )


def plan_condition(
    manifest: dict,
    condition_id: str,
    question_ids: list[str] | None = None,
    artifact_identity: dict | None = None,
) -> dict:
    """Build a deterministic evaluation plan for *condition_id*.

    Parameters
    ----------
    manifest:
        Experiment manifest dict (from :func:`load_manifest`).
    condition_id:
        One of the condition IDs defined in the manifest.
    question_ids:
        Optional subset of question IDs to plan.  ``None`` means all
        active questions from the corpus manifest.
    artifact_identity:
        Provenance dict required for available conditions.  Must be
        provided when the condition is available.

    Returns
    -------
    dict
        A plan dict with keys: ``condition_id``, ``condition_name``,
        ``status``, ``available``, ``question_ids``, ``access_boundary``,
        ``tools_permitted``, ``tools_denied``, ``provenance_requirements``,
        ``artifact_identity``, ``unavailable_reason``.

    Raises
    ------
    ValueError
        On unknown condition, invalid/duplicate question IDs, or missing
        artifact identity for available conditions.
    """
    conditions = manifest.get("conditions", [])
    condition = None
    for c in conditions:
        if c.get("condition_id") == condition_id:
            condition = c
            break

    if condition is None:
        known = sorted(c.get("condition_id", "") for c in conditions)
        raise ValueError(
            f"Unknown condition_id '{condition_id}'. "
            f"Known conditions: {known}"
        )

    available = condition.get("available", False)
    status = condition.get("status", "pending")

    active_question_ids = set(manifest.get("_active_question_ids", []))

    if question_ids is not None:
        seen: set[str] = set()
        for qid in question_ids:
            if not QUESTION_ID_PATTERN.match(qid):
                raise ValueError(
                    f"Invalid question_id format '{qid}'. "
                    f"Expected pattern: {QUESTION_ID_PATTERN.pattern}"
                )
            if qid in seen:
                raise ValueError(f"Duplicate question_id '{qid}'.")
            seen.add(qid)
            if active_question_ids and qid not in active_question_ids:
                raise ValueError(
                    f"Unknown question_id '{qid}'. "
                    f"Not in active corpus questions."
                )
        resolved_ids = sorted(question_ids)
    else:
        resolved_ids = sorted(active_question_ids)

    if available and artifact_identity is None:
        raise ValueError(
            f"Condition '{condition_id}' is available but no "
            f"artifact_identity was provided. Provenance is required "
            f"for available conditions."
        )

    if available and artifact_identity is not None:
        _validate_artifact_identity(artifact_identity, condition)

    return {
        "condition_id": condition_id,
        "condition_name": condition.get("name", ""),
        "status": status,
        "available": available,
        "question_ids": resolved_ids,
        "access_boundary": condition.get("access_boundary", ""),
        "tools_permitted": condition.get("tools_permitted", []),
        "tools_denied": condition.get("tools_denied", []),
        "provenance_requirements": condition.get("artifact_identity", {}),
        "artifact_identity": artifact_identity,
        "unavailable_reason": (
            condition.get("unavailable_reason") if not available else None
        ),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Condition-aware evaluation planner (no agents launched).",
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=Path(__file__).resolve().parent / "experiment.json",
        help="Path to experiment.json (default: sibling experiment.json).",
    )
    parser.add_argument(
        "--condition",
        required=True,
        help="Condition ID to plan (e.g. baseline, index-md).",
    )
    parser.add_argument(
        "--question-id",
        action="append",
        dest="question_ids",
        help="Question ID subset (repeatable). Omit for all active.",
    )
    parser.add_argument(
        "--artifact-json",
        type=str,
        default=None,
        help="Artifact identity as JSON string or @file path.",
    )

    args = parser.parse_args(argv)

    artifact_identity = None
    if args.artifact_json is not None:
        raw = args.artifact_json
        if raw.startswith("@"):
            with open(raw[1:]) as f:
                artifact_identity = json.load(f)
        else:
            artifact_identity = json.loads(raw)

    try:
        manifest = load_manifest(args.manifest)
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        print(f"Error loading manifest: {exc}", file=sys.stderr)
        return 1

    try:
        plan = plan_condition(
            manifest,
            args.condition,
            question_ids=args.question_ids,
            artifact_identity=artifact_identity,
        )
    except ValueError as exc:
        print(f"Planning error: {exc}", file=sys.stderr)
        return 1

    json.dump(plan, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
