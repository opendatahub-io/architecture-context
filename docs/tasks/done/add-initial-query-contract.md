# Task: Add Initial Machine-Readable Query Contract

## Goal

Implement the initial query interface in
`docs/plans/analyzer-assisted-agent-architecture.md` as a bounded, one-shot
CLI contract over the existing architecture snapshot.

## Scope

- Add a `query` command family with machine-readable versioned responses for:
  `callers-of`, `consumers-of`, `config-sources`, `crds`, `dependency-status`,
  and `diff`.
- Reuse existing structured loader data and existing CRD/diff implementations
  rather than duplicating parsers.
- Every response must include query identity, requested version/applicability,
  evidence/source locations when available, and an explicit result status such
  as `ok`, `unknown`, or `not-extracted`.
- `crds` and `diff` must return useful structured answers from current data.
  Source-level callers, consumers, and configuration sources must return
  `not-extracted` with a visible reason when current snapshot data cannot prove
  them; never infer relationships from absence.
- `dependency-status` may return available dependency facts but must label
  lifecycle/release status `unknown` when the snapshot has no such evidence.
- Preserve existing top-level commands and text output; new query behavior is
  opt-in and one-shot (no server lifecycle).
- Document concrete JSON examples and bounded/unknown semantics.

## Negative controls

- Do not invent callers, consumers, configuration sources, dependency status,
  ownership, or source locations.
- Do not treat query output as an authority override or apply overlays.
- Do not implement OTel, synthesis, routing changes, or paid evaluations.
- Do not modify generated architecture documents or resolve merge conflicts.

## Acceptance criteria

- [x] All six named query forms exist under the documented command contract
  and accept the required identifying arguments.
- [x] JSON schemas/types are versioned, deterministic, bounded, and document
  applicability, evidence, and explicit unknown/not-extracted outcomes.
- [x] CRD/diff results are backed by existing data; unsupported source queries
  are visibly not-extracted rather than empty success responses.
- [x] Focused tests cover successful, unknown, not-extracted, missing-version,
  and malformed-argument cases; existing tests and commands remain compatible.
- [x] Plan note, session log, and PLAN are reconciled.
- [x] Task is moved to `done/` only after review and an accepted commit.

## Status

Done — `arch-query query` provides all six initial machine-readable forms with
versioned evidence/status responses and explicit not-extracted boundaries.
