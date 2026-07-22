# ADR-0005: Architecture Context Overlays for Between-Cycle Updates

## Status

Accepted

## Date

2026-04-20

## Context

The architecture pipeline generates comprehensive documentation for each RHOAI version, but full regeneration is expensive (cloning 70+ repos, running agents, aggregating). Between regeneration cycles, architecture-relevant changes occur continuously: version bumps, component renames, new capabilities, deprecations.

Without a way to record these changes, generated architecture docs would be stale until the next full pipeline run. Teams needed a lightweight mechanism to contribute architectural updates without re-running the entire pipeline.

## Decision

Introduce an `overlays/` directory containing numbered markdown files with YAML frontmatter. Each overlay records a single architectural fact that supplements or supersedes generated architecture docs.

Format:
- YAML frontmatter: `id`, `title`, `status` (active/superseded), `created`, `affects` (component list), `release` (version list), `provenance` (source links), `author`, `superseded_by`
- Markdown body: `## Fact` (what changed), `## Impact on Strategies` (implications)
- 4-digit IDs (`0001`, `0002`, ...) for consistent ordering

Overlays are:
- Human-authored (primarily by engineers and architects)
- Community-contributed via PRs (external contributors submit overlays for their components)
- Machine-consumed (agents read overlays to augment architecture context)
- Validated by CI (`lint_overlays.py` checks frontmatter schema)
- Documented in `AGENT_USAGE.md` for agent consumption

## Consequences

Positive:
- Architecture context stays current between regeneration cycles
- Low barrier to contribution (a single markdown file, no pipeline run needed)
- External teams (CodeFlare, KServe, Model Runtimes, AIPCC) began contributing overlays via PRs
- Overlays have provenance links to upstream PRs/issues for traceability
- `superseded_by` field allows clean lifecycle management

Negative:
- Overlays can accumulate; need periodic reconciliation with regenerated docs
- No automated mechanism to detect when an overlay is stale vs. the generated docs
- Dual numbering (overlay IDs vs ADR IDs) can be confusing
