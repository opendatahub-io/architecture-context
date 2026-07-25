"""Deterministic validator for the failure-adjudication template.

Validates:
  - Schema compliance (adjudication_schema.json)
  - All human_category values are null (template constraint)
  - Every proposal question_id exists in the consumer-v1 corpus
  - result_id matches the expected format
  - Summary counts match actual proposal data
  - Proposals are sorted by question_id
  - No duplicate question_ids
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def validate(
    template_path: str | Path,
    corpus_path: str | Path | None = None,
    schema_path: str | Path | None = None,
) -> list[str]:
    """Validate an adjudication template. Returns a list of error strings."""
    errors: list[str] = []
    template_path = Path(template_path)

    if not template_path.exists():
        return [f"Template file not found: {template_path}"]

    try:
        with open(template_path) as f:
            template = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        return [f"Failed to parse template: {e}"]

    if not isinstance(template, dict):
        return ["Template must be a JSON object"]

    for field in [
        "schema_version", "template_version", "source_experiment",
        "source_artifact", "generated_at", "total_corpus_questions",
        "instructions", "valid_human_categories", "proposals", "summary",
    ]:
        if field not in template:
            errors.append(f"Missing required field: {field}")

    if errors:
        return errors

    if template["schema_version"] != "1.0.0":
        errors.append(
            f"Unsupported schema_version: {template['schema_version']}"
        )

    proposals = template["proposals"]
    if not isinstance(proposals, list):
        errors.append("proposals must be an array")
        return errors

    seen_ids: set[str] = set()
    prev_qid = ""
    for i, p in enumerate(proposals):
        if not isinstance(p, dict):
            errors.append(f"proposals[{i}]: not a dict")
            continue

        qid = p.get("question_id", "")
        if not qid:
            errors.append(f"proposals[{i}]: missing question_id")
        elif qid in seen_ids:
            errors.append(f"proposals[{i}]: duplicate question_id {qid}")
        else:
            seen_ids.add(qid)

        if qid < prev_qid:
            errors.append(
                f"proposals[{i}]: not sorted by question_id "
                f"({qid} after {prev_qid})"
            )
        prev_qid = qid

        rid = p.get("result_id", "")
        if rid and qid and not rid.endswith(f"/{qid}"):
            errors.append(
                f"proposals[{i}]: result_id '{rid}' does not end "
                f"with '/{qid}'"
            )

        if p.get("human_category") is not None:
            errors.append(
                f"proposals[{i}] ({qid}): human_category must be null "
                f"in template, got {p['human_category']!r}"
            )

        for field in [
            "tier", "category", "question", "expected_answer",
            "proposed_category", "reasoning", "suggested_action", "evidence",
        ]:
            if field not in p:
                errors.append(f"proposals[{i}] ({qid}): missing {field}")

        evidence = p.get("evidence", {})
        if isinstance(evidence, dict):
            if "signals" not in evidence:
                errors.append(
                    f"proposals[{i}] ({qid}): evidence missing signals"
                )
            if "score_context" not in evidence:
                errors.append(
                    f"proposals[{i}] ({qid}): evidence missing score_context"
                )

    summary = template.get("summary", {})
    if isinstance(summary, dict):
        expected_total = len(proposals)
        if summary.get("total_proposals") != expected_total:
            errors.append(
                f"summary.total_proposals ({summary.get('total_proposals')}) "
                f"!= actual proposal count ({expected_total})"
            )

        expected_perfect = template.get("total_corpus_questions", 0) - len(proposals)
        if summary.get("questions_with_perfect_score") != expected_perfect:
            errors.append(
                f"summary.questions_with_perfect_score "
                f"({summary.get('questions_with_perfect_score')}) "
                f"!= expected ({expected_perfect})"
            )

        by_cat = summary.get("by_proposed_category", {})
        actual_by_cat: dict[str, int] = {}
        for p in proposals:
            cat = p.get("proposed_category", "")
            actual_by_cat[cat] = actual_by_cat.get(cat, 0) + 1
        if by_cat != actual_by_cat:
            errors.append(
                f"summary.by_proposed_category mismatch: "
                f"stated={by_cat}, actual={actual_by_cat}"
            )

        by_tier = summary.get("by_tier", {})
        actual_by_tier: dict[str, int] = {}
        for p in proposals:
            tier = str(p.get("tier", ""))
            actual_by_tier[tier] = actual_by_tier.get(tier, 0) + 1
        if by_tier != actual_by_tier:
            errors.append(
                f"summary.by_tier mismatch: "
                f"stated={by_tier}, actual={actual_by_tier}"
            )

        unresolved = summary.get("unresolved_count", -1)
        actual_unresolved = actual_by_cat.get("unresolved", 0)
        if unresolved != actual_unresolved:
            errors.append(
                f"summary.unresolved_count ({unresolved}) "
                f"!= actual ({actual_unresolved})"
            )

    if corpus_path:
        corpus_path = Path(corpus_path)
        if corpus_path.exists():
            with open(corpus_path) as f:
                corpus = json.load(f)
            corpus_ids = {
                q["id"]
                for q in corpus.get("questions", corpus if isinstance(corpus, list) else [])
            }
            for qid in seen_ids:
                if qid not in corpus_ids:
                    errors.append(
                        f"question_id {qid} not found in corpus"
                    )

    if schema_path:
        schema_path = Path(schema_path)
        if schema_path.exists():
            try:
                import jsonschema

                with open(schema_path) as f:
                    schema = json.load(f)
                jsonschema.validate(template, schema)
            except ImportError:
                pass
            except jsonschema.ValidationError as e:
                errors.append(f"Schema validation: {e.message}")

    return errors


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(
        description="Validate failure-adjudication template.",
    )
    parser.add_argument(
        "template",
        type=Path,
        help="Path to adjudication_template.json",
    )
    parser.add_argument(
        "--corpus",
        type=Path,
        default=None,
        help="Path to corpus.json for cross-reference check",
    )
    parser.add_argument(
        "--schema",
        type=Path,
        default=None,
        help="Path to adjudication_schema.json for schema validation",
    )
    args = parser.parse_args()

    errs = validate(
        args.template,
        corpus_path=args.corpus,
        schema_path=args.schema,
    )
    if errs:
        for e in errs:
            print(f"ERROR: {e}", file=sys.stderr)
        print(f"\nFAIL: {len(errs)} error(s) found.", file=sys.stderr)
        return 1

    with open(args.template) as f:
        tpl = json.load(f)
    summary = tpl.get("summary", {})
    print(
        f"PASS: {summary.get('total_proposals', '?')} proposals validated"
    )
    print(f"  Source: {tpl.get('source_experiment', '?')}")
    print(f"  Total corpus questions: {tpl.get('total_corpus_questions', '?')}")
    print(
        f"  Perfect score (excluded): "
        f"{summary.get('questions_with_perfect_score', '?')}"
    )
    print(f"  By proposed category: {summary.get('by_proposed_category', {})}")
    print(f"  By tier: {summary.get('by_tier', {})}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
