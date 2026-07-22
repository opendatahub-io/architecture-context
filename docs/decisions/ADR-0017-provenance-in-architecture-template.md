# ADR-0017: Provenance Section in Per-Component Architecture Template

## Status

Accepted

## Date

2026-07-22

## Context

ADR-0016 introduced provenance discovery — mapping upstream/midstream/downstream repo relationships and storing them in `component-map.json`. This data is queryable via `arch-query provenance`, but the per-component `GENERATED_ARCHITECTURE.md` files (the primary artifact consumed by architects and agents) contain no provenance information. An architect reading a component's architecture summary cannot see its supply chain lineage or historical name aliases without a separate tool invocation.

Additionally, repos are frequently renamed (e.g., `llama-stack` → `ogx`) or forked under different names (e.g., `kagenti/kagenti-extensions` → `opendatahub-io/agents-operator`). These aliases are not captured anywhere in the architecture documents, creating confusion when engineers encounter references to old names in issues, docs, or CI configs.

## Decision

Add a `## Provenance` section to the `GENERATED_ARCHITECTURE.md` template, placed after `## Metadata` and before `## Purpose`. It contains two subsections:

**Repo Lineage** — a table showing the upstream/midstream/downstream chain with full repository URLs, sync mechanisms, sync branches, sync workflow filenames, and detection methods.

**Aliases** — a table capturing current vs previous repo names with type (`rename`, `upstream_name_differs`, `archive`) and context. Aliases are detected using both heuristics (name mismatches between upstream and midstream, `-legacy`/`-archive` suffixed repos) and an explicit known-aliases list from `parse_repo_provenance.py`.

The section supports two data paths: structured provenance from `component-map.json` when available, or local fallback via `git remote -v` and sync workflow scanning when running the skill standalone on a bare checkout.

Repository values use full URLs (`https://github.com/org/repo`) rather than `org/repo` shorthand to avoid assumptions about hosting platform.

## Consequences

Positive:
- Supply chain lineage visible inline in every component's architecture summary
- Name aliases prevent confusion when repos are renamed or forked under different names
- Works in degraded mode without `component-map.json` — partial data is still valuable
- Validation script enforces section placement and table column headers

Negative:
- Adds another section that agents must populate, increasing generation time slightly
- Alias detection heuristics may miss uncommon renaming patterns not covered by the known-aliases list
