#!/usr/bin/env python3
"""Score raw evaluation results against the benchmark corpus ground truth.

Computes three deterministic checks per question-response pair:
  1. Exact match: response contains expected answer or any acceptable variant
     (case-insensitive substring).
  2. Source citation: response cites the source_file path.
  3. Gap acknowledgment: for not_documented_expected questions, response
     explicitly states the information is not documented.

Writes scored-results.json with per-question scores and per-tree aggregates
by tier and consumer.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


GAP_PHRASES = [
    "not documented",
    "not found in",
    "no documentation",
    "not present in the documents",
    "does not document",
    "is not documented",
    "not available in the",
    "no architecture doc",
    "not covered in",
    "not included in",
    "absent from",
    "no information about",
    "does not have its own architecture",
    "not listed in",
]

FABRICATION_SIGNALS = [
    "the documentation shows",
    "according to the docs",
    "the document states",
    "as described in",
    "is documented at",
]


def normalize(text: str) -> str:
    """Lowercase and collapse whitespace for substring matching."""
    return re.sub(r"\s+", " ", text.lower().strip())


def check_exact_match(response: str, question: dict) -> dict:
    """Check if response contains expected answer or acceptable variants."""
    resp_norm = normalize(response)
    expected = question["expected_answer"]
    variants = question.get("acceptable_variants", [])

    expected_match = normalize(expected) in resp_norm
    variant_matches = [v for v in variants if normalize(v) in resp_norm]

    return {
        "passed": expected_match or len(variant_matches) > 0,
        "expected_match": expected_match,
        "variant_matches": variant_matches,
    }


def check_source_citation(response: str, question: dict) -> dict:
    """Check if response cites the source file path."""
    source_file = question.get("source_file", "")
    if not source_file:
        return {"passed": False, "reason": "no source_file in question"}

    resp_lower = response.lower()
    source_lower = source_file.lower()

    full_cite = source_lower in resp_lower

    basename = Path(source_file).name.lower()
    basename_cite = basename in resp_lower if basename else False

    stem = Path(source_file).stem.lower()
    stem_cite = stem in resp_lower if stem and len(stem) > 3 else False

    return {
        "passed": full_cite or basename_cite,
        "full_path_cited": full_cite,
        "basename_cited": basename_cite,
        "stem_cited": stem_cite,
    }


def check_gap_acknowledgment(response: str, question: dict) -> dict:
    """For not_documented_expected questions, check honest gap handling."""
    if not question.get("not_documented_expected", False):
        return {"passed": True, "applicable": False}

    resp_lower = response.lower()

    gap_found = any(phrase in resp_lower for phrase in GAP_PHRASES)
    matched_phrases = [p for p in GAP_PHRASES if p in resp_lower]

    fabrication_found = any(phrase in resp_lower for phrase in FABRICATION_SIGNALS)
    fabrication_matches = [p for p in FABRICATION_SIGNALS if p in resp_lower]

    passed = gap_found and not fabrication_found

    return {
        "passed": passed,
        "applicable": True,
        "gap_acknowledged": gap_found,
        "gap_phrases_found": matched_phrases,
        "fabrication_detected": fabrication_found,
        "fabrication_phrases_found": fabrication_matches,
    }


def score_response(response: str, question: dict) -> dict:
    """Score a single response against its question's ground truth."""
    exact = check_exact_match(response, question)
    citation = check_source_citation(response, question)
    gap = check_gap_acknowledgment(response, question)

    gap_applicable = gap.get("applicable", True)
    checks_total = 3 if gap_applicable else 2
    checks_passed = sum([exact["passed"], citation["passed"]])
    if gap_applicable:
        checks_passed += gap["passed"]

    return {
        "exact_match": exact,
        "source_citation": citation,
        "gap_acknowledgment": gap,
        "checks_passed": checks_passed,
        "checks_total": checks_total,
        "score": round(checks_passed / checks_total, 4) if checks_total > 0 else 1.0,
    }


def compute_aggregates(scored_questions: list[dict], tree_key: str) -> dict:
    """Compute per-tier, per-consumer, and per-scope aggregates for one tree."""
    by_tier: dict[int, list] = {}
    by_consumer: dict[str, list] = {}
    by_scope: dict[str, list] = {}

    for sq in scored_questions:
        tree_data = sq.get(tree_key, {})
        scores = tree_data.get("scores", {})
        if not scores:
            continue
        tier = sq["tier"]
        consumer = sq["consumer"]
        scope = sq.get("required_scope", "unknown")
        by_tier.setdefault(tier, []).append(scores)
        by_consumer.setdefault(consumer, []).append(scores)
        by_scope.setdefault(scope, []).append(scores)

    def _agg(score_list: list[dict]) -> dict:
        n = len(score_list)
        if n == 0:
            return {"count": 0}
        exact = sum(1 for s in score_list if s["exact_match"]["passed"])
        citation = sum(1 for s in score_list if s["source_citation"]["passed"])
        gap_applicable = [s for s in score_list if s["gap_acknowledgment"].get("applicable", True)]
        gap_passed = sum(1 for s in gap_applicable if s["gap_acknowledgment"]["passed"])
        avg_score = sum(s["score"] for s in score_list) / n

        return {
            "count": n,
            "exact_match_rate": round(exact / n, 4),
            "source_citation_rate": round(citation / n, 4),
            "gap_acknowledgment_rate": (
                round(gap_passed / len(gap_applicable), 4) if gap_applicable else None
            ),
            "average_score": round(avg_score, 4),
        }

    tier_names = {1: "Inventory", 2: "Component Facts", 3: "Cross-Component Integration", 4: "Navigation/Structure"}
    return {
        "by_tier": {
            f"tier_{t} ({tier_names.get(t, '')})": _agg(scores)
            for t, scores in sorted(by_tier.items())
        },
        "by_consumer": {
            consumer: _agg(scores)
            for consumer, scores in sorted(by_consumer.items())
        },
        "by_scope": {
            scope: _agg(scores)
            for scope, scores in sorted(by_scope.items())
        },
        "overall": _agg([
            sq[tree_key]["scores"]
            for sq in scored_questions
            if sq.get(tree_key, {}).get("scores")
        ]),
    }


