# Consumer Benchmark Evaluation Report

## Reproducibility Metadata

| Property | Value |
|----------|-------|
| Corpus version | 1.0.0 |
| Architecture context | `0920cf3b8255cfd45584554de82b9812c1d01c08` |
| Model | opus (`claude-opus-4-6`) |
| Timestamp | 2026-07-20T23:02:36.462435+00:00 |
| Git SHA | `unknown` |
| Random seed | 42 |
| Total questions | 31 |
| Tree A | `/data/tree-a` |
| Tree B | `/data/tree-b` |

## Overall Summary

| Metric | Tree A | Tree B | Delta |
|--------|--------|--------|-------|
| Exact match | 19.4% | 19.4% | 0.0pp |
| Source citation | 74.2% | 67.7% | -6.5pp |
| Gap acknowledgment | 100.0% | 100.0% | 0.0pp |
| Composite score | 48.4% | 45.2% | -3.2pp |

## Per-Tier Scores

| Tier | Metric | Tree A | Tree B | Delta |
|------|--------|--------|--------|-------|
| tier_1 (Inventory) | Exact match | 30.0% | 30.0% | 0.0pp |
| tier_1 (Inventory) | Source citation | 40.0% | 30.0% | -10.0pp |
| tier_1 (Inventory) | Composite | 38.3% | 33.3% | -5.0pp |
| tier_2 (Component Facts) | Exact match | 30.0% | 30.0% | 0.0pp |
| tier_2 (Component Facts) | Source citation | 100.0% | 90.0% | -10.0pp |
| tier_2 (Component Facts) | Composite | 66.7% | 61.7% | -5.0pp |
| tier_3 (Cross-Component Integration) | Exact match | 0.0% | 0.0% | 0.0pp |
| tier_3 (Cross-Component Integration) | Source citation | 100.0% | 100.0% | 0.0pp |
| tier_3 (Cross-Component Integration) | Composite | 50.0% | 50.0% | 0.0pp |
| tier_4 (Navigation/Structure) | Exact match | 0.0% | 0.0% | 0.0pp |
| tier_4 (Navigation/Structure) | Source citation | 71.4% | 71.4% | 0.0pp |
| tier_4 (Navigation/Structure) | Composite | 35.7% | 35.7% | 0.0pp |

## Per-Consumer Scores

| Consumer | Metric | Tree A | Tree B | Delta |
|----------|--------|--------|--------|-------|
| architecture-review | Exact match | 20.0% | 20.0% | 0.0pp |
| architecture-review | Composite | 60.0% | 55.0% | -5.0pp |
| component-lookup | Exact match | 44.4% | 44.4% | 0.0pp |
| component-lookup | Composite | 48.1% | 42.6% | -5.6pp |
| platform-navigator | Exact match | 0.0% | 0.0% | 0.0pp |
| platform-navigator | Composite | 35.7% | 35.7% | 0.0pp |
| security-review | Exact match | 0.0% | 0.0% | 0.0pp |
| security-review | Composite | 55.6% | 55.6% | 0.0pp |
| strategy-review | Exact match | 0.0% | 0.0% | 0.0pp |
| strategy-review | Composite | 25.0% | 25.0% | 0.0pp |

## Per-Scope Scores

Architecture-only composite is the **primary quality metric**.

| Scope | Metric | Tree A | Tree B | Delta |
|-------|--------|--------|--------|-------|
| architecture | Exact match | 21.4% | 21.4% | 0.0pp |
| architecture | Source citation | 82.1% | 75.0% | -7.1pp |
| architecture | Composite | 53.6% | 50.0% | -3.6pp |
| full-repo | Exact match | 0.0% | 0.0% | 0.0pp |
| full-repo | Source citation | 0.0% | 0.0% | 0.0pp |
| full-repo | Composite | 0.0% | 0.0% | 0.0pp |

## Flagged Regressions

Questions where Tree B scores lower than Tree A on key metrics.

No regressions detected.

## Severe Errors

Agent sessions that failed entirely (no response produced).

No severe errors.

## Efficiency Comparison

| Metric | Tree A | Tree B |
|--------|--------|--------|
| Total duration | 21m 6s | 20m 59s |
| Mean duration / question | 40s | 40s |
| Total cost | $9.3966 | $9.2503 |
| Input tokens | 17.7K | 45.5K |
| Output tokens | 49.9K | 46.8K |
| Questions evaluated | 31 | 31 |

## Per-Question Details

| ID | Tier | Exact A | Exact B | Cite A | Cite B | Gap A | Gap B | Score A | Score B |
|----|------|---------|---------|--------|--------|-------|-------|---------|--------|
| INV-001 | 1 | Y | Y | Y | Y | Y | Y | 100% | 100% |
| INV-002 | 1 | N | N | N | N | Y | Y | 0% | 0% |
| INV-003 | 1 | N | N | N | N | Y | Y | 0% | 0% |
| INV-004 | 1 | N | N | N | N | Y | Y | 0% | 0% |
| INV-005 | 1 | N | N | Y | Y | Y | Y | 50% | 50% |
| INV-006 | 1 | N | N | N | N | Y | Y | 33% | 33% |
| INV-007 | 1 | N | N | N | N | Y | Y | 0% | 0% |
| INV-008 | 1 | Y | Y | Y | N | Y | Y | 100% | 50% |
| INV-009 | 1 | N | N | N | N | Y | Y | 0% | 0% |
| INV-010 | 1 | Y | Y | Y | Y | Y | Y | 100% | 100% |
| FACT-001 | 2 | N | N | Y | Y | Y | Y | 50% | 50% |
| FACT-002 | 2 | N | N | Y | Y | Y | Y | 50% | 50% |
| FACT-003 | 2 | Y | Y | Y | Y | Y | Y | 100% | 100% |
| FACT-004 | 2 | N | N | Y | N | Y | Y | 50% | 0% |
| FACT-005 | 2 | N | N | Y | Y | Y | Y | 50% | 50% |
| FACT-006 | 2 | Y | Y | Y | Y | Y | Y | 100% | 100% |
| FACT-007 | 2 | Y | Y | Y | Y | Y | Y | 100% | 100% |
| FACT-008 | 2 | N | N | Y | Y | Y | Y | 67% | 67% |
| FACT-009 | 2 | N | N | Y | Y | Y | Y | 50% | 50% |
| FACT-010 | 2 | N | N | Y | Y | Y | Y | 50% | 50% |
| INTG-001 | 3 | N | N | Y | Y | Y | Y | 50% | 50% |
| INTG-005 | 3 | N | N | Y | Y | Y | Y | 50% | 50% |
| INTG-007 | 3 | N | N | Y | Y | Y | Y | 50% | 50% |
| INTG-009 | 3 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-001 | 4 | N | N | N | N | Y | Y | 0% | 0% |
| NAV-002 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-004 | 4 | N | N | N | N | Y | Y | 0% | 0% |
| NAV-005 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-007 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-008 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-009 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |

---

Generated: 2026-07-24T19:44:40.454614Z
