# Architecture Context Overlays

Overlays are architecture updates that correct or extend the generated architecture docs. They capture facts that emerged between regeneration cycles — version bumps, maturity changes, dependency shifts, platform decisions — so consumers of this repo use current information even when the generated docs haven't caught up yet.

Overlays are consumed by any tooling that reads from this repo (strategy pipelines, architecture reviews, design validation). Each consumer decides how to match and prioritize overlays in its own context.

## When to Write an Overlay

Write an overlay when:
- A component version changed (e.g., SDK bump, upstream release)
- A feature's maturity level shifted (e.g., Dev Preview, GA)
- A dependency was added, removed, or deprecated
- A platform-wide decision was made that affects multiple components
- The generated architecture docs are missing or wrong about something

Do **not** write an overlay for:
- Information already in the current architecture docs — overlays patch gaps, not duplicates
- Corrections scoped to a single downstream artifact — handle those in the consuming tool

## File Format

Each overlay is a Markdown file with YAML frontmatter:

```yaml
---
id: "0001"
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
author: Your Name                 # who created this overlay
superseded_by: null               # set when status changes to superseded
---

## Fact

What changed, in 1-3 sentences. Include the specific version, PR, or decision.

## Impact on Strategies

- Bullet list of how this affects downstream consumers
- Be specific: "use X, not Y" rather than "update references"

## Context

Why this overlay exists. Typically: the generated architecture docs reference
an older state because the newer branch hasn't been analyzed yet.
```

## Naming Convention

`NNNN-short-kebab-description.md`

- `NNNN`: Zero-padded four-digit sequence number (insertion order)
- Description: Kebab-case summary of the fact

Examples:
- `0001-kfp-sdk-2.16-in-rhoai-3.5.md`
- `0002-kale-dev-preview-rhoai-3.5.md`
- `0003-gateway-api-replaces-istio-ingress.md`

## Matching

Consumers match overlays using the frontmatter fields:

1. **Status**: Only `active` overlays are consumed
2. **Release**: Filter by target release version or `"all"`
3. **Component**: Match `affects` list against the components relevant to the consumer's task
4. Overlays with `affects: [platform]` apply to all components

## Lifecycle

- **active**: Consumers read and apply this overlay
- **superseded**: The architecture context has caught up (regenerated with the correct information). Change `status` to `superseded`, set `superseded_by` to explain why. The file stays for audit trail; consumers ignore it.

Mark an overlay superseded when:
- The architecture context is regenerated and includes the fact
- The fact is no longer true (e.g., a version was reverted)
- A newer overlay replaces it with updated information
