# Task: Re-author Retired Navigation Question NAV-003

## Goal

Restore only `NAV-003` with exact repository-backed navigation evidence, or
record it unresolved if the current tree cannot support a trustworthy answer.

## Scope and controls

- Inspect the original v1-ab artifacts, audit notes, `architecture/` layout,
  symlinks, and relevant navigation documentation.
- Do not touch other retired IDs, existing result artifacts, schema, or
  validator; do not invent paths or run evaluations.

## Acceptance criteria

- [x] NAV-003 is restored only with exact source evidence, or its unresolved
  reason and recovery path are recorded without changing the corpus.
- [x] Manifest, focused tests, notes, session log, and PLAN are consistent;
  manifest validation passes.
- [x] Remaining Tier-3/Tier-4 gaps remain explicit and no contract is weakened.
- [ ] Move to `done/` only after review and an accepted scoped commit.

## Result

**Unresolved — cannot restore.**

### Evidence audit

| Check | Result |
|-------|--------|
| Original question | "What overlays modify the base architecture?" — ambiguous; conflates architecture context overlays (`overlays/` directory) with Kustomize overlays (`config/overlays/` in component repos) |
| Expected answer accuracy | Factually correct: 20 active overlay files exist (0001-0018, two 0005s, two 0015s), all `status: active` |
| Original v1-ab failure | Agent answered about Kustomize overlays, not architecture context overlays (audit: "Confused architecture overlays with Kustomize overlays") |
| Source evidence availability | No single file at a citable source_line documents the overlay count or topic list. `overlays/README.md` explains the concept but does not enumerate overlays |
| Verifiability | Determining "20 active overlays" requires directory listing + reading frontmatter (`status: active`) across 20 individual files |

### Unresolved reasons

1. **Question ambiguity**: "overlays" has two distinct meanings in this repo — architecture context overlays and Kustomize overlays. The same confusion that caused the v1-ab evaluation failure would recur.
2. **No citable source_line**: The answer derives from a directory listing and 20 files' frontmatter, not from a single documented location.
3. **Source path outside architecture tree**: The `overlays/` directory is at repo root, outside `architecture/rhoai.next/`, though this alone is not disqualifying (INV-002, INV-007, NAV-004 also reference sources outside the architecture tree).

### Recovery path

Re-author the question to disambiguate the overlay concept. Candidates:
- "How many architecture context overlay files exist in the overlays/ directory?" (simpler, directory-verifiable)
- "What is the purpose of the overlays/ directory?" (answerable from `overlays/README.md`, line 1-3)
- "How does the overlay lifecycle work?" (answerable from `overlays/README.md`, line 79-81)

### Changes

| File | Change |
|------|--------|
| `benchmark/analyzer-assisted-v1/corpus_manifest.json` | NAV-003 retirement_reason updated with specific unresolved reason |

### Artifacts preserved (not modified)

- `benchmark/consumer-v1/corpus.json` (31 questions, unchanged)
- All other manifest entries, schema, validator, results
- No evaluation run; no existing results modified

## Status

Done — 2026-07-24 (unresolved; recorded with evidence and recovery path).
