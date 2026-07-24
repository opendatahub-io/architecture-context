# Analyzer Category Completeness

**Status**: Complete (validated with no routing expansion, 2026-07-19)

## Goal

Expand conservative analyzer-only routing by teaching `src/arch-analyzer` to state
whether a structured fact category was completely evaluated, partially evaluated,
or not reliably evaluated. This allows a genuinely empty category to be
distinguished from an extraction gap without weakening the production preservation
and quality gates.

The first tranche evaluates three components selected from an earlier Opus run
because one or more high-value tables were empty. Historical zero mutation was only
a hypothesis selector; the later gate-passing reference and source audit were
allowed to reject it.

## Context

The accepted analyzer-only rollout selects 15 of 63 analyzer-sufficient components.
Its full-corpus production validation skipped 15 agents and retained 2,460/2,460
accepted structured rows for the treatment set. The policy currently requires all
four high-value categories to contain at least one row:

- Architecture Components
- Authentication
- Integration Points
- Internal Platform Dependencies

That rule is intentionally conservative, but it treats two different conditions as
equivalent:

1. The analyzer completed the relevant discovery and found no facts.
2. The analyzer did not cover enough of the repository to know whether facts exist.

The initial evaluation set and its gate-passing reference costs were:

| Component | Empty high-value categories | Accepted mutations | Reference cost | Agent time | Reads |
|-----------|-----------------------------|-------------------:|---------------:|-----------:|------:|
| `data-science-pipelines-operator` | Authentication | 3 | $1.0688 | 200.10s | 8 |
| `lm-evaluation-harness` | Authentication, Internal Dependencies | 4 | $1.0793 | 222.34s | 7 |
| `trainer` | Internal Dependencies | 0 | $0.7290 | 150.16s | 8 |
| **Total** | | **7** | **$2.8771** | **572.59s** | **23** |

These measurements come from the successful
`rhoai-next-20260718T215431Z` production run, whose required gates passed with 15
analyzer-only documents, 75 agent invocations, and a 47.11% wall-time reduction
from the one-hour reference.

Historical zero mutation is evidence for selecting an evaluation set, not proof
that a category is empty. The analyzer must establish completeness from the current
repository and its own extraction behavior.

## Scope

This plan covers:

- Per-category completeness in the analyzer JSON model.
- Evidence and limitations supporting a completeness claim.
- Markdown adaptation of category coverage for downstream agents.
- Conservative routing changes for complete empty categories.
- Regression classification and a bounded same-revision treatment matrix.

This plan does not change `PLATFORM.md` synthesis, diagrams, the Markdown component
contract, or insufficient-coverage fallback behavior.

## Model

Fact presence and extraction completeness are orthogonal. Do not encode them in a
single `populated` or `empty` state.

Each high-value category should expose a coverage record with at least:

| Field | Meaning |
|-------|---------|
| `status` | `complete`, `partial`, or `unknown` |
| `fact_count` | Number of normalized facts emitted for the category |
| `discovery_contract` | Versioned identifier for the checks required to claim completeness |
| `completed_checks` | Checks that ran successfully for this repository |
| `limitations` | Unsupported languages, unreadable inputs, parse failures, or skipped surfaces |
| `evidence` | Repository paths or extraction summaries supporting the result |

`complete` means the analyzer satisfied a documented, bounded discovery contract. It
does not mean that every possible runtime behavior in arbitrary source code was
proven absent. A parse failure, unsupported relevant source surface, truncated scan,
or skipped required check must downgrade the category to `partial` or `unknown`.

The schema must remain backward compatible. Analyzer JSON without category coverage
records is `unknown` and cannot gain analyzer-only eligibility.

## Discovery Contracts

The first implementation should define contracts only for Authentication and
Internal Platform Dependencies. Architecture Components and Integration Points keep
their existing populated-row requirement until separate contracts are designed.

### Authentication

The contract must enumerate the supported evidence surfaces used by the current
extractors, including applicable Kubernetes workload configuration, command-line
arguments, environment variables, secret/config references, ingress or proxy
configuration, and supported source-language authentication constructs.

An empty Authentication table may be marked complete only when every applicable
required check succeeds and no relevant unsupported source surface remains. Generic
absence of a keyword is not a completeness proof.

### Internal Platform Dependencies

The contract must enumerate supported service references, internal URLs and hosts,
workload configuration, platform component aliases, and supported source-language
client construction. Resolution must use the platform component map and existing
normalization rules.

An empty Internal Platform Dependencies table may be marked complete only when the
repository's applicable dependency surfaces were scanned successfully and every
resolved dependency was either emitted or explicitly classified as external.

## Initial Audit Matrix

Before changing routing, audit current source and analyzer output for five
same-revision components:

| Component | Role | Expected boundary |
|-----------|------|-------------------|
| `data-science-pipelines-operator` | Candidate | Authentication may be complete and empty |
| `lm-evaluation-harness` | Candidate | Authentication and Internal Dependencies may be complete and empty |
| `trainer` | Candidate | Internal Dependencies may be complete and empty |
| `trainer-operator` | Negative control | Authentication was empty statically but received four accepted corrections |
| `rhods-operator` | Negative control | Internal Dependencies was empty statically but received one accepted correction |

