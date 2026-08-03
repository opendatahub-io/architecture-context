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
| Total questions | 40 |
| Tree A | `/data/tree-a` |
| Tree B | `/data/tree-b` |

## Overall Summary

| Metric | Tree A | Tree B | Delta |
|--------|--------|--------|-------|
| Exact match | 15.0% | 15.0% | 0.0pp |
| Source citation | 55.0% | 50.0% | -5.0pp |
| Gap acknowledgment | 100.0% | 100.0% | 0.0pp |
| Composite score | 36.2% | 33.8% | -2.5pp |

## Per-Tier Scores

| Tier | Metric | Tree A | Tree B | Delta |
|------|--------|--------|--------|-------|
| tier_1 (Inventory) | Exact match | 30.0% | 30.0% | 0.0pp |
| tier_1 (Inventory) | Source citation | 30.0% | 20.0% | -10.0pp |
| tier_1 (Inventory) | Composite | 33.3% | 28.3% | -5.0pp |
| tier_2 (Component Facts) | Exact match | 30.0% | 30.0% | 0.0pp |
| tier_2 (Component Facts) | Source citation | 100.0% | 90.0% | -10.0pp |
| tier_2 (Component Facts) | Composite | 66.7% | 61.7% | -5.0pp |
| tier_3 (Cross-Component Integration) | Exact match | 0.0% | 0.0% | 0.0pp |
| tier_3 (Cross-Component Integration) | Source citation | 40.0% | 40.0% | 0.0pp |
| tier_3 (Cross-Component Integration) | Composite | 20.0% | 20.0% | 0.0pp |
| tier_4 (Navigation/Structure) | Exact match | 0.0% | 0.0% | 0.0pp |
| tier_4 (Navigation/Structure) | Source citation | 50.0% | 50.0% | 0.0pp |
| tier_4 (Navigation/Structure) | Composite | 25.0% | 25.0% | 0.0pp |

## Per-Consumer Scores

| Consumer | Metric | Tree A | Tree B | Delta |
|----------|--------|--------|--------|-------|
| architecture-review | Exact match | 15.4% | 15.4% | 0.0pp |
| architecture-review | Composite | 46.2% | 42.3% | -3.8pp |
| component-lookup | Exact match | 44.4% | 44.4% | 0.0pp |
| component-lookup | Composite | 48.1% | 42.6% | -5.6pp |
| platform-navigator | Exact match | 0.0% | 0.0% | 0.0pp |
| platform-navigator | Composite | 25.0% | 25.0% | 0.0pp |
| security-review | Exact match | 0.0% | 0.0% | 0.0pp |
| security-review | Composite | 55.6% | 55.6% | 0.0pp |
| strategy-review | Exact match | 0.0% | 0.0% | 0.0pp |
| strategy-review | Composite | 0.0% | 0.0% | 0.0pp |

## Flagged Regressions

Questions where Tree B scores lower than Tree A on key metrics.

No regressions detected.

## Severe Errors

Agent sessions that failed entirely (no response produced).

No severe errors.

## Efficiency Comparison

| Metric | Tree A | Tree B |
|--------|--------|--------|
| Total duration | 30m 11s | 30m 48s |
| Mean duration / question | 45s | 46s |
| Total cost | $13.9958 | $14.2573 |
| Input tokens | 27.4K | 45.6K |
| Output tokens | 74.2K | 73.6K |
| Questions evaluated | 40 | 40 |

## Per-Question Details

| ID | Tier | Exact A | Exact B | Cite A | Cite B | Gap A | Gap B | Score A | Score B |
|----|------|---------|---------|--------|--------|-------|-------|---------|--------|
| INV-001 | 1 | Y | Y | Y | Y | Y | Y | 100% | 100% |
| INV-002 | 1 | N | N | N | N | Y | Y | 0% | 0% |
| INV-003 | 1 | N | N | N | N | Y | Y | 0% | 0% |
| INV-004 | 1 | N | N | N | N | Y | Y | 0% | 0% |
| INV-005 | 1 | N | N | N | N | Y | Y | 0% | 0% |
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
| INTG-002 | 3 | N | N | N | N | Y | Y | 0% | 0% |
| INTG-003 | 3 | N | N | N | N | Y | Y | 0% | 0% |
| INTG-004 | 3 | N | N | N | N | Y | Y | 0% | 0% |
| INTG-005 | 3 | N | N | Y | Y | Y | Y | 50% | 50% |
| INTG-006 | 3 | N | N | N | N | Y | Y | 0% | 0% |
| INTG-007 | 3 | N | N | Y | Y | Y | Y | 50% | 50% |
| INTG-008 | 3 | N | N | N | N | Y | Y | 0% | 0% |
| INTG-009 | 3 | N | N | Y | Y | Y | Y | 50% | 50% |
| INTG-010 | 3 | N | N | N | N | Y | Y | 0% | 0% |
| NAV-001 | 4 | N | N | N | N | Y | Y | 0% | 0% |
| NAV-002 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-003 | 4 | N | N | N | N | Y | Y | 0% | 0% |
| NAV-004 | 4 | N | N | N | N | Y | Y | 0% | 0% |
| NAV-005 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-006 | 4 | N | N | N | N | Y | Y | 0% | 0% |
| NAV-007 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-008 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-009 | 4 | N | N | Y | Y | Y | Y | 50% | 50% |
| NAV-010 | 4 | N | N | N | N | Y | Y | 0% | 0% |

