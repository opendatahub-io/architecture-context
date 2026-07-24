# Task: Approve Newly Eligible Components (Batch 2)

## Goal

Review and approve 2 components that became newly eligible for analyzer-only
routing after the static-analysis re-extraction: `ai4rag` and
`guardrails-detectors`. These were not in the prior component set and
appeared when the sufficient count grew from 68 to 70.

## Context

The platform-delegated authentication task re-ran
`uv run main.py static-analysis --platform=rhoai.next --force`, which
re-extracted all components. Two previously unseen components now show as
eligible:

- `ai4rag` — IBM component, all 3 high-value categories complete with 0
  limitations
- `guardrails-detectors` — Red Hat Data Services component, authentication
  has 1 fact and 1 limitation but passed the eligibility check

Current state: 57/90 approved, 60 eligible, 3 newly eligible (ai4rag,
guardrails-detectors, rhods-operator — rhods-operator is a permanent
residual and should NOT be approved).

## Target Components

| Component | Checkout | Auth | Integration | Internal Deps |
|-----------|----------|------|-------------|---------------|
| `ai4rag` | `/data/checkouts/IBM.next/ai4rag/` | complete, 0 facts, 0 lims | complete, 1 fact | complete, 0 facts |
| `guardrails-detectors` | `/data/checkouts/red-hat-data-services.next/guardrails-detectors/` | partial, 1 fact, 1 lim | complete, 0 facts | complete, 0 facts |

## Review Checklist

For each component:

1. Read `ANALYZER_ARCHITECTURE.md` — verify tables are populated or
   legitimately empty
2. Read `component-architecture.json` category_coverage — verify no hidden
   gaps
3. Briefly inspect source to confirm the component profile matches analyzer
   output (e.g., if auth is empty, confirm no inbound surfaces exist)
4. For complete-empty categories (status=complete, fact_count=0), verify the
   contract is valid (no limitations, completed checks present)
5. For `guardrails-detectors` specifically: determine what the 1
   authentication limitation is and whether it blocks eligibility

## Negative Controls

- Must NOT approve rhods-operator (permanent residual by design)
- Must NOT approve if any high-value category has an unresolved gap
- Must NOT modify analyzer code — this is a review-and-approve task only

## Acceptance Criteria

1. Each component has a documented disposition (approved or rejected with
   reason)
2. `uv run main.py check-eligibility --platform=rhoai.next` confirms
   updated approval count with zero regressions
3. Previously approved 57 components remain eligible+approved

## Likely Files

| File | Role |
|------|------|
| `lib/analyzer_only_approvals.json` | Add approvals (alphabetical order) |
| `/data/checkouts/IBM.next/ai4rag/ANALYZER_ARCHITECTURE.md` | Review |
| `/data/checkouts/IBM.next/ai4rag/component-architecture.json` | Review |
| `/data/checkouts/red-hat-data-services.next/guardrails-detectors/ANALYZER_ARCHITECTURE.md` | Review |
| `/data/checkouts/red-hat-data-services.next/guardrails-detectors/component-architecture.json` | Review |

## Status

Done (2026-07-23)

### Disposition

- **ai4rag**: Approved. All 3 high-value categories complete with 0 limitations.
  Authentication legitimately empty (pure Python library, no inbound surfaces,
  no web framework). Single integration point (AWS S3 via boto3) correctly captured.
- **guardrails-detectors**: Approved. Authentication limitation ("7 inbound runtime
  surfaces not fully accounted for") is non-blocking — the analyzer correctly found
  the blanket "no auth middleware detected" fact for the FastAPI app (confirmed by
  source inspection). Integration points and internal dependencies properly complete-empty.
- **rhods-operator**: Not approved (permanent residual by design).

### Results

- Approval count: 57 → 59
- Eligible: 60, Approved: 59, Newly eligible (unapproved): 1 (rhods-operator)
- Zero regressions — all 57 previously approved components remain eligible+approved
