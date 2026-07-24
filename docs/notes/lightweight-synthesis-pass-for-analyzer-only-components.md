# Optional LLM Synthesis Enrichment for Analyzer-Only Components

**Status**: Future exploration
**Date**: 2026-07-19

## Idea

The 34 analyzer-only components receive deterministic Purpose, Data Flows, and
Architectural Analysis prose from the `arch-analyzer` renderer. The corpus harness
enforces synthesis length and quality for these documents. The question is whether an
optional LLM synthesis pass over the analyzer output could improve the freeform
sections beyond what the deterministic renderer produces, particularly for
downstream agents that use architecture-context as a platform knowledge store.

The analyzer output provides structured facts with source evidence but has bounded
coverage -- sufficiency is explicit and can still contain partial coverage and
documented limitations. Any synthesis pass must treat the analyzer output as a
bounded structural map, not a complete inventory.

## Expected Shape

### Option A: Analyzer-only LLM synthesis (no repo access)

1. Feed the agent `ANALYZER_ARCHITECTURE.md` only -- no repository access.
2. Ask it to rewrite Purpose, Data Flows, and Architectural Analysis.
3. Preserve all structured tables via the existing `lib/architecture_merge.py` path.
4. Target ~30-60 seconds and minimal tokens per component.

The rhods-operator audit (below) suggests this option would improve Role 1 content
(prose restatement) marginally over the deterministic renderer, but is unlikely to
produce meaningful Role 3 content (architectural reasoning) because it cannot
observe code patterns. It may also hallucinate causal connections between
co-located facts. This option should be tested first; stop here if it does not
measurably improve downstream task performance over the current deterministic
renderer.

### Option B: Analyzer-as-index for targeted repo reads

Use the analyzer output as a structural map that tells the agent *where to look*
rather than *what to discover*. The analyzer JSON contains source evidence with file
paths and line numbers for every extracted fact. Instead of broad exploration, the
agent would:

1. Read `ANALYZER_ARCHITECTURE.md` to understand the structural landscape.
2. Identify patterns worth explaining from the structured facts -- e.g., multiple
   controllers watching the same GVK, a webhook intercepting creates on a CRD that
   another controller reconciles, a service chain visible in the ingress/auth tables.
3. Read 3-5 specific source files at the line ranges cited in the analyzer evidence
   to understand the *why* behind the structural *what*.
4. Write Purpose, Data Flows, and Architectural Analysis informed by both the
   structural map and targeted source context.

This reintroduces repository reads and variable agent exploration. It is not
analyzer-only and must not be part of the analyzer-only critical path. It should be
an optional enrichment phase with separate telemetry and routing identity. Only
consider Option B if Option A demonstrates measurable downstream improvement first.

Estimated cost at 34 components:

- Option A: ~17-34 summed agent-minutes.
- Option B: ~34-51 summed agent-minutes.
- Current 34 analyzer-only approvals avoid ~69.7 summed agent-minutes.
- These passes would give back approximately 24-73% of the saved agent work before
  accounting for startup variance.

## Motivation

Architecture-context is consumed by agents working on RFE review, strategy,
documentation, security, and bug triage. The structured facts answer "what does this
component expose?" but the synthesis sections answer "what is this component for and
how does it fit?" -- the latter aids semantic reasoning about cross-component
behavior and integration.

## Prior Evidence

- The sufficient-path A/B reduced wall time from 541s to 285s while preserving
  structured recall. The copy-and-edit variant hit 239s including gap work.
- Synthesis-only against pre-extracted facts should be substantially cheaper than
  either treatment since no repository reads or gap passes are involved.
- The `arch-query` design doc identifies token reduction and structured grounding as
  primary consumer benefits; synthesis prose complements that by providing the
  semantic framing that structured tables alone do not carry.

## Benchmarking Approach

The benchmark must compare against the current deterministic renderer output, not
against absent prose. Legacy agent-generated documents contain known unsupported and
corrected claims and should be a comparison arm, not the baseline truth.

Required comparison arms:

1. **Current deterministic renderer** -- the control. This is what analyzer-only
   components produce today.
2. **Analyzer-only LLM synthesis** (Option A) -- LLM rewrites synthesis sections
   from analyzer Markdown only, no repo access.
3. **Targeted-source LLM synthesis** (Option B) -- LLM rewrites synthesis sections
   using analyzer Markdown plus bounded repo reads at cited evidence locations.
4. **Legacy agent prose** -- the historical full-exploration agent output, included
   as a reference arm but not treated as ground truth.

Scoring method:

1. Score all claims in each arm against source evidence and existing adjudications
   first (factual accuracy).
2. Then measure downstream utility: when a consuming agent uses the document to
   answer a cross-component question, which arm produces equivalent or better
   answers?
