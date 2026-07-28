# Task: Fix Platform Summary Analyzer Artifact Loading

## Goal

Ensure platform aggregation consumes analyzer evidence from the current
`architecture/<platform>/<component>/.analyzer/component-architecture.json`
layout and does not fail on empty JSON collections.

## Scope

- Teach `arch-query` to merge component-local analyzer artifacts in addition
  to legacy top-level component JSON files.
- Include webhook inventory and webhook reference arrays in
  `arch-query platform-summary`.
- Ensure empty webhook query results and platform-summary collections serialize
  as JSON arrays, not `null`.
- Update the aggregate platform skill to use webhook evidence from
  `platform-summary` instead of invoking a separate webhook probe.

## Execution record

- Added loader support for `<component>/.analyzer/component-architecture.json`.
- Added `platform-summary` fields for `webhooks`, `platform_webhooks`, and
  `external_webhooks`, and initialized collection outputs as non-null arrays.
- Preserved `arch-query webhooks` as an optional human-facing query and fixed
  empty JSON output to return `[]`.
- Updated aggregate platform webhook instructions and reference guidance.
- Validation:
  - `GOCACHE=/tmp/arch-query-go-cache go test ./...`
  - `bin/arch-query webhooks --version rhoai.next --output json` returned a
    JSON array with 218 webhook entries.
  - `bin/arch-query platform-summary --version rhoai.next` returned array
    fields for webhooks, controller watches, RBAC, and cross-cutting evidence.
  - Scoped `git diff --check` passed.

## Status

Completed 2026-07-28.
