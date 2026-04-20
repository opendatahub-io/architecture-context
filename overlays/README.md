# Architecture Context Overlays

Overlays are architectural patches that apply across all strategy documents. They capture facts that emerged between architecture context regeneration cycles — version bumps, maturity changes, dependency shifts, platform decisions — so the strategy pipeline uses current information even when the generated architecture docs haven't caught up yet.

## When to Write an Overlay

Write an overlay when:
- A component version changed (e.g., SDK bump, upstream release)
- A feature's maturity level shifted (e.g., Dev Preview, GA)
- A dependency was added, removed, or deprecated
- A platform-wide decision was made that affects multiple strategies
- The generated architecture docs are missing or wrong about something

Do **not** write an overlay for:
- Strategy-specific corrections — use `## Staff Engineer Input` in the strategy file
- Information already in the current architecture docs — overlays patch gaps, not duplicates

## Priority Chain

Overlays sit in the middle of the input priority chain for strategy refinement:

1. **Staff Engineer Input** — per-strategy, human-authored (highest priority)
2. **Architecture Context Overlays** — cross-strategy corrections (this)
3. **Removed RFE Context** — per-RFE implementation details
4. **Architecture Context** — generated platform docs (lowest priority)

Staff Engineer Input in a specific strategy can override an overlay. Overlays override the generated architecture context.

## File Format

Each overlay is a Markdown file with YAML frontmatter:

```yaml
---
id: "001"
title: Short description of the fact
status: active                    # active | superseded
created: 2026-04-20
affects:                          # component names matching architecture/*.md
  - data-science-pipelines
  - notebooks
release:                          # RHOAI releases this applies to
  - "3.5"                         # use "all" for timeless facts
provenance:                       # links to PRs, issues, decisions
  - https://github.com/org/repo/pull/123
superseded_by: null               # set when status changes to superseded
---

## Fact

What changed, in 1-3 sentences. Include the specific version, PR, or decision.

## Impact on Strategies

- Bullet list of what strategies should do differently
- Be specific: "use X, not Y" rather than "update references"

## Context

Why this overlay exists. Typically: the generated architecture docs reference
an older state because the newer branch hasn't been analyzed yet.
```

## Frontmatter Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `id` | Yes | string | Three-digit sequence number (`"001"`, `"002"`, ...) |
| `title` | Yes | string | Short description of the architectural fact |
| `status` | Yes | enum | `active` (pipeline reads it) or `superseded` (pipeline ignores it) |
| `created` | Yes | string | Date created (YYYY-MM-DD) |
| `affects` | Yes | list | Component names from `architecture/*.md`. Use `platform` for all strategies |
| `release` | Yes | list | RHOAI release versions (e.g., `["3.5"]`). Use `["all"]` for timeless facts |
| `provenance` | Yes | list | URLs to PRs, issues, or decisions establishing this fact |
| `superseded_by` | No | string | Explanation or link when marking as superseded |

## Naming Convention

`NNN-short-kebab-description.md`

- `NNN`: Zero-padded three-digit sequence number (insertion order)
- Description: Kebab-case summary of the fact

Examples:
- `001-kfp-sdk-2.16-in-rhoai-3.5.md`
- `002-kale-dev-preview-rhoai-3.5.md`
- `003-gateway-api-replaces-istio-ingress.md`

## Pipeline Matching

The strategy pipeline matches overlays to strategies using **component intersection**:

1. Read all overlay files with `status: active`
2. Filter by `release` — overlay's release list must include the target release or `"all"`
3. Match `affects` — overlay's component list must intersect with the strategy's Affected Components table
4. Overlays with `affects: [platform]` match all strategies

Matched overlays' `## Fact` and `## Impact on Strategies` sections are injected into the refinement and review context.

## Lifecycle

- **active**: The pipeline reads and applies this overlay during refine and review
- **superseded**: The architecture context has caught up (regenerated with the correct information). Change `status` to `superseded`, set `superseded_by` to explain why. The file stays for audit trail; the pipeline ignores it.

Mark an overlay superseded when:
- The architecture context is regenerated and includes the fact
- The fact is no longer true (e.g., a version was reverted)
- A newer overlay replaces it with updated information
