# Task: Accept CodeFlare Component-Map Inventory Wording

## Goal

Keep the inventory benchmark contract aligned with the current architecture
tree's authoritative component inventory source.

## Evidence

The 2026-08-02 full benchmark flagged `INV-005` because Tree B answered that
CodeFlare SDK was listed in `component-map.json` and had a dedicated
architecture document. The response was source-backed and semantically
answered the question, but the corpus only accepted wording using “component
inventory” or “RHOAI component”.

## Change

- Added `CodeFlare SDK is listed in component-map.json` to the synchronized
  `consumer-v1` and `strategy-v1` corpus variants.
- Added a scorer regression test using the exact Markdown-formatted wording
  from the flagged response.

## Validation

- Focused scorer tests: `46 passed`.
- Both JSON corpora parse successfully.
- Rescored the existing raw results from
  `tmp/evaluations/consumer-v1-rhoai-next-20260802T191329Z/` without
  regenerating the architecture tree.
- Tree B overall improved from `0.6417` to `0.6542`.
- `INV-005` passes for both trees and the report now shows no regressions.

## Status

Complete — 2026-08-02.
