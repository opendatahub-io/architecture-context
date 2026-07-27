# Task: Remove the Legacy Webhook Inventory Phase

## Goal

Remove the obsolete Python `webhook-inventory` phase and its `main.py`
subcommand now that `arch-analyzer`, `repo-to-architecture-summary`, and
`aggregate-platform-architecture` own webhook extraction and synthesis.

## Scope

- Remove `run_webhook_inventory_phase`, its orchestration hooks, and the
  `webhook-inventory` CLI parser/options.
- Remove phase-only Python helpers and tests with no remaining consumer,
  including legacy `webhooks.json` materialization and phase-owned enrichment.
- Update aggregate skill/reference instructions and preserve `arch-query
  webhooks` as a read-only query over component JSON.
- Update ADRs, notes, help text, tests, and plan references to describe the new
  ownership boundaries and explicit unknowns for unavailable overlay/runtime
  evidence.

## Execution record

- Removed `lib/phases/webhooks.py`, `lib/webhook_analyzer.py`, and the phase
  tests, plus the CLI parser and orchestration hooks.
- Updated aggregate webhook synthesis to consume component JSON directly and
  document absent overlay, handler, and cross-component enrichment as unknown.
- Superseded ADR-0013 and rewrote the webhook note for the new architecture.
- Preserved `arch-query webhooks`; independent query check returned 157 entries
  from `architecture/rhoai.next` component JSON.
- Validation: arch-query Go tests passed, focused validator tests passed (4),
  aggregate `PLATFORM.md` validation passed, Python compilation passed, and
  scoped `git diff --check` passed. The host `main.py --help` check was blocked
  by missing `python-dotenv` in the host environment.
- Delegated run log: `/tmp/claude-task-runs/agent-driver.jsonl`; reported cost
  `$4.610451`; generated architecture outputs were not staged or modified by
  the task.

## Status

Completed and accepted 2026-07-27.
