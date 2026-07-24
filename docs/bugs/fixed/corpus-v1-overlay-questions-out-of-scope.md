# Bug: Corpus V1 Overlay Questions Out of Scope

## Summary

10 of 40 corpus questions (25%) expect answers sourced from `overlays/*.md`
files, but the evaluation container mounts only the architecture version
directory (`architecture/rhoai.next/`). The `overlays/` directory lives at
the repo root and is never visible to the consumer agent.

This is the single largest driver of the 15% exact-match rate and 36%
composite score in the v1 A/B evaluation.

## Affected Questions

| ID | Expected Source | Agent Behavior |
|----|----------------|----------------|
| INV-005 | overlays/0004 | Found codeflare-sdk in README but couldn't know about PLATFORM.md inventory gap |
| INV-009 | overlays/0016 | Incorrectly answered "Yes" — component data shows Triton runtimes; overlay corrects this |
| INTG-002 | overlays/0011 | Correctly reported overlays don't exist in tree |
| INTG-003 | overlays/README.md | Correctly reported overlays don't exist in tree |
| INTG-004 | overlays/0011 | Gave good answer from component docs but missed overlay-specific detail |
| INTG-006 | overlays/0008 | Correctly answered "No" from component docs but couldn't cite overlay |
| INTG-008 | overlays/0009 | Found 6 fine-tuning components from docs; expected 4 per overlay |
| INTG-010 | overlays/0014 | Correctly identified ModelMesh as deprecated but lacked overlay specifics |
| NAV-003 | overlays/README.md | Confused architecture overlays with Kustomize overlays in PLATFORM.md |
| NAV-006 | overlays/README.md | Confused overlay lifecycle with managementState lifecycle |
| NAV-010 | overlays/0003 | Found the rename in component docs but couldn't cite the overlay |

## Root Cause

The evaluation harness (`run_containerized.sh`) mounts `--tree-a` and
`--tree-b` as read-only volumes. These point to `architecture/rhoai.next.bak/`
and `architecture/rhoai.next/`. Neither mount includes the `overlays/`
directory which lives at the repository root.

The corpus was written with knowledge of overlays, but the evaluation scope
was designed to test the architecture document tree only.

## Impact

HIGH — this is the dominant factor in the low composite score. Fixing this
alone would affect 25% of questions.

INV-009 is the most severe case: the agent gives a factually wrong answer
("Yes, Triton is shipped") because the component data does show Triton
runtimes. Only overlay 0016 corrects this to "Tested & Verified only."
Without overlay access, the agent cannot distinguish shipped vs. T&V runtimes.

## Options

1. **Mount overlays in the evaluation** — add `-v overlays/:/data/overlays:ro`
   and adjust agent prompting to include overlays. Tests the full consumer
   experience but changes what the benchmark measures.

2. **Split the corpus** — tag overlay-dependent questions separately and score
   them only when overlays are in scope. Preserves the current benchmark as
   a pure architecture-doc quality test.

3. **Synthesize overlay content into component docs** — have the analyzer
   merge relevant overlay facts into component `.md` files during generation.
   This is analyzer v2 work and the most impactful long-term fix.

## Recommendation

Option 2 (split the corpus) for the v1.1 benchmark; option 3 (synthesize
overlays) as a v2 analyzer goal.

## Resolution

Removed all 11 overlay-dependent questions from the corpus (40 → 29 questions).
Overlays are human-written documents whose accuracy cannot be trusted for
long-term structured data. They are treated as bug reports to consider, not
mandated data updates. The benchmark measures architecture-doc quality from
analyzer-generated content only; overlay knowledge is out of scope.

Removed question IDs: INV-005, INV-009, INTG-002, INTG-003, INTG-004,
INTG-006, INTG-008, INTG-010, NAV-003, NAV-006, NAV-010.

## Status

Fixed.
