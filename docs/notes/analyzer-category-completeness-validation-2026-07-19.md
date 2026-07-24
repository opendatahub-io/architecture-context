# Analyzer Category Completeness Validation, 2026-07-19

## Decision

The versioned Authentication and Internal Platform Dependencies completeness
contracts are implemented and safe to retain, but they do not expand analyzer-only
routing in the first five-component tranche. Every historical candidate has either
a source-backed missing fact or an unresolved relevant source surface. All five
components remain evidence-gated.

This is a useful negative result. The implementation distinguishes a proven bounded
empty category from an extraction gap and rejected historical zero-mutation evidence
when current source and accepted output contradicted it.

## Reference

The accepted reference is the gate-passing
`tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z` run. Its required gates
passed with 15 analyzer-only documents, 75 agent invocations, and a 47.11% workflow
wall-time reduction from the one-hour reference.

The fresh analyzer replay is
`tmp/architecture-corpus-runs/rhoai-next-category-completeness-final-20260719T005100Z`.
It contains all 90 JSON and Markdown analyzer snapshots plus the eligibility and
corpus-comparison reports.

## Source Audit

| Component | Commit | Coverage result | Evidence and decision |
|-----------|--------|-----------------|-----------------------|
| `data-science-pipelines-operator` | `ab30578b3e674c26ff759edd1ddcc0e8734dfeee` | Authentication `partial` | Five inbound runtime surfaces include controller health/metrics endpoints at `main.go:320` and `main.go:324`; the accepted agent added three structured rows. Keep the agent. |
| `lm-evaluation-harness` | `00f38414949e23e47ca4a38bef1696a722fd1d8f` | Authentication `partial`; Internal Dependencies `partial` | The analyzer found five credential references, including `HF_TOKEN`, `ANTHROPIC_API_KEY`, `WATSONX_API_KEY`, and `OPENAI_API_KEY`, plus Python header constructions. The accepted agent added four Authentication rows. Shell/C++ runtime utilities leave the dependency absence contract incomplete. Keep the agent. |
| `trainer` | `7906eeacd135f9847cb4d6aaeaa9fc4a25bf7d52` | Internal Dependencies `partial` | Runtime source/config references JobSet, Volcano, Kubeflow, Gateway API, and scheduler APIs. Historical zero mutation is not proof of absence. Keep the agent until these relationships are emitted or classified. |
| `trainer-operator` | `28fbb2b9a4fc4dcbd9a4f52b0920e1935ab0c24f` | Authentication `partial` | Five inbound metrics/health surfaces remain unaccounted; the accepted agent added three structured rows. The statically emitted platform utility dependency does not resolve Authentication. Keep the agent. |
| `rhods-operator` | `e453f0a67fcb67982fa9522de90278e76990c194` | Authentication and Internal Dependencies `partial` | Eight inbound service/health/webhook surfaces and many platform component/API aliases remain unresolved. The latest accepted run made no structured mutation, but the source evidence prevents a complete-empty claim. Keep the agent. |

The checkouts were clean at those commits except for untracked analyzer, generated
Markdown, and extracted schema artifacts produced by the workflow.

## Corpus Replay

The fresh 90-component classifier reported:

| Measure | Result |
|---------|-------:|
| Analyzer-sufficient components | 63 |
| Existing analyzer-only nominations | 15 |
| Newly eligible components | 0 |
| False nominations | 0 |
| Zero structured-mutation components | 20 |
| Zero-mutation recall | 75.00% |

The fresh-analyzer-to-accepted-document comparison also passed every required gate:

- 8,166/8,171 analyzer identities retained unchanged (99.94%).
- All 16 analyzer-to-final conflicts were accepted; none were unexplained.
- No analyzer rows were unexplained or missing.
- Structural and synthesis quality passed for 90/90 documents.

Each of the five audit documents retained 100% of fresh analyzer structured rows
with zero populated-cell conflicts.

## Matrix Telemetry

Because fresh routing kept all five components evidence-gated, the accepted
same-revision run already supplies the required treatment telemetry. Repeating the
paid agents would not test a new route.

| Measure | Five-component matrix |
|---------|----------------------:|
| Route decisions | 5 evidence-gated, 0 analyzer-only |
| Agent invocations | 5 |
| Summed agent time | 944.34s |
| Longest component time | 222.34s |
| Cost | $4.7654 |
| Tool calls | 81 |
| Read calls | 39 |
| Source files | 20 |
| Input tokens | 20,485 |
| Cache-creation input tokens | 266,878 |
| Cache-read input tokens | 3,764,119 |
| Output tokens | 44,396 |

## Outcome

Keep the category coverage model and conservative routing support. Do not expand
production analyzer-only routing from this tranche, and do not run another paid
90-component workflow. Future expansion should start with focused extractors for the
source-backed Authentication and platform dependency signals found here, then replay
the same zero-false-nomination gate.
