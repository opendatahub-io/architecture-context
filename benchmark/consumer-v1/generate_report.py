#!/usr/bin/env python3
"""Generate a markdown report from scored evaluation results.

Produces report.md with:
  - Per-tier score tables (tree A vs tree B, paired deltas)
  - Per-consumer breakdowns
  - Flagged material regressions
  - Severe errors called out individually
  - Efficiency comparison (tokens, cost, latency)
  - Reproducibility metadata
"""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from io import StringIO
from pathlib import Path

TIER_NAMES = {
    1: "Inventory",
    2: "Component Facts",
    3: "Cross-Component Integration",
    4: "Navigation / Structure",
}

PRIMARY_SCOPE = "architecture"


def _pct(value: float | None) -> str:
    if value is None:
        return "N/A"
    return f"{value * 100:.1f}%"


def _delta(a: float | None, b: float | None) -> str:
    if a is None or b is None:
        return "N/A"
    d = b - a
    sign = "+" if d > 0 else ""
    return f"{sign}{d * 100:.1f}pp"


def _cost(value: float | None) -> str:
    if value is None:
        return "N/A"
    return f"${value:.4f}"


def _duration(seconds: float | None) -> str:
    if seconds is None:
        return "N/A"
    m, s = divmod(int(seconds), 60)
    h, m = divmod(m, 60)
    if h:
        return f"{h}h {m}m {s}s"
    if m:
        return f"{m}m {s}s"
    return f"{s}s"


def _tokens(value: int | None) -> str:
    if value is None or value == 0:
        return "N/A"
    if value >= 1_000_000:
        return f"{value / 1_000_000:.1f}M"
    if value >= 1_000:
        return f"{value / 1_000:.1f}K"
    return str(value)


def _primary_overall(tree_agg: dict) -> dict:
    """Return the primary architecture-scope aggregate with legacy fallback."""
    primary = tree_agg.get("primary_overall")
    if primary is not None:
        return primary
    return tree_agg.get("by_scope", {}).get(PRIMARY_SCOPE, {})


def _regression_issues(a_scores: dict, b_scores: dict) -> list[str]:
    a_exact = a_scores.get("exact_match", {}).get("passed", False)
    b_exact = b_scores.get("exact_match", {}).get("passed", False)
    a_cite = a_scores.get("source_citation", {}).get("passed", False)
    b_cite = b_scores.get("source_citation", {}).get("passed", False)
    a_gap = a_scores.get("gap_acknowledgment", {}).get("passed", False)
    b_gap = b_scores.get("gap_acknowledgment", {}).get("passed", False)

    issues = []
    if a_exact and not b_exact:
        issues.append("exact_match regressed (A:pass -> B:fail)")
    if a_cite and not b_cite:
        issues.append("source_citation regressed (A:pass -> B:fail)")
    if a_gap and not b_gap:
        issues.append("gap_acknowledgment regressed (A:pass -> B:fail)")
    return issues


