# Milestone: Analyzer-Generated Document Fidelity

## Goal

Establish that analyzer-first `GENERATED_ARCHITECTURE.md` output preserves the
source-backed architecture content needed to replace the legacy repository-wide
agent workflow. Speed and structural validity are necessary but are not sufficient
for this milestone.

## Result

At dashboard commit `f1cdd9f22`, the initial analyzer retained 141 of 165 measured
structured identities (85.45%) from the existing `rhoai.next` fixture. The completed
row-level audit corrected analyzer and comparator defects and produced this result:

| Measure | Result |
|---------|-------:|
| Raw structured fixture recall | 162/166 (97.59%) |
| Adjudicated structured recall | 162/162 (100%) |
| Whole-document row recall | 192/293 (65.53%) |
| Current analyzer identities preserved by generated document | 314/314 (100%) |
| Analyzer-to-generated cell conflicts | 0 |
| Extraction | 0.49s |
| Rendering | less than 0.01s |
| Deterministic synthesis rebase | 0.04s |

The four raw misses are source-reviewed fixture defects or out-of-scope browser
behavior. Recent history and source-file inventory remain in the whole-document
metric but are excluded from structured architecture recall. The second-repository
`caikit-nlp` check preserved 20/20 current analyzer identities while exercising the
bounded `partial` path.

## Acceptance Criteria

- [x] Every one of the 24 dashboard structured-identity misses is classified as a valid
  fixture fact, stale or incorrect fixture fact, equivalence/comparator issue, or
  analyzer extraction defect.
- [x] Every populated-cell conflict in the dashboard comparison is classified, with
  source evidence for any change accepted as a fixture correction.
- [x] Analyzer, normalization, rendering, comparator, or bounded agent-gap behavior is
  corrected for every confirmed defect.
- [x] The final dashboard `GENERATED_ARCHITECTURE.md` reaches at least 95% exact recall
  over the adjudicated structured baseline, with no unexplained miss in network,
  authentication, secrets, RBAC, or integration categories.
- [x] The agent output preserves every structured identity supplied by the analyzer and
  only changes a populated source-backed cell when it records targeted evidence.
- [x] Source-file inventory and recent Git history are reported separately and do not
  dilute the architecture-fidelity metric.
- [x] A second representative repository confirms the resulting comparison and
  preservation gates are not dashboard-specific.

## Boundaries

This milestone covers component-level extraction and
`GENERATED_ARCHITECTURE.md`. It does not change `PLATFORM.md` synthesis or diagram
generation. The existing Markdown is a regression fixture, not unquestioned ground
truth; adjudication is part of the milestone.

## Work Items

- [Audit dashboard structured fidelity gaps](../tasks/done/complete-architecture-context-static-migration.md)

## Status

Done
