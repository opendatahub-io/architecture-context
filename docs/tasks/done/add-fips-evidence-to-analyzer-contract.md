# Task: Add FIPS Evidence to the Analyzer Contract

## Goal

Make FIPS and build-hermeticity claims available through evidence-driven
analyzer context and bounded synthesis, without hardcoding component-specific
claims in the architecture skill or generated Markdown.

## Evidence

The post-regeneration strategy comparison at
`tmp/evaluations/consumer-v1-rhoai-next-vs-bak-20260801T003432Z/` still flags
`INTG-009`. The backup document explains that
`fms-guardrails-orchestrator` uses rustls with the ring backend and is not
FIPS-validated; the regenerated document contains the rustls dependency but no
explicit FIPS analysis. The targeted replay also completed successfully while
producing no FIPS text, so this is an evidence/routing gap rather than an
`arch-doc` write failure.

## Plan

1. Identify the source evidence needed for application crypto backend,
   FIPS-mode configuration, and build-image/runtime crypto signals.
2. Add a structured analyzer coverage category or projection for those facts,
   including explicit unknown/not-verified findings when evidence is absent.
3. Route the category to bounded synthesis and preserve the resulting
   FIPS/build-hermeticity subsections through `arch-doc`.
4. Add analyzer, skill, merge, and focused FMS regression tests.
5. Run a targeted FMS replay and re-evaluate `INTG-009` before a full corpus
   rerun.

## Acceptance Criteria

- No component-specific FIPS value is hardcoded in the skill or renderer.
- Available crypto/build evidence is rendered with provenance.
- Missing evidence is stated as unknown or not verified rather than inferred.
- The FMS targeted replay preserves analyzer-owned evidence and includes the
  supported FIPS conclusion.
- `INTG-009` no longer flags for an evidence-backed reason.

## Status

Complete — analyzer extraction, coverage routing, skill guidance, focused tests,
targeted FMS replay, and focused `INTG-009` re-evaluation completed
2026-08-01. The isolated FMS candidate, merged document, and final document
contain the evidence-backed FIPS conclusion and pass `arch-doc validate`.

## Implementation Evidence

- Rust projects now emit source-linked `crypto-library`, `crypto-provider`,
  `crypto-build-signal`, `fips-build-signal`, and `fips-posture` records from
  Cargo/build files. A missing signal produces an explicit `not-extracted`
  posture rather than an implicit compliance claim.
- `fips_compliance` is emitted as `fips-compliance/v1` category coverage and is
  routed as a safety-critical bounded partial gap. The skill guidance requires
  a source-linked `FIPS Compliance` subsection and forbids inferring FIPS from
  TLS, OpenSSL, or a base image alone.
- `GOCACHE=/tmp/arch-analyzer-gocache go test ./...` passed,
  `GOCACHE=/tmp/arch-analyzer-gocache go vet ./...` passed, focused Python
  tests passed (`88 passed`), and the Rust fixture emitted the expected
  provenance and partial coverage.
- The targeted FMS replay used six bounded source reads, resolved the
  `fips_compliance` gap, and added the `FIPS Compliance` subsection. Candidate,
  merged, and final documents each validated with 11 sections. Analyzer merge
  preservation reported 92 unchanged rows and no applied table changes; one
  stale integration-point proposal was rejected.
- The isolated replay artifacts are under
  `tmp/architecture-corpus-runs/rhoai.next-20260730T215609Z-929041/`. The
  canonical tree still requires a full regeneration before the broad benchmark;
  that is the next measurement, not an outstanding acceptance criterion for
  this focused task.
- The original focused `INTG-009` regression was a rubric mismatch: Tree B
  stated that `ring` is not a FIPS-validated cryptographic provider, but the
  corpus only accepted the narrower contiguous phrase `rustls with ring is not
  FIPS-validated`. Added the equivalent evidence-backed variant to both
  `benchmark/consumer-v1/corpus.json` and `benchmark/strategy-v1/corpus.json`.
  Rescoring the existing raw result produced Tree A 1.0, Tree B 1.0, with no
  regressions.