def generate_report(scored_path: Path, output_path: Path | None = None) -> Path:
    """Generate report.md from scored-results.json."""
    with open(scored_path) as f:
        scored = json.load(f)

    if output_path is None:
        output_path = scored_path.parent / "report.md"

    out = StringIO()

    out.write("# Consumer Benchmark Evaluation Report\n\n")

    out.write("## Reproducibility Metadata\n\n")
    out.write("| Property | Value |\n")
    out.write("|----------|-------|\n")
    out.write(f"| Corpus version | {scored.get('corpus_version', 'N/A')} |\n")
    architecture_context = scored.get("architecture_context_version", "N/A")
    out.write(f"| Architecture context | `{architecture_context}` |\n")
    model = scored.get("model", "N/A")
    model_id = scored.get("model_id", "N/A")
    out.write(f"| Model | {model} (`{model_id}`) |\n")
    out.write(f"| Timestamp | {scored.get('timestamp', 'N/A')} |\n")
    out.write(f"| Git SHA | `{scored.get('git_sha', 'N/A')}` |\n")
    out.write(f"| Random seed | {scored.get('seed', 'N/A')} |\n")
    out.write(f"| Total questions | {scored.get('total_questions', 'N/A')} |\n")
    out.write(f"| Tree A | `{scored.get('tree_a_path', 'N/A')}` |\n")
    out.write(f"| Tree B | `{scored.get('tree_b_path', 'N/A')}` |\n")
    out.write("\n")

    # Overall summary
    agg = scored.get("aggregates", {})
    a_tree_agg = agg.get("tree_a", {})
    b_tree_agg = agg.get("tree_b", {})
    a_primary = _primary_overall(a_tree_agg)
    b_primary = _primary_overall(b_tree_agg)
    a_overall = a_tree_agg.get("overall", {})
    b_overall = b_tree_agg.get("overall", {})

    out.write("## Primary Architecture Summary\n\n")
    out.write("Architecture-scope rows are the primary quality metric.\n\n")
    out.write("| Metric | Tree A | Tree B | Delta |\n")
    out.write("|--------|--------|--------|-------|\n")
    for metric, label in [
        ("exact_match_rate", "Exact match"),
        ("source_citation_rate", "Source citation"),
        ("gap_acknowledgment_rate", "Gap acknowledgment"),
        ("average_score", "Composite score"),
    ]:
        a_val = a_primary.get(metric)
        b_val = b_primary.get(metric)
        out.write(
            f"| {label} | {_pct(a_val)} | {_pct(b_val)}"
            f" | {_delta(a_val, b_val)} |\n"
        )
    out.write("\n")

    out.write("## All-Question Summary\n\n")
    out.write("Includes non-primary full-repo diagnostic rows.\n\n")
    out.write("| Metric | Tree A | Tree B | Delta |\n")
    out.write("|--------|--------|--------|-------|\n")
    for metric, label in [
        ("exact_match_rate", "Exact match"),
        ("source_citation_rate", "Source citation"),
        ("gap_acknowledgment_rate", "Gap acknowledgment"),
        ("average_score", "Composite score"),
    ]:
        a_val = a_overall.get(metric)
        b_val = b_overall.get(metric)
        out.write(
            f"| {label} | {_pct(a_val)} | {_pct(b_val)}"
            f" | {_delta(a_val, b_val)} |\n"
        )
    out.write("\n")

    # Per-tier breakdown
    out.write("## Per-Tier Scores\n\n")
    out.write("| Tier | Metric | Tree A | Tree B | Delta |\n")
    out.write("|------|--------|--------|--------|-------|\n")

    a_tiers = agg.get("tree_a", {}).get("by_tier", {})
    b_tiers = agg.get("tree_b", {}).get("by_tier", {})
    all_tier_keys = sorted(set(list(a_tiers.keys()) + list(b_tiers.keys())))

    for tier_key in all_tier_keys:
        a_tier = a_tiers.get(tier_key, {})
        b_tier = b_tiers.get(tier_key, {})
        for metric, label in [
            ("exact_match_rate", "Exact match"),
            ("source_citation_rate", "Source citation"),
            ("average_score", "Composite"),
        ]:
            a_val = a_tier.get(metric)
            b_val = b_tier.get(metric)
            out.write(
                f"| {tier_key} | {label} | {_pct(a_val)} | {_pct(b_val)}"
                f" | {_delta(a_val, b_val)} |\n"
            )
    out.write("\n")

    # Per-consumer breakdown
    out.write("## Per-Consumer Scores\n\n")
    out.write("| Consumer | Metric | Tree A | Tree B | Delta |\n")
    out.write("|----------|--------|--------|--------|-------|\n")

    a_consumers = agg.get("tree_a", {}).get("by_consumer", {})
    b_consumers = agg.get("tree_b", {}).get("by_consumer", {})
    all_consumer_keys = sorted(set(list(a_consumers.keys()) + list(b_consumers.keys())))

    for consumer in all_consumer_keys:
        a_con = a_consumers.get(consumer, {})
        b_con = b_consumers.get(consumer, {})
        for metric, label in [
            ("exact_match_rate", "Exact match"),
            ("average_score", "Composite"),
        ]:
            a_val = a_con.get(metric)
            b_val = b_con.get(metric)
            out.write(
                f"| {consumer} | {label} | {_pct(a_val)} | {_pct(b_val)}"
                f" | {_delta(a_val, b_val)} |\n"
            )
    out.write("\n")

    # Per-scope breakdown
    out.write("## Per-Scope Scores\n\n")
    out.write("Architecture-only composite is the **primary quality metric**.\n\n")
    out.write("| Scope | Metric | Tree A | Tree B | Delta |\n")
    out.write("|-------|--------|--------|--------|-------|\n")

    a_scopes = agg.get("tree_a", {}).get("by_scope", {})
    b_scopes = agg.get("tree_b", {}).get("by_scope", {})
    all_scope_keys = sorted(set(list(a_scopes.keys()) + list(b_scopes.keys())))

    for scope_key in all_scope_keys:
        a_scope = a_scopes.get(scope_key, {})
        b_scope = b_scopes.get(scope_key, {})
        for metric, label in [
            ("exact_match_rate", "Exact match"),
            ("source_citation_rate", "Source citation"),
            ("average_score", "Composite"),
        ]:
            a_val = a_scope.get(metric)
            b_val = b_scope.get(metric)
            d = _delta(a_val, b_val)
            out.write(
                f"| {scope_key} | {label}"
                f" | {_pct(a_val)} | {_pct(b_val)}"
                f" | {d} |\n"
            )
    out.write("\n")

    # Regressions
    out.write("## Flagged Regressions\n\n")
    out.write(
        "Primary-scope questions where Tree B scores lower than Tree A on key"
        " metrics.\n\n"
    )

    regressions = []
    non_primary_regressions = []
    for sq in scored.get("results", []):
        a_scores = sq.get("tree_a", {}).get("scores", {})
        b_scores = sq.get("tree_b", {}).get("scores", {})
        if not a_scores or not b_scores:
            continue

        issues = _regression_issues(a_scores, b_scores)

        if issues:
            regression = {
                "id": sq["question_id"],
                "tier": sq["tier"],
                "scope": sq.get("required_scope", PRIMARY_SCOPE),
                "question": sq["question"],
                "issues": issues,
            }
            if regression["scope"] == PRIMARY_SCOPE:
                regressions.append(regression)
            else:
                non_primary_regressions.append(regression)

    if regressions:
        out.write("| ID | Tier | Issue | Question |\n")
        out.write("|----|------|-------|----------|\n")
        for r in regressions:
            tier_name = TIER_NAMES.get(r["tier"], str(r["tier"]))
            for issue in r["issues"]:
                q_short = r["question"][:60]
                if len(r["question"]) > 60:
                    q_short += "..."
                out.write(f"| {r['id']} | {tier_name} | {issue} | {q_short} |\n")
        out.write("\n")
    else:
        out.write("No regressions detected.\n\n")

    out.write("## Non-Primary Regression Diagnostics\n\n")
    out.write(
        "Full-repo or other non-primary rows are reported separately so they do"
        " not obscure architecture-tree quality.\n\n"
    )

    if non_primary_regressions:
        out.write("| ID | Scope | Tier | Issue | Question |\n")
        out.write("|----|-------|------|-------|----------|\n")
        for r in non_primary_regressions:
            tier_name = TIER_NAMES.get(r["tier"], str(r["tier"]))
            for issue in r["issues"]:
                q_short = r["question"][:60]
                if len(r["question"]) > 60:
                    q_short += "..."
                out.write(
                    f"| {r['id']} | {r['scope']} | {tier_name}"
                    f" | {issue} | {q_short} |\n"
                )
        out.write("\n")
    else:
        out.write("No non-primary regression diagnostics.\n\n")

    # Severe errors
    out.write("## Severe Errors\n\n")
    out.write("Agent sessions that failed entirely (no response produced).\n\n")

    errors = []
    for sq in scored.get("results", []):
        for tree_key in ("tree_a", "tree_b"):
            tree_data = sq.get(tree_key, {})
            if not tree_data.get("success", True):
                errors.append({
                    "id": sq["question_id"],
                    "tree": tree_key,
                    "error": tree_data.get("error", "unknown"),
                })

    if errors:
        out.write("| ID | Tree | Error |\n")
        out.write("|----|------|-------|\n")
        for e in errors:
            err_short = str(e["error"])[:80]
            out.write(f"| {e['id']} | {e['tree']} | {err_short} |\n")
        out.write("\n")
    else:
        out.write("No severe errors.\n\n")

    # Efficiency comparison
    out.write("## Efficiency Comparison\n\n")
    eff = scored.get("efficiency", {})
    eff_a = eff.get("tree_a", {})
    eff_b = eff.get("tree_b", {})

    out.write("| Metric | Tree A | Tree B |\n")
    out.write("|--------|--------|--------|\n")
    out.write(
        f"| Total duration | {_duration(eff_a.get('total_duration_seconds'))}"
        f" | {_duration(eff_b.get('total_duration_seconds'))} |\n"
    )
    out.write(
        f"| Mean duration / question | {_duration(eff_a.get('mean_duration_seconds'))}"
        f" | {_duration(eff_b.get('mean_duration_seconds'))} |\n"
    )
    out.write(
        f"| Total cost | {_cost(eff_a.get('total_cost_usd'))}"
        f" | {_cost(eff_b.get('total_cost_usd'))} |\n"
    )
    out.write(
        f"| Input tokens | {_tokens(eff_a.get('total_input_tokens'))}"
        f" | {_tokens(eff_b.get('total_input_tokens'))} |\n"
    )
    out.write(
        f"| Output tokens | {_tokens(eff_a.get('total_output_tokens'))}"
        f" | {_tokens(eff_b.get('total_output_tokens'))} |\n"
    )
    out.write(
        f"| Questions evaluated | {eff_a.get('questions_evaluated', 'N/A')}"
        f" | {eff_b.get('questions_evaluated', 'N/A')} |\n"
    )
    out.write("\n")

    # Per-question detail table
    out.write("## Per-Question Details\n\n")
    out.write(
        "| ID | Tier | Exact A | Exact B | Cite A | Cite B | Gap A | Gap B"
        " | Score A | Score B |\n"
    )
    out.write(
        "|----|------|---------|---------|--------|--------|-------|-------"
        "|---------|--------|\n"
    )

    for sq in scored.get("results", []):
        qid = sq["question_id"]
        tier = sq["tier"]
        a_s = sq.get("tree_a", {}).get("scores", {})
        b_s = sq.get("tree_b", {}).get("scores", {})

        def _check(scores, key):
            return "Y" if scores.get(key, {}).get("passed", False) else "N"

        def _score(scores):
            s = scores.get("score")
            return f"{s:.0%}" if s is not None else "N/A"

        out.write(
            f"| {qid} | {tier} "
            f"| {_check(a_s, 'exact_match')} | {_check(b_s, 'exact_match')} "
            f"| {_check(a_s, 'source_citation')} | {_check(b_s, 'source_citation')} "
            f"| {_check(a_s, 'gap_acknowledgment')}"
            f" | {_check(b_s, 'gap_acknowledgment')} "
            f"| {_score(a_s)} | {_score(b_s)} |\n"
        )
    out.write("\n")

    generated_at = datetime.now(UTC).isoformat().replace("+00:00", "Z")
    out.write(f"---\n\nGenerated: {generated_at}\n")

    with open(output_path, "w") as f:
        f.write(out.getvalue())

    print(f"Report written to {output_path}")
    if regressions:
        print(f"  {len(regressions)} regression(s) flagged")
    if errors:
        print(f"  {len(errors)} severe error(s)")
    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="Generate markdown report from scored evaluation results.",
    )
    parser.add_argument(
        "--scored-results",
        type=Path,
        required=True,
        help="Path to scored-results.json from score_results.py",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output path for report.md (default: alongside scored results)",
    )
    args = parser.parse_args()

    if not args.scored_results.exists():
        parser.error(f"Scored results not found: {args.scored_results}")

    generate_report(args.scored_results, args.output)


if __name__ == "__main__":
    main()
