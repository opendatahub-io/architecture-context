# Task: Move Architecture Template into Skill Templates

## Goal

Move the repo-to-architecture-summary output template from `references/` to an
adjacent `templates/` directory, keeping the skill's progressive-disclosure
navigation and all applicable internal links correct.

## Scope

- Move `.claude/skills/repo-to-architecture-summary/references/architecture-template.md`
  to `.claude/skills/repo-to-architecture-summary/templates/architecture-template.md`.
- Update `SKILL.md`, `references/provenance-and-quality.md`, and
  `references/controller-analysis.md` to use the new path.
- Search for remaining active references and update any that would break skill
  usage; preserve historical plan/audit references unless they are intended as
  live navigation.
- Validate the skill structure, links, Markdown, and output-template consumers.

## Acceptance criteria

- The template exists only under `templates/`.
- The skill directly instructs agents to read the new template path.
- No active skill reference points to the removed `references/` path.
- The template contents are unchanged except for any necessary link updates.
- Focused validation passes and generated architecture outputs are untouched.

## Execution record

- Relocated the template byte-for-byte to
  `.claude/skills/repo-to-architecture-summary/templates/architecture-template.md`.
- Updated the core skill and both active reference links; preserved historical
  plan references as historical documentation.
- Independent validation: skill `quick_validate.py` passed, active-reference
  search passed, SHA-256 hashes matched, and scoped `git diff --check` passed.
- Delegated run log: `/tmp/claude-task-runs/agent-driver.jsonl`; reported cost
  `$1.80852525`; generated architecture outputs were untouched.

## Status

Completed and accepted 2026-07-27.