## Regression Analysis

The automated "Flagged Regressions" section above reports no regressions because the
report generator (`generate_report.py:164-188`) only checks `exact_match` and
`gap_acknowledgment` regressions. It does not check `source_citation`, which is where
both regressions occur. This is a **benchmark defect** in the report generator.

Two questions regressed (Tree B composite score < Tree A composite score):

### INV-008: How many CRDs does the RHOAI platform ship in total?

**Classification: synthesis difference** (scoring artifact, not a real regression)

| Metric | Tree A | Tree B |
|--------|--------|--------|
| Exact match | PASS | PASS |
| Source citation | PASS | FAIL |
| Composite | 100% | 50% |

**Evidence:** Both trees returned the correct answer (192 CRDs across 50+ API groups).
The expected canonical source is `PLATFORM.md` (corpus `source_file`). Tree A cited
`/data/tree-a/PLATFORM.md` in a "Sources" section, satisfying the basename check.
Tree B cited `diagrams/platform-maturity.mmd` inline — a valid source containing the
same data — but never mentioned `PLATFORM.md`, failing the basename citation check.

Both agents read `diagrams/platform-maturity.mmd`; Tree A also read `PLATFORM.md`
while Tree B did not. The answer is substantively correct and properly sourced in
both cases. The regression is a citation-format mismatch against the scorer's
expected source file, not a factual gap.

### FACT-004: Does model-registry define its own CRDs?

**Classification: navigation failure**

| Metric | Tree A | Tree B |
|--------|--------|--------|
| Exact match | FAIL | FAIL |
| Source citation | PASS | FAIL |
| Composite | 50% | 0% |

**Evidence:** The expected answer is "No — model-registry does not define CRDs; it
watches KServe InferenceService CRDs." The expected source is `model-registry.md`
(line 147), which contains an explicit empty CRD table and the note "_No CRDs are
defined by this component._"

Tree A read 4 files (`model-registry.md`, `model-registry-operator.md`, and both
`.json` files). It correctly distinguished the service (no CRDs) from the operator
(defines `ModelRegistry` CRD) and cited `model-registry.md`.

Tree B read only `model-registry-operator.md`. It concluded "Yes, model-registry
defines its own CRDs" by conflating the operator's CRDs with the service component.
It never opened `model-registry.md`, which exists identically in both trees (38,932
bytes, same content). This is agent non-determinism in file navigation — the
underlying document tree is identical, but the Tree B agent took a narrower search
path that missed the canonical source.

Neither tree achieved exact match because both gave nuanced answers distinguishing
model-registry from model-registry-operator, while the scorer checks for simple
"No" variant matches. Tree B's factual error (answering "Yes") is a genuine
navigation failure.

### Summary

| ID | Delta | Classification | Root Cause |
|----|-------|----------------|------------|
| INV-008 | -50pp | Synthesis difference | Cited diagram instead of PLATFORM.md; same facts |
| FACT-004 | -50pp | Navigation failure | Agent skipped model-registry.md, only read operator doc |

Overall: 38/40 questions tied, 2 regressions, 0 improvements. The -2.5pp composite
delta is driven entirely by these two source_citation failures. One is a scoring
artifact (INV-008), one is a genuine agent navigation failure (FACT-004). No
extraction gaps, missing components, or benchmark defects in the corpus itself were
found. The report generator has a defect: it should also flag source_citation
regressions.

### Cost Accounting

| Metric | Value |
|--------|-------|
| Tree A total cost | $13.9958 |
| Tree B total cost | $14.2573 |
| **Combined total** | **$28.2531** |
| Wall-clock time | ~7 min (concurrency=10) |
| Model | claude-opus-4-6 via Vertex AI |

---

Generated: 2026-07-20T23:02:38.159352Z
