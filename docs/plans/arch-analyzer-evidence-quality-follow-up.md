# arch-analyzer Evidence Quality Follow-up

## Objective

Use the completed 97-component run to improve the precision and accountability
of analyzer-assisted source reads and rendered evidence. This is a focused
follow-up to the completed broad analyzer-enrichment passes.

## Evidence baseline

- 97 components completed successfully.
- 838 structured source-read justifications were recorded.
- 790 reads were resolved, 40 partially resolved, 6 unhelpful, and 2
  contradicted.
- The dominant read categories were authentication, services, integration
  points, internal dependencies, and HTTP endpoints.
- Some justifications covered very large line ranges.
- Category values sometimes contain comma-joined multi-category strings.
- `agents-operator.md` contains duplicate `crypto/tls` security-evidence rows,
  with `literal` rendered as a status.
- The current platform summary has weaker narrative fidelity than the prior
  comparison document in security, ingress, FIPS, NetworkPolicy, disconnected
  deployment, and HA topics.

## Implementation sequence

### 1. Preserve cross-cutting narrative evidence

Extend analyzer artifacts and the compact synthesis context with bounded,
source-linked evidence families for security, ingress, supply chain and
disconnected deployment, HA, and deployment topology. Each family should
retain observed claims, provenance, and an explicit status such as observed,
inferred, unresolved, or confirmed-empty. Partial synthesis must preserve
these evidence families in the component output even when no additional prose
gap is identified.

Update `aggregate-platform-architecture` with a required cross-cutting
evidence matrix. The platform synthesis should gather these structured facts
before writing `PLATFORM.md`, and may perform bounded targeted source reads only
when a required family is missing or contradictory.

### 2. Tighten source-read scope

Use the read ledger and telemetry to identify whole-file or oversized reads.
Improve analyzer gap candidates and skill guidance so agents prefer bounded
line ranges and record an explicit reason when a full-file read is necessary.

### 3. Mine unresolved and low-value reads

Analyze all `partially-resolved`, `unhelpful`, and `contradicted` records. Add
only the missing deterministic facts that demonstrably caused repeated source
inspection; do not repeat the completed broad enrichment passes.

### 4. Normalize read-justification categories

Represent multi-category justifications as arrays in the schema and renderer,
while preserving compatibility with existing comma-joined values. Validate
categories against the analyzer vocabulary and report unknown values.

### 5. Reconcile read telemetry and ledgers

Clearly distinguish unique source files, source-read operations, line ranges,
and justification records. Explain or eliminate duplicate accounting so run
reports can compare agent activity consistently.

### 6. Improve security-evidence extraction and rendering

Fix [the duplicate TLS security-evidence bug](../bugs/open/arch-analyzer-duplicate-security-evidence.md):
deduplicate repeated observations, separate evidence classification from
status, retain provenance, and avoid promoting generic `crypto/tls` imports to
strong security evidence without a configuration or enforcement signal.

### 7. Add evidence-quality validation

Add deterministic checks for duplicate evidence identities, invalid status or
category values, oversized unexplained reads, and provenance loss. Surface
warnings or failures in analyzer and generation reports without silently
discarding useful evidence.

### 8. Replay and measure

Replay representative operator, Python service, gRPC, webhook-heavy, and
multi-runtime components. Compare unique files, read operations, justified
line ranges, unresolved-read rates, duplicate evidence, source discovery,
duration, fallback rate, and architecture validation against the completed-run
baseline.

## Boundaries

- Prior architecture documents remain comparison-only and are not synthesis
  inputs.
- Do not block agents from justified source reads.
- Do not move semantic architectural judgment into deterministic extraction.
- Do not commit raw logs, transcripts, API/OTel dumps, credentials, or other
  generated runtime data.

## Success criteria

- Oversized reads decline or have explicit, reviewable justifications.
- Component and platform outputs retain source-linked narrative evidence for
  security, ingress, supply chain/disconnected deployment, HA, and deployment
  topology.
- Unresolved-read categories produce a prioritized, evidence-backed analyzer
  backlog rather than another broad enrichment pass.
- Category and telemetry counts are internally consistent.
- Security evidence contains no duplicate identities and uses meaningful
  statuses.
- Replay shows reduced unnecessary source inspection without reduced fact
  preservation or architecture validation quality.

## Execution evidence

The initial implementation replay used read-only next-version checkouts for
`rhods-operator`, `agents-operator`, `MLServer`, and `odh-dashboard`.

- All four analyzer JSON artifacts passed evidence validation.
- Security evidence identities were unique in all four artifacts; the prior
  `agents-operator` artifact had 20 duplicate TLS-import rows, while the new
  artifact has one deduplicated dependency signal with retained provenance.
- All four rendered analyzer documents passed architecture validation.
- `arch-query platform-summary` exposed 128 cross-cutting records across the
  four-component fixture, covering all six required topics.

The focused containerized synthesis replay then regenerated the same four
components from the analyzer artifacts and read-only checkouts, without using
prior architecture documents as synthesis inputs:

| Metric | rhods-operator | agents-operator | MLServer | odh-dashboard |
|---|---:|---:|---:|---:|
| Duration | 6m 30s | 5m 21s | 5m 39s | 5m 04s |
| Agent turns | 33 | 36 | 41 | 29 |
| Source-read operations | 8/8 | 8/8 | 8/8 | 8/8 |
| Unique source files | 7 | 7 | 8 | 8 |
| Fully resolved reads | 8 | 8 | 8 | 7 |
| Partially resolved reads | 0 | 0 | 0 | 1 |
| Route / fallback | partial / none | partial / none | partial / none | partial / none |

- All 32 reads included structured `gap_category`, question, expected signal,
  outcome, and section fields; 31 resolved fully. The single partial read was
  `odh-dashboard`'s deployment overlay, where JSON Patch indirection limited
  deterministic resolution.
- The replay produced insights and change artifacts for all four components.
- All four regenerated documents passed architecture validation, and the
  orchestrator's full validation pass reported 943/943 documents valid.
- The replay confirms bounded, reviewable source inspection and preserved
  analyzer-backed evidence. It does not establish a full-corpus runtime
  speedup; that requires a matched before/after full run.