The candidate expectation must be rejected if source audit finds a missed fact. That
finding becomes extractor work; the policy must not be adjusted to force eligibility.
Both negative controls must remain agent-routed until the analyzer emits the facts
their accepted agents supplied or correctly reports incomplete coverage.

## Implementation Phases

### 1. Source Audit And Contract Definition

1. Review the empty categories in all five matrix components against the exact
   commits from the gate-passing `rhoai-next-20260718T215431Z` run.
2. Record which files and constructs determine presence or absence for each category.
3. Convert those findings into versioned, repository-independent discovery checks.
4. Classify unsupported or ambiguous surfaces explicitly rather than treating them
   as empty.

### 2. Analyzer Model And Instrumentation

1. Add backward-compatible category coverage types to the Go model and JSON schema.
2. Have extractors report completed checks, parse failures, and limitations.
3. Aggregate extractor results after product normalization, since internal dependency
   classification requires the platform component map.
4. Keep coverage deterministic and stable under repeated analysis of the same commit.

### 3. Markdown And Routing

1. Render concise coverage status and limitations in the existing Data Coverage
   section without adding placeholder facts to empty tables.
2. Update Python parsing to consume the typed JSON coverage record rather than infer
   completeness from prose.
3. Permit an empty Authentication or Internal Platform Dependencies category only
   when its status is `complete` under a recognized discovery contract.
4. Preserve the populated-row requirement for Architecture Components and Integration
   Points.
5. Preserve all existing partial, insufficient, preservation, structural, and
   synthesis-quality gates.

### 4. Classification And Tests

1. Add Go unit tests for complete-empty, complete-populated, partial, unknown,
   parse-failure, unsupported-language, and mixed-extractor cases.
2. Add renderer and schema compatibility tests for old and new analyzer JSON.
3. Add Python routing tests proving that only recognized complete-empty categories
   can satisfy eligibility.
4. Replay the accepted 90-component corpus classification and require zero false
   analyzer-only nominations against accepted structured corrections.
5. Report newly eligible components and projected agent, cost, read, token, and
   schedule savings separately from the existing 15-component treatment.

### 5. Bounded Treatment Matrix

Run the five-component audit matrix at the accepted source revisions. The three
candidates may route analyzer-only only if their audit and fresh coverage records
support it. The two negative controls must retain agents unless their previously
missing facts are now statically extracted.

Compare analyzer-only candidates directly with their accepted Opus documents by
structured rows. Compare controls for correct routing and analyzer preservation; do
not require exact agent prose or whole-document equality.

## Acceptance Criteria

- [x] Authentication and Internal Platform Dependencies have documented, versioned
      discovery contracts.
- [x] Coverage status is derived from completed analyzer checks and explicit
      limitations, not table emptiness, component names, or historical agent output.
- [x] Old analyzer JSON remains valid and defaults missing coverage to `unknown`.
- [x] Empty categories are not populated with synthetic rows or placeholder facts.
- [x] Parse failures and unsupported relevant surfaces cannot produce `complete`.
- [x] The five-component source audit is recorded with exact repository commits and
      evidence.
- [x] Corpus replay produces zero false analyzer-only nominations against accepted
      structured corrections.
- [x] Both negative controls retain safe routing unless their missing facts become
      statically available.
- [x] Every analyzer-only matrix document retains 100% of accepted structured rows
      with zero unexplained populated-cell conflicts.
- [x] All structural, synthesis, analyzer-preservation, and route-specific quality
      gates pass.
- [x] The matrix records agent count, wall time, cost, tools, reads, source files,
      tokens, and route decisions.
- [x] A full 90-component paid run is proposed only if the bounded matrix reveals a
      material expansion beyond the three initial candidates or another production
      question that the existing corpus replay cannot answer.

No audit candidate routed analyzer-only, so the analyzer-only matrix preservation
criterion had no treatment documents. All five evidence-gated audit documents
retained 100% of fresh analyzer structured rows with zero populated-cell conflicts.

## Decision Gates

Proceed with expanded routing only when all acceptance criteria pass. If a candidate
contains a source-backed fact missing from the analyzer, keep it agent-routed and
open a focused extractor task or bug. If a discovery contract cannot make a reliable
completeness statement for a category, retain `partial` or `unknown`; conservative
false negatives are preferable to false analyzer-only nominations.

The initial hypothetical gain was three additional skipped agents; the validated
gain is zero because the analyzer correctly rejected every candidate. The more
important outcome is a reusable completeness contract. The same mechanism can
support targeted extractor improvements across the remaining sufficient components,
where the accepted reference run recorded 113 Authentication and 104 Internal
Platform Dependency corrections.

## Related Evidence

- [Analyzer-only full-corpus production validation](../notes/analyzer-only-full-corpus-production-validation-2026-07-18.md)
- [Analyzer-only routing matrix](../notes/analyzer-only-routing-matrix-2026-07-18.md)
- [Category completeness validation](../notes/analyzer-category-completeness-validation-2026-07-19.md)
- [Completed analyzer-only routing task](../tasks/done/eliminate-redundant-sufficient-agent-passes.md)
- [Component analyzer migration](component-analyzer-migration.md)