def compute_efficiency(scored_questions: list[dict], tree_key: str) -> dict:
    """Aggregate efficiency metrics for one tree."""
    durations = []
    costs = []
    token_totals = {"input": 0, "output": 0}

    for sq in scored_questions:
        tree_data = sq.get(tree_key, {})
        if not tree_data:
            continue
        telemetry = tree_data.get("telemetry", {})
        dur = tree_data.get("duration_seconds")
        if dur is not None:
            durations.append(dur)
        cost = telemetry.get("total_cost_usd")
        if cost is not None:
            costs.append(cost)
        usage = telemetry.get("usage", {})
        token_totals["input"] += usage.get("input_tokens", 0)
        token_totals["output"] += usage.get("output_tokens", 0)

    return {
        "total_duration_seconds": round(sum(durations), 2) if durations else None,
        "mean_duration_seconds": round(sum(durations) / len(durations), 2) if durations else None,
        "total_cost_usd": round(sum(costs), 4) if costs else None,
        "total_input_tokens": token_totals["input"],
        "total_output_tokens": token_totals["output"],
        "questions_evaluated": len(durations),
    }


def score_results(results_path: Path, corpus_path: Path, output_path: Path | None = None) -> Path:
    """Score raw results and write scored-results.json."""
    with open(results_path) as f:
        raw = json.load(f)
    with open(corpus_path) as f:
        corpus = json.load(f)

    questions_by_id = {q["id"]: q for q in corpus["questions"]}

    scored_questions = []
    for entry in raw["results"]:
        qid = entry["question_id"]
        question = questions_by_id.get(qid)
        if question is None:
            print(f"WARNING: question {qid} not found in corpus, skipping", file=sys.stderr)
            continue

        scored = {
            "question_id": qid,
            "tier": entry["tier"],
            "consumer": entry["consumer"],
            "question": entry["question"],
            "expected_answer": entry["expected_answer"],
            "not_documented_expected": entry["not_documented_expected"],
            "required_scope": question.get("required_scope", "unknown"),
            "presentation_order": entry.get("presentation_order"),
        }

        for tree_key in ("tree_a", "tree_b"):
            tree_data = entry.get(tree_key, {})
            if not tree_data:
                scored[tree_key] = {"success": False, "scores": {}}
                continue

            response = tree_data.get("response", "")
            scores = score_response(response, question)

            scored[tree_key] = {
                "success": tree_data.get("success", False),
                "response_length": len(response),
                "duration_seconds": tree_data.get("duration_seconds"),
                "telemetry": tree_data.get("telemetry", {}),
                "scores": scores,
            }

        scored_questions.append(scored)

    scored_output = {
        "corpus_version": raw.get("corpus_version"),
        "architecture_context_version": raw.get("architecture_context_version"),
        "model": raw.get("model"),
        "model_id": raw.get("model_id"),
        "timestamp": raw.get("timestamp"),
        "git_sha": raw.get("git_sha"),
        "seed": raw.get("seed"),
        "tree_a_path": raw.get("tree_a_path"),
        "tree_b_path": raw.get("tree_b_path"),
        "total_questions": len(scored_questions),
        "aggregates": {
            "tree_a": compute_aggregates(scored_questions, "tree_a"),
            "tree_b": compute_aggregates(scored_questions, "tree_b"),
        },
        "efficiency": {
            "tree_a": compute_efficiency(scored_questions, "tree_a"),
            "tree_b": compute_efficiency(scored_questions, "tree_b"),
        },
        "results": scored_questions,
    }

    if output_path is None:
        output_path = results_path.parent / "scored-results.json"

    with open(output_path, "w") as f:
        json.dump(scored_output, f, indent=2)

    tree_a_agg = scored_output["aggregates"]["tree_a"]["overall"]
    tree_b_agg = scored_output["aggregates"]["tree_b"]["overall"]
    print(f"Scored {len(scored_questions)} questions")
    print(f"  Tree A overall: {tree_a_agg.get('average_score', 'N/A')}")
    print(f"  Tree B overall: {tree_b_agg.get('average_score', 'N/A')}")
    print(f"Wrote {output_path}")
    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="Score raw evaluation results against corpus ground truth.",
    )
    parser.add_argument(
        "--results",
        type=Path,
        required=True,
        help="Path to raw-results.json from run_evaluation.py",
    )
    parser.add_argument(
        "--corpus",
        type=Path,
        default=Path(__file__).parent / "corpus.json",
        help="Path to corpus.json (default: %(default)s)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output path for scored-results.json (default: alongside raw results)",
    )
    args = parser.parse_args()

    if not args.results.exists():
        parser.error(f"Results not found: {args.results}")
    if not args.corpus.exists():
        parser.error(f"Corpus not found: {args.corpus}")

    score_results(args.results, args.corpus, args.output)


if __name__ == "__main__":
    main()
