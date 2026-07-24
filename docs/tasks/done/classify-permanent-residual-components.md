# Task: Classify Permanent Residual Components

## Goal

Formally classify four components as permanent agent residuals, removing them
from the extraction backlog and establishing clear documentation that these
components will never be analyzer-only for structural reasons.

## Context

The v1 residual register lists four components that cannot be made
analyzer-only due to fundamental limitations, not missing extraction contracts.
These are currently mixed into the unresolved mutation counts, inflating the
apparent extraction backlog by 20 mutations. Formally classifying them cleans
the target scope and sets an honest ceiling for analyzer-only coverage.

## Target Components

| Component | Mutations | Reason |
|-----------|----------:|--------|
| `rhods-operator` | 0 | Deliberate prose residual. Hierarchical lifecycle, fan-out provisioning, and cross-component data-flow narrative are not represented by deterministic structured facts. Agent-owned for architectural prose, not extraction gaps. |
| `ogx` | 0 | Unsupported language limitation. Internal Dependencies blocked by shell (12 build/CI scripts) and iOS Swift (5 files). Authentication resolved (5 facts). Zero platform references across 735 files. |
| `notebooks` | 19 | Bundled-library inventory. Evidence model (library availability in user environment) is fundamentally different from runtime service integration. No shipped application entrypoint invokes these libraries. |
| `notebooks-downstream` | 1 | Same as `notebooks`. Downstream image with pinned library versions. |

## Work

1. Update `docs/notes/analyzer-residual-agent-gaps.md`:
   - Move all four components into a "Permanent Agent Residuals" section.
   - Remove their mutations from the unresolved count.
   - Update the mutation reconciliation table.
2. Document the classification decision with source-backed justification
   for each component.
3. Update the projected ceiling in the coverage plan
   (`docs/plans/analyzer-only-full-coverage.md`).

## Negative Controls

- Must not classify a component as permanent residual if the limitation is
  a missing extraction contract that could reasonably be implemented.
- Must not remove components from the residual register entirely — they
  must remain documented with their permanent classification.

## Acceptance Criteria

- [ ] All four components documented in a Permanent Agent Residuals section.
- [ ] Mutation reconciliation table updated (99 unresolved → 79 unresolved
  + 20 permanent).
- [ ] Each classification has source-backed justification referencing prior
  audit notes.
- [ ] Coverage plan updated with accurate ceiling.
- [ ] Move this task to `docs/tasks/done/`.

## Likely Files

- `docs/notes/analyzer-residual-agent-gaps.md`
- `docs/plans/analyzer-only-full-coverage.md`

## Status

Done. All four components classified as permanent agent residuals. Mutation
reconciliation updated (99 unresolved → 79 extraction-targetable + 20
permanent). Coverage plan ceiling corrected.
