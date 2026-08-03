#!/usr/bin/env python3
"""Validate an LLM-as-judge result file against the judge_result_schema.

Deterministic validation only — does not call any model or run any evaluation.
Checks structural validity, internal consistency, calibration accounting,
and provenance requirements.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

SCHEMA_VERSION = "0.1.0"
ACCEPTANCE_THRESHOLD = 0.9
VALID_QID_PREFIXES = {"INV", "FACT", "INTG", "NAV"}


def validate_judge_result(data: dict) -> list[str]:
    """Validate a judge result dict. Returns a list of error strings."""
    errors: list[str] = []

    if not isinstance(data, dict):
        return ["Root must be a JSON object"]

    sv = data.get("schema_version")
    if sv != SCHEMA_VERSION:
        errors.append(f"schema_version must be '{SCHEMA_VERSION}', got '{sv}'")

    if "judge_model" not in data:
        errors.append("Missing required field: judge_model")
    else:
        jm = data["judge_model"]
        if not isinstance(jm, dict):
            errors.append("judge_model must be an object")
        else:
            if not jm.get("model_id"):
                errors.append("judge_model.model_id must be non-empty")
            if not jm.get("model_version"):
                errors.append("judge_model.model_version must be non-empty")

    if "authorization" not in data:
        errors.append("Missing required field: authorization")
    else:
        auth = data["authorization"]
        if not isinstance(auth, dict):
            errors.append("authorization must be an object")
        else:
            for field in [
                "authorized_by",
                "authorized_question_count",
                "estimated_cost_usd",
                "estimated_duration_seconds",
                "calibration_set_path",
            ]:
                if field not in auth:
                    errors.append(f"Missing authorization field: {field}")
            if isinstance(auth.get("authorized_question_count"), int):
                if auth["authorized_question_count"] < 1:
                    errors.append("authorized_question_count must be >= 1")
            if isinstance(auth.get("estimated_cost_usd"), (int, float)):
                if auth["estimated_cost_usd"] < 0:
                    errors.append("estimated_cost_usd must be >= 0")

    judgments = data.get("judgments", [])
    if not isinstance(judgments, list):
        errors.append("judgments must be an array")
        judgments = []

    seen_qids: set[str] = set()
    semantic_match_count = 0
    semantic_mismatch_count = 0
    abstention_count = 0
    disagreement_count = 0

    for i, j in enumerate(judgments):
        prefix = f"judgments[{i}]"
        if not isinstance(j, dict):
            errors.append(f"{prefix}: must be an object")
            continue

        qid = j.get("question_id", "")
        if not qid or not isinstance(qid, str):
            errors.append(f"{prefix}: question_id must be non-empty string")
        elif qid in seen_qids:
            errors.append(f"{prefix}: duplicate question_id '{qid}'")
        else:
            seen_qids.add(qid)

        abstained = j.get("abstained", False)
        sem = j.get("semantic_match")
        conf = j.get("confidence")
        rationale = j.get("rationale")
        det = j.get("deterministic_match")
        disagree = j.get("disagreement")

        if "rationale" not in j:
            errors.append(f"{prefix}: missing required field rationale")
        elif not isinstance(rationale, str) or not rationale:
            errors.append(f"{prefix}: rationale must be a non-empty string")

        if not isinstance(abstained, bool):
            errors.append(f"{prefix}: abstained must be boolean")

        if abstained:
            abstention_count += 1
            if sem is not None:
                errors.append(f"{prefix}: semantic_match must be null when abstained")
            if conf is not None:
                errors.append(f"{prefix}: confidence must be null when abstained")
        else:
            if not isinstance(sem, bool):
                errors.append(f"{prefix}: semantic_match must be boolean when not abstained")
            if conf is not None and not isinstance(conf, (int, float)):
                errors.append(f"{prefix}: confidence must be number or null")
            elif isinstance(conf, (int, float)) and not (0 <= conf <= 1):
                errors.append(f"{prefix}: confidence must be in [0, 1]")

            if sem is True:
                semantic_match_count += 1
            elif sem is False:
                semantic_mismatch_count += 1

        if not isinstance(det, bool):
            errors.append(f"{prefix}: deterministic_match must be boolean")

        if not isinstance(disagree, bool):
            errors.append(f"{prefix}: disagreement must be boolean")
        elif isinstance(sem, bool) and isinstance(det, bool):
            expected_disagree = sem != det
            if disagree != expected_disagree:
                errors.append(
                    f"{prefix}: disagreement must be {expected_disagree} "
                    f"(semantic_match={sem}, deterministic_match={det})"
                )

        if isinstance(disagree, bool) and disagree:
            disagreement_count += 1

    summary = data.get("summary", {})
    if not isinstance(summary, dict):
        errors.append("summary must be an object")
    else:
        expected = {
            "total_judged": len(judgments),
            "semantic_match_count": semantic_match_count,
            "semantic_mismatch_count": semantic_mismatch_count,
            "abstention_count": abstention_count,
            "disagreement_count": disagreement_count,
        }
        for key, expected_val in expected.items():
            actual = summary.get(key)
            if actual != expected_val:
                errors.append(
                    f"summary.{key}: expected {expected_val}, got {actual}"
                )

    cal = data.get("calibration", {})
    if not isinstance(cal, dict):
        errors.append("calibration must be an object")
    else:
        hl = cal.get("human_labeled_count", 0)
        ja = cal.get("judge_agreed_count", 0)
        rate = cal.get("agreement_rate")
        threshold = cal.get("acceptance_threshold")
        met = cal.get("acceptance_met")

        if not isinstance(hl, int) or hl < 0:
            errors.append("calibration.human_labeled_count must be non-negative integer")
        if not isinstance(ja, int) or ja < 0:
            errors.append("calibration.judge_agreed_count must be non-negative integer")

        if isinstance(hl, int) and isinstance(ja, int) and ja > hl:
            errors.append("calibration.judge_agreed_count cannot exceed human_labeled_count")

        if isinstance(hl, int) and hl > 0:
            expected_rate = round(ja / hl, 4) if isinstance(ja, int) else None
            if rate is None:
                errors.append("calibration.agreement_rate must not be null when human_labeled_count > 0")
            elif isinstance(rate, (int, float)):
                if abs(rate - expected_rate) > 0.001:
                    errors.append(
                        f"calibration.agreement_rate: expected ~{expected_rate}, got {rate}"
                    )
        elif isinstance(hl, int) and hl == 0:
            if rate is not None:
                errors.append("calibration.agreement_rate must be null when human_labeled_count is 0")

        if threshold != ACCEPTANCE_THRESHOLD:
            errors.append(f"calibration.acceptance_threshold must be {ACCEPTANCE_THRESHOLD}")

        if isinstance(rate, (int, float)) and isinstance(met, bool):
            expected_met = rate >= ACCEPTANCE_THRESHOLD
            if met != expected_met:
                errors.append(
                    f"calibration.acceptance_met must be {expected_met} "
                    f"(agreement_rate={rate}, threshold={ACCEPTANCE_THRESHOLD})"
                )
        elif hl == 0 and met is not False:
            errors.append("calibration.acceptance_met must be false when no human labels exist")

        human_labeled_qids = {
            j["question_id"]
            for j in judgments
            if isinstance(j, dict) and j.get("human_label") is not None
        }
        if isinstance(hl, int) and len(human_labeled_qids) != hl:
            errors.append(
                f"calibration.human_labeled_count ({hl}) does not match "
                f"judgment entries with human_label ({len(human_labeled_qids)})"
            )

    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_judge_result.py <judge-result.json>", file=sys.stderr)
        sys.exit(1)

    path = Path(sys.argv[1])
    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        sys.exit(1)

    with open(path) as f:
        data = json.load(f)

    errors = validate_judge_result(data)
    if errors:
        print(f"FAIL: {len(errors)} error(s) found")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    else:
        total = len(data.get("judgments", []))
        cal = data.get("calibration", {})
        print(f"PASS: {total} judgments validated")
        print(f"  Schema version: {data.get('schema_version')}")
        print(f"  Judge model: {data.get('judge_model', {}).get('model_id', 'N/A')}")
        print(f"  Calibration: {cal.get('judge_agreed_count', 0)}/{cal.get('human_labeled_count', 0)} agreement")
        print(f"  Acceptance met: {cal.get('acceptance_met', False)}")


if __name__ == "__main__":
    main()
