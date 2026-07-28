# Analyzer Gap Evidence and Source-Read Justification Plan

## Objective

Reduce unnecessary agent source reads by having `arch-analyzer` publish the
highest-value evidence locations and unresolved questions, while requiring the
agent to explain the purpose and result of each source file it reads.

This preserves agent discretion: source reads remain allowed under the partial
route and file budget. The analyzer supplies better starting points, and the
justification ledger makes remaining demand measurable.

## Evidence baseline

The completed 97-component run recorded 698 source reads and 592 discovery
calls. The median component used the full eight-file budget. Merge demand was
concentrated in authentication, integration points, internal dependencies,
HTTP endpoints, egress, and services.

## Work sequence

### 1. Publish a gap evidence index

Add a deterministic `gap_evidence_index` to analyzer JSON and the compact
context projection. Each entry should include the gap category and unresolved
field, a concrete question, candidate source paths and line ranges, symbols or
configuration keys, the expected evidence signal, and current limitations.

Candidates must come from source-backed extraction. The index may rank likely
evidence locations but must not claim that a candidate proves the unresolved
fact.

### 2. Enrich high-demand extraction

Prioritize deterministic extraction for dynamic HTTP routes and handler
ownership; gRPC registration, interceptors, credentials, and ports; runtime
client constructors and egress configuration; Kubernetes client/resource
relationships and controller watches; RBAC-to-handler/controller relationships;
configuration defaults, environment variables, probes, lifecycle arguments; and
service/deployment/endpoint/TLS/auth joins.

Each new fact must retain provenance and explicit unknown behavior.

### 3. Add a source-read justification contract

Require the agent to write a machine-readable sidecar containing one record per
source file read. Records contain `path`, `line_range`, `gap_category`,
`question`, `expected_signal`, `outcome`, and affected `sections`. The sidecar
contains paths and reasoning metadata only: never source excerpts, secrets,
prompts, or raw transcripts.

The orchestrator compares the ledger to telemetry and reports missing or
unjustified reads. Initial rollout is warning-only; enforcement can follow
after the format is proven stable.

### 4. Close the feedback loop

Replay representative operators, Python services, gRPC services, webhook-heavy
components, and multi-runtime repositories. Compare source reads, discovery
calls, justified-read ratio, edit/merge decisions, duration, fallback rate, and
fact preservation.

## Boundaries

- Do not block valid bounded source reads merely because the analyzer lacks a
  fact.
- Do not use prior generated architecture documents as synthesis inputs.
- Keep semantic trade-offs and cross-component interpretation agent-owned.
- Keep justification sidecars and raw telemetry out of committed architecture
  output unless a sanitized summary is explicitly authored.

## Success criteria

- Compact context gives actionable candidate files for dominant gap categories.
- Justified-read ratio reaches at least 95% in replay.
- Discovery calls and full-budget components decline without reducing useful
  evidence or fact preservation.
- Repeated demand signals become analyzer facts or remain explicitly documented
  as agent-owned semantic work.
