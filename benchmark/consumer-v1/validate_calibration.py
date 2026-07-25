#!/usr/bin/env python3
"""Validate a calibration set template against the calibration schema.

Deterministic validation only — checks structural validity, corpus membership,
selection consistency, null labels, and deterministic ordering.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

TEMPLATE_VERSION = "0.1.0"
VALID_ANSWERABILITIES = {"answerable", "answerable-as-gap"}
VALID_TIERS = {1, 2, 3, 4}


def validate_calibration_template(
    data: dict, corpus: dict | None = None
) -> list[str]:
    """Validate a calibration template dict. Returns a list of error strings."""
    errors: list[str] = []

    if not isinstance(data, dict):
        return ["Root must be a JSON object"]

    tv = data.get("template_version")
    if tv != TEMPLATE_VERSION:
        errors.append(f"template_version must be '{TEMPLATE_VERSION}', got '{tv}'")

    sel = data.get("selection", {})
    if not isinstance(sel, dict):
        errors.append("selection must be an object")
    else:
        total = sel.get("total", 0)
        if not isinstance(total, int) or total < 20 or total > 30:
            errors.append(f"selection.total must be 20-30, got {total}")

        if sel.get("deterministic") is not True:
            errors.append("selection.deterministic must be true")

        by_tier = sel.get("by_tier", {})
        if isinstance(by_tier, dict):
            for t in ["1", "2", "3", "4"]:
                if t not in by_tier or not isinstance(by_tier[t], int) or by_tier[t] < 1:
                    errors.append(f"selection.by_tier.{t} must be a positive integer")
            tier_sum = sum(by_tier.get(str(t), 0) for t in range(1, 5))
            if tier_sum != total:
                errors.append(
                    f"selection.by_tier sum ({tier_sum}) does not match total ({total})"
                )

        by_ans = sel.get("by_answerability", {})
        if isinstance(by_ans, dict):
            gap_count = by_ans.get("answerable-as-gap", 0)
            if not isinstance(gap_count, int) or gap_count < 1:
                errors.append("selection.by_answerability.answerable-as-gap must be >= 1")
            ans_count = by_ans.get("answerable", 0)
            if isinstance(ans_count, int) and isinstance(gap_count, int):
                if ans_count + gap_count != total:
                    errors.append(
                        f"selection.by_answerability sum ({ans_count + gap_count}) "
                        f"does not match total ({total})"
                    )

    questions = data.get("questions", [])
    if not isinstance(questions, list):
        errors.append("questions must be an array")
        questions = []

    if len(questions) != sel.get("total", 0):
        errors.append(
            f"questions array length ({len(questions)}) does not match "
            f"selection.total ({sel.get('total', 0)})"
        )

    seen_ids: set[str] = set()
    actual_by_tier: dict[int, int] = {1: 0, 2: 0, 3: 0, 4: 0}
    actual_by_ans: dict[str, int] = {"answerable": 0, "answerable-as-gap": 0}
    prev_tier = 0
    prev_id = ""

    corpus_ids: set[str] = set()
    corpus_questions: dict[str, dict] = {}
    if corpus and isinstance(corpus.get("questions"), list):
        for q in corpus["questions"]:
            if isinstance(q, dict) and "id" in q:
                corpus_ids.add(q["id"])
                corpus_questions[q["id"]] = q

    for i, q in enumerate(questions):
        prefix = f"questions[{i}]"
        if not isinstance(q, dict):
            errors.append(f"{prefix}: must be an object")
            continue

        qid = q.get("question_id", "")
        if not qid or not isinstance(qid, str):
            errors.append(f"{prefix}: question_id must be non-empty string")
        elif qid in seen_ids:
            errors.append(f"{prefix}: duplicate question_id '{qid}'")
        else:
            seen_ids.add(qid)

        if corpus_ids and qid not in corpus_ids:
            errors.append(f"{prefix}: question_id '{qid}' not found in corpus")

        tier = q.get("tier")
        if not isinstance(tier, int) or tier not in VALID_TIERS:
            errors.append(f"{prefix}: tier must be 1-4, got {tier}")
        else:
            actual_by_tier[tier] += 1
            if tier < prev_tier:
                errors.append(
                    f"{prefix}: questions must be ordered by tier "
                    f"(tier {tier} after tier {prev_tier})"
                )
            elif tier == prev_tier and qid < prev_id:
                errors.append(
                    f"{prefix}: questions within same tier must be ordered by ID "
                    f"('{qid}' after '{prev_id}')"
                )
            prev_tier = tier
            prev_id = qid

        if q.get("human_label") is not None:
            errors.append(f"{prefix}: human_label must be null in template")

        ans = q.get("answerability", "")
        if ans not in VALID_ANSWERABILITIES:
            errors.append(f"{prefix}: answerability must be one of {VALID_ANSWERABILITIES}")
        else:
            actual_by_ans[ans] += 1

        nde = q.get("not_documented_expected")
        if not isinstance(nde, bool):
            errors.append(f"{prefix}: not_documented_expected must be boolean")
        elif ans == "answerable-as-gap" and nde is not True:
            errors.append(f"{prefix}: answerable-as-gap requires not_documented_expected: true")
        elif ans == "answerable" and nde is not False:
            errors.append(f"{prefix}: answerable requires not_documented_expected: false")

        if corpus_ids and qid in corpus_questions:
            cq = corpus_questions[qid]
            if q.get("question") != cq.get("question"):
                errors.append(f"{prefix}: question text does not match corpus")
            if q.get("expected_answer") != cq.get("expected_answer"):
                errors.append(f"{prefix}: expected_answer does not match corpus")
            if q.get("tier") != cq.get("tier"):
                errors.append(f"{prefix}: tier does not match corpus")

        if not q.get("selection_rationale"):
            errors.append(f"{prefix}: selection_rationale must be non-empty")

    if isinstance(sel.get("by_tier"), dict):
        for t in range(1, 5):
            expected = sel["by_tier"].get(str(t), 0)
            if actual_by_tier[t] != expected:
                errors.append(
                    f"Tier {t}: expected {expected} questions, found {actual_by_tier[t]}"
                )

    if isinstance(sel.get("by_answerability"), dict):
        for status in ["answerable", "answerable-as-gap"]:
            expected = sel["by_answerability"].get(status, 0)
            if actual_by_ans[status] != expected:
                errors.append(
                    f"Answerability '{status}': expected {expected}, found {actual_by_ans[status]}"
                )

    return errors


def main():
    if len(sys.argv) < 2:
        print(
            "Usage: validate_calibration.py <calibration_template.json> [corpus.json]",
            file=sys.stderr,
        )
        sys.exit(1)

    path = Path(sys.argv[1])
    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        sys.exit(1)

    with open(path) as f:
        data = json.load(f)

    corpus = None
    if len(sys.argv) > 2:
        corpus_path = Path(sys.argv[2])
        if corpus_path.exists():
            with open(corpus_path) as f:
                corpus = json.load(f)

    errors = validate_calibration_template(data, corpus)
    if errors:
        print(f"FAIL: {len(errors)} error(s) found")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    else:
        sel = data.get("selection", {})
        print(f"PASS: {sel.get('total', 0)} calibration questions validated")
        print(f"  Template version: {data.get('template_version')}")
        print(f"  Algorithm: {sel.get('algorithm', 'N/A')}")
        by_tier = sel.get("by_tier", {})
        print(f"  Tier distribution: T1={by_tier.get('1', 0)} T2={by_tier.get('2', 0)} T3={by_tier.get('3', 0)} T4={by_tier.get('4', 0)}")
        by_ans = sel.get("by_answerability", {})
        print(f"  Answerability: answerable={by_ans.get('answerable', 0)} gap={by_ans.get('answerable-as-gap', 0)}")
        print(f"  Corpus cross-check: {'yes' if corpus else 'no'}")


if __name__ == "__main__":
    main()
