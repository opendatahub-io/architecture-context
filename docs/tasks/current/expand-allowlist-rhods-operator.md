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