3. Use a blind judge pass (structured rubric, not open-ended) over a sample of 5-10
   components spanning Go operators, Python services, Rust services, and frontend
   monorepos.

## Sample Audit: rhods-operator Freeform Sections

An audit of `architecture/rhoai.next/rhods-operator.md` classified every claim in
the three freeform sections by whether it is derivable from the structured tables in
the same document. The sections serve three distinct roles with different derivability:

### Role 1: Restating structured facts as prose (low unique value)

The Purpose **Short** sentence and parts of the **Detailed** paragraph restate facts
already present in the CRDs, Architecture Components, and Configuration tables. For
example, "manages the full lifecycle ... through two primary Custom Resources:
DSCInitialization and DataScienceCluster" is directly visible in the CRDs table. The
16+ component controllers, cloud manager controllers (AWS, Azure, CoreWeave), and
RELATED_IMAGE_* injection are all enumerated in structured tables.

Approximately 60% of the Purpose section is restatable from tables alone. The
deterministic renderer already produces this content; an LLM rewrite adds marginal
value here.

### Role 2: Connecting structured facts into sequences (medium unique value)

The Data Flows section documents three step-by-step flows:

- Client request through Gateway ingress (Route → Envoy → kube-auth-proxy → OAuth → backend)
- Component deployment lifecycle (DSC CR → registry → component CR → kustomize → K8s API)
- Monitoring data collection (pods → OTel → Tempo → Prometheus → Thanos)

Every individual endpoint, port, protocol, and auth mechanism appears somewhere in
the Services, Ingress, Authentication, or Integration Points tables. The unique
value is the **ordering and causal connections** between those facts -- how they
compose into end-to-end flows. The structured tables list pieces; the Data Flows
section explains which piece hands off to which, and why.

An LLM working from analyzer output could infer reasonable flows from the
service/ingress/auth tables, but might miss non-obvious handoff details (e.g., the
Lua filter performing token forwarding and cookie stripping between auth proxy and
backends). Without source access, it may also fabricate connections between
co-located facts.

### Role 3: Architectural reasoning and design patterns (high unique value)

The Architectural Analysis section describes five patterns:

| Pattern | In structured tables? |
|---------|-----------------------|
| Registry-based ComponentHandler interface | No |
| Multi-layer ingress architecture rationale (why Envoy + EnvoyFilter + kube-auth-proxy) | No -- tables list the components, not why they are composed this way |
| Dual-mode operation (DSC mode vs Platform CR mode) | No |
| Dynamic resource ownership and GC patterns | No |
| Webhook complexity analysis (hardware profile merge-vs-replace semantics) | No -- webhook table lists names/types but not design reasoning |

Approximately 80-90% of the Architectural Analysis is not derivable from structured
tables. These are insights about code organization, design decisions, and
cross-cutting concerns that require understanding source patterns rather than
enumerating deployable artifacts.

### Implications for Benchmarking

The three roles should be scored separately in any evaluation:

- **Role 1** (prose restatement): the deterministic renderer already handles this.
  An LLM rewrite is unlikely to add measurable value.
- **Role 2** (flow sequencing): expect reasonable but potentially shallower results
  from Option A. Option B could improve here by reading the specific handoff code.
  Risk of hallucinated connections without source access.
- **Role 3** (architectural reasoning): expect the largest quality gap from Option A.
  An LLM can identify what components exist from the tables, but cannot reliably
  infer why they are composed a particular way or what code patterns govern their
  interaction. Option B is the only path likely to produce meaningful Role 3 content.

The evaluation rubric should weight Role 3 content higher than Role 1, since
restating structured facts adds little value while architectural reasoning is the
content most likely to aid downstream semantic understanding.

## Implementation Constraints

Any eventual implementation must:

- Preserve structured tables using the existing `lib/architecture_merge.py` path.
- Cache output by analyzer JSON digest and repository revision.
- Fall back to deterministic Markdown on failure.
- Run outside the required architecture-generation critical path.
- Prohibit unsupported causal or design-rationale claims that lack source evidence.
- Require measurable downstream improvement before Option B is considered.

## Open Questions

- Does Option A improve downstream task performance over the current deterministic
  renderer? This is the gate for any further work.
- Should synthesis be a separate pipeline phase or integrated into the existing
  architecture skill?
- What is the acceptable cost ceiling per component for synthesis-only passes, given
  that the current 34 approvals save ~69.7 summed agent-minutes?
- Which component shapes are most likely to benefit -- complex multi-module
  monorepos, or simple single-binary operators?
- Can the benchmark distinguish LLM-fabricated connections from genuine inferences?

## Scope

This note captures the idea for future exploration. It is not active work and does
not affect the current deterministic analyzer ownership expansion.
