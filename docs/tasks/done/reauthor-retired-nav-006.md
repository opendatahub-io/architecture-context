# Task: Re-author Retired Navigation Question NAV-006

## Goal

Restore only `NAV-006` with exact repository-backed navigation evidence, or
record it unresolved if the current tree cannot support a trustworthy answer.

## Scope and controls

- Inspect the original v1-ab artifacts, audit notes, `architecture/` layout,
  symlinks, and relevant navigation documentation.
- Do not touch other retired IDs, existing result artifacts, schema, or
  validator; do not invent paths or run evaluations.

## Acceptance criteria

- [x] NAV-006 is restored only with exact source evidence, or its unresolved
  reason and recovery path are recorded without changing the corpus.
- [x] Manifest, focused tests, notes, session log, and PLAN are consistent;
  manifest validation passes.
- [x] Remaining Tier-3/Tier-4 gaps remain explicit and no contract is weakened.
- [x] Move to `done/` only after review and an accepted scoped commit.

## Result

**Unresolved — cannot restore.**

### Evidence audit

| Check | Result |
|-------|--------|
| Original question | "How do overlay lifecycle states work?" — unambiguous; single overlay lifecycle concept in this repo |
| Expected answer accuracy | Every claim is near-exact paraphrase of `overlays/README.md` lines 72-82 |
| Source file existence | `overlays/README.md` exists (86 lines), content verified |
| Source line precision | Lines 77-82 (Lifecycle section) define active/superseded states; lines 70-75 (Matching section) describe consumer filtering rules |
| v1-ab agent behavior | Both trees confused overlay lifecycle with `managementState` lifecycle (Managed/Removed states on DSC components); neither read `overlays/README.md` |
| Alternative source in architecture tree | None — overlay lifecycle concept is not documented in any `architecture/` file |
| Evaluation scope | `overlays/README.md` is NOT mounted in the evaluation container (only `architecture/rhoai.next/` is mounted) |
| Policy constraint | Bug resolution (`docs/bugs/fixed/corpus-v1-overlay-questions-out-of-scope.md`) explicitly placed overlay knowledge out of benchmark scope |

### Source evidence detail

The original expected answer maps to `overlays/README.md` with exact line references:

| Expected answer claim | Source line | Source text |
|-----------------------|------------|-------------|
| "Two lifecycle states: active and superseded" | 79-80 | `- **active**: ...` / `- **superseded**: ...` |
| "active (consumers apply the overlay's corrections)" | 79 | "Consumers read and apply this overlay" |
| "superseded (ignored by consumers, kept for audit trail)" | 80 | "The file stays for audit trail; consumers ignore it" |
| "Only active overlays are consumed" | 72 | "Only `active` overlays are consumed" |
| "Consumers filter by release version or 'all'" | 73 | "Filter by target release version or `\"all\"`" |
| "match the affects list" | 74 | "Match `affects` list against the components relevant to the consumer's task" |
| "An overlay with affects: [platform] applies to all components" | 75 | "Overlays with `affects: [platform]` apply to all components" |

### Why not restored despite exact evidence

1. **Evaluation scope**: The evaluation container mounts only `architecture/rhoai.next/`. `overlays/README.md` is at the repo root and not accessible during evaluation. Restoring the question would create an un-evaluable entry that scores 0% in any evaluation run.
2. **Policy**: The bug resolution explicitly placed "overlay knowledge" out of scope: "The benchmark measures architecture-doc quality from analyzer-generated content only."
3. **No alternative source**: Unlike INV-005 and INV-009 (restored because their answers could be re-sourced from architecture tree files), the overlay lifecycle concept has no representation in any architecture file.

### Distinction from NAV-003

NAV-003 was unresolvable due to question quality issues (ambiguity, no citable source_line, answer requires 20-file frontmatter scan). NAV-006 has none of these problems — the question is unambiguous and the source evidence is exact. It is blocked solely by evaluation infrastructure scope.

### Recovery path

1. **Mount `overlays/` in evaluation**: Add `-v overlays/:/data/overlays:ro` to the evaluation container. NAV-006 can then be restored with `source_file: overlays/README.md`, `source_line: "72-82"`.
2. **Implement corpus scope tagging**: The pending task `docs/tasks/pending/tag-corpus-questions-by-required-scope.md` would allow questions to declare required scope (e.g., `architecture+overlays`). NAV-006 could be tagged and evaluated only when overlays are in scope.
3. **Synthesize overlay system docs into architecture tree**: Include overlay mechanism documentation in the architecture tree (e.g., as a section in `PLATFORM.md`), making the answer available during evaluation.

### Changes

| File | Change |
|------|--------|
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | NAV-006 retirement_reason updated with specific evidence and unresolved reason |

### Artifacts preserved (not modified)

- `benchmark/consumer-v1/corpus.json` (31 questions, unchanged)
- All other manifest entries, schema, validator, results
- No evaluation run; no existing results modified

## Status

Done — 2026-07-24 (unresolved; recorded with evidence and recovery path).
