# Task: Move Platform Webhook Synthesis to Aggregate Platform Architecture

## Goal

Make `aggregate-platform-architecture` the owner of platform-wide webhook
synthesis while keeping `repo-to-architecture-summary` responsible for
per-component webhook semantics and `arch-analyzer` responsible for the
canonical deterministic inventory.

## Scope

- Add `aggregate-platform-architecture/references/webhook-analysis.md` for
  cross-component webhook synthesis.
- Update the aggregate skill to consume analyzer-backed component JSON and the
  platform webhook inventory, and to incorporate webhook ownership,
  cross-cutting concerns, shared targets, overlay placement, and security
  implications into `PLATFORM.md`.
- Remove duplicate semantic work from `lib/phases/webhooks.py` while retaining
  deterministic materialization and JSON enrichment needed by `webhooks.json`
  and `arch-query`.
- Update validation, tests, and documentation so the aggregate boundary is
  explicit and outputs remain compatible.

## Non-goals

- Do not move deterministic webhook extraction out of `arch-analyzer`.
- Do not use prior `architecture/**` documents as synthesis inputs.
- Do not remove per-component webhook synthesis from
  `repo-to-architecture-summary`.

## Execution record

- Added the aggregate webhook reference and optional platform-template section
  for ownership, cross-component targets, cross-cutting concerns, overlay
  deployment, security implications, and provenance.
- Updated the aggregate skill to load structured webhook data through
  `arch-query`/`webhooks.json` without source re-enumeration or sub-agents.
- Removed the webhook phase's agent-analysis step while retaining deterministic
  overlay/handler mapping, cross-component maps, JSON/Markdown enrichment, and
  `webhooks.json` materialization.
- Added validator support and focused tests for optional webhook sections and
  the no-agent phase boundary.
- Independent validation: `PYTHONPATH=. ./.venv/bin/pytest -q
  tests/test_validate_platform.py tests/test_webhook_analyzer.py` (10 passed),
  existing `PLATFORM.md` validation passed, and scoped `git diff --check`
  passed.
- Delegated run log: `/tmp/claude-task-runs/agent-driver.jsonl`; reported cost
  `$5.67195825`; no generated architecture outputs were included in the task
  changes.

## Status

Completed and accepted 2026-07-27.
