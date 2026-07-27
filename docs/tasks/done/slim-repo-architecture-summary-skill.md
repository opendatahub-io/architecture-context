# Task: Slim repo-to-architecture-summary Skill

## Goal

Reduce `.claude/skills/repo-to-architecture-summary/SKILL.md` below 500 lines
without losing behavior by moving detailed legacy-route procedures and quality
guidance into discoverable reference files.

## Scope

- Preserve in `SKILL.md` the arguments, analyzer input contract, route/tool
  limits, analyzer-first policy, gap classification, prior-architecture
  isolation, concise output contract, validation contract, and reporting
  contract.
- Extract detailed procedures into focused references, reusing existing files
  where appropriate:
  - operator preparation and RHOAI ingress
  - AIPCC ecosystem analysis
  - security, FIPS, and build hermeticity
  - sub-agent dispatch
  - provenance analysis
  - architecture-output requirements
  - insight artifact schema
  - summary reporting and quality bar
- Update `SKILL.md` with clear links and instructions to read applicable
  references on demand, preserving legacy/partial/synthesis route behavior.
- Remove the duplicated controller-reconnaissance sentence and reconcile the
  frontmatter `allowed-tools` declaration with the documented route controls.
- Preserve existing reference content and links unless moving/merging it is
  necessary; do not alter production pipeline behavior.

## Acceptance criteria

- `SKILL.md` is below 500 lines and remains internally coherent.
- Every extracted procedure is available in a linked reference file, with no
  accidental loss of required commands, safety limits, schemas, or output
  requirements.
- Existing reference links resolve; markdown/code fences and JSON examples are
  valid; no stale section references remain.
- Focused deterministic checks pass, including line count, link checks, and
  relevant skill/architecture tests if available.
- No generated architecture output, raw telemetry, API/OTel dumps, secrets, or
  unrelated worktree changes are modified. Implementation agent does not
  commit.

## Execution record — 2026-07-27

- The delegated run stalled while emitting an oversized rewrite command and
  was stopped before execution. Useful untracked reference drafts were
  reviewed and retained only where coherent.
- The driver completed the refactor through reviewed patches. `SKILL.md` is
  now 119 lines, with six resolving Markdown reference links.
- Added focused references for legacy deep analysis, operator preparation,
  RHOAI ingress patterns, AIPCC, security/build analysis, and
  provenance/quality/reporting. Existing language-specific references remain
  available.
- `git diff --check` passed; no production code, generated architecture,
  telemetry, API/OTel dumps, secrets, or unrelated work was changed.

## Driver review

Accepted. The always-loaded skill now contains the analyzer contract, route
limits, clean-run isolation, output contract, and safety rules. Detailed
legacy procedures are discoverable through references, and the duplicate
controller sentence was removed. Deterministic line-count and link checks
passed.
