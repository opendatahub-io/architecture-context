# Task: Prepare Failure-Classification Adjudication Template

## Goal

Create a deterministic human-review bundle from existing analyzer-assisted
failure proposals without promoting any proposal to an authoritative result.

## Scope and controls

- Read `AGENTS.md`, `PLAN.md`, `agent-driver.md`, the architecture plan,
  `lib/failure_proposals.py`, `benchmark/analyzer-assisted-v1/proposal_schema.json`,
  and the existing raw/scored v1-ab artifacts.
- Generate a bounded, versioned review template containing proposal identity,
  direct evidence, proposed category/reasoning, and `human_category: null`.
- Preserve raw/scored artifacts and proposal semantics; do not infer labels,
  rewrite results, run evaluation, or modify generated architecture output.
- Include reviewer instructions and deterministic counts by proposed category.

## Acceptance criteria

- [x] Every template record maps to an existing result/proposal identity and has
  direct evidence or an explicit unresolved proposal.
- [x] The authoritative human category is null for every record and validation
  rejects non-null labels in the template.
- [x] Focused tests, proposal/benchmark validators, and `git diff --check` pass.
- [x] Record human adjudication and any promotion to authoritative classifications
  as external follow-up gates.

## Result

**Implemented** — 35-proposal adjudication template v0.1.0 from v1-ab scored
results.

### Template

| Metric | Value |
|--------|-------|
| Total corpus questions | 40 |
| Proposals (score < 1.0 on at least one tree) | 35 |
| Questions with perfect score (excluded) | 5 (INV-001, INV-010, FACT-003, FACT-006, FACT-007) |
| Proposed category | unresolved (all 35 — no telemetry signals in v1-ab) |
| Suggested action | manual-classify (all 35) |
| human_category | null (all 35) |

### By tier

| Tier | Proposals |
|------|-----------|
| 1 (Inventory) | 8 |
| 2 (Component Facts) | 7 |
| 3 (Integration) | 10 |
| 4 (Navigation) | 10 |

### Deliverables

| File | Purpose |
|------|---------|
| `benchmark/consumer-v1/adjudication_template.json` | 35-proposal template with `human_category: null` |
| `benchmark/consumer-v1/adjudication_schema.json` | JSON Schema 2020-12 for the template format |
| `benchmark/consumer-v1/validate_adjudication.py` | Deterministic validator with corpus cross-check |
| `tests/test_adjudication_template.py` | 44 focused tests |

### Validation results

| Check | Result |
|-------|--------|
| `python3 benchmark/consumer-v1/validate_adjudication.py adjudication_template.json --corpus corpus.json` | PASS: 35 proposals |
| `pytest tests/test_adjudication_template.py` | 44 passed |
| `python3 benchmark/analyzer-assisted-v1/validate_corpus.py` | PASS: 40 entries, 40 active |
| `python3 benchmark/consumer-v1/validate.py` | PASS: 40 questions |
| `git diff --check` | Clean |

### External adjudication gate

Human adjudication is required before any `human_category` value is set.
No proposal was promoted to an authoritative classification. All 35 proposals
are "unresolved" because the v1-ab evaluation predates context telemetry —
manual review of agent responses against expected answers is the only path
to classification.

## Status

Done — 2026-07-25 (template only; human adjudication remains an external gate).
