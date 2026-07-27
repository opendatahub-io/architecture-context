# Task: Expand Provisional Allowlist for rhods-operator

## Goal

Use the accepted real synthesis evidence to enable `rhods-operator` on the
provisional synthesis route while leaving `odh-dashboard` analyzer-only.

## Scope

- Update `lib/synthesis_migration_allowlist.json` to add `rhods-operator`.
- Preserve `caikit-nlp` and `rhoai-mcp`; do not add dashboard because its
  analyzer-only approval takes precedence and needs no agent synthesis.
- Add/update durable plan/task evidence and focused routing assertions.
- Preserve legacy fallback, analyzer fact ownership, clean-run isolation, and
  all promotion gates.

## Exclusions

- Do not modify generated architecture output or raw run artifacts.
- Do not retire legacy or claim full rollout.
- Do not require external services or human labels.

## Acceptance criteria

- Allowlist JSON validates and contains exactly the reviewed components.
- `rhods-operator` routes to synthesis when readiness is sufficient;
  `odh-dashboard` remains analyzer-only.
- Focused routing tests pass and evidence cites the accepted real synthesis
  report. Implementation agent does not commit.

## Execution record — 2026-07-27

- Container implementation run completed without a commit; reported cost was
  `$1.6717`.
- The allowlist JSON validates with exactly `caikit-nlp`, `rhoai-mcp`, and
  `rhods-operator`.
- Seven focused routing assertions passed; the broader targeted/analyzer-only/
  routing suite reported 108 passing tests and 12 pre-existing allowlist
  failures. Ruff passed.
- Evidence source: `d14a7e1f` and
  `docs/notes/real-analyzer-assisted-synthesis-report.md`.

## Driver review

Accepted. `rhods-operator` now routes to provisional synthesis when readiness
is sufficient, while `odh-dashboard` remains analyzer-only by approval
precedence. No generated architecture output, raw run artifact, external
service, human label, or unrelated worktree change was included.
