# Plan: Add Provenance Section to Architecture Template

## Goal

Add a `## Provenance` section to the `GENERATED_ARCHITECTURE.md` template so that every component's architecture summary includes its upstream/midstream/downstream repo lineage and any name aliases. This makes the supply chain visible per-component without requiring a separate `arch-query provenance` lookup.

## Context

Provenance data already exists in `component-map.json` (under the `"provenance"` key) and is queryable via `arch-query provenance`. But the per-component `GENERATED_ARCHITECTURE.md` files -- the primary artifact consumed by architects and agents -- have no provenance information. An architect reading the kserve architecture summary cannot see that `opendatahub-io/kserve` is a fork of `kserve/kserve` synced via workflow, or that `red-hat-data-services/kserve` is the downstream. They also cannot see historical name aliases (e.g., `llama-stack-k8s-operator` → `ogx-k8s-operator`).

## Acceptance Criteria

- [ ] Architecture template (`references/architecture-template.md`) contains a new `## Provenance` section with tables for repo lineage and aliases
- [ ] SKILL.md updated with instructions for how the agent populates the provenance section during analysis
- [ ] Validation script (`scripts/validate_architecture.py`) updated to recognize the new section
- [ ] The section is useful when provenance data is NOT available (agent falls back to git remote + fork detection from the repo being analyzed)

## Design

### New Template Section

Place `## Provenance` after `## Metadata` and before `## Purpose`. Rationale: provenance is identity-level information ("what is this repo and where did it come from") that contextualizes everything that follows.

#### Repo Lineage Table

| Role | Repository | Sync Mechanism | Sync Branch | Sync Workflows | Detection Method |
|------|-----------|----------------|-------------|----------------|------------------|
| Upstream | https://github.com/kserve/kserve | -- | -- | -- | github_api |
| Midstream | https://github.com/opendatahub-io/kserve | sync_workflow | main | `sync-upstream.yaml` | sync_workflow |
| Downstream | https://github.com/red-hat-data-services/kserve | auto_merge | rhoai-staging | -- | cross_org_match |

- **Role**: `Upstream`, `Midstream`, `Downstream` -- the three-tier model matching `repoRole()` in `cmd/provenance.go`
- **Repository**: full URL (e.g., `https://github.com/org/repo`) -- no assumptions about hosting platform
- **Sync Mechanism**: `sync_workflow`, `rebase_workflow`, `auto_merge`, `manual`, or `--` for the origin
- **Sync Branch**: branch used for sync, or `--`
- **Sync Workflows**: CI workflow filenames that perform the sync (e.g., `sync-upstream.yaml`), or `--` if none. Helps engineers find the actual automation.
- **Detection Method**: how the relationship was discovered (`github_api`, `sync_workflow`, `known_mapping`, `cross_org_match`, `sync_config`)

When provenance data is unavailable (no `component-map.json` with provenance, or running the skill standalone), the agent should populate what it can from:
1. `git remote -v` (the repo being analyzed)
2. GitHub fork metadata visible in the repo itself
3. `.github/workflows/sync*.yaml` files in the checkout

In that fallback case, Detection Method should be `local_analysis`.

#### Aliases Table

| Current Name | Previous Name | Type | Context |
|--------------|--------------|------|---------|
| `ogx` | `llama-stack` | rename | Renamed in opendatahub-io and upstream orgs circa 2026 |
| `agents-operator` | `kagenti-extensions` | upstream_name_differs | Upstream repo `kagenti/kagenti-extensions` forked as `opendatahub-io/agents-operator` |

- **Current Name**: the repo name as it exists now
- **Previous Name**: the former name, or the differing upstream name
- **Type**: `rename` (repo was renamed), `upstream_name_differs` (fork has a different name than upstream), `archive` (old repo archived, new one created)
- **Context**: brief explanation of when/why

When no aliases exist, keep the heading and table header but omit data rows (consistent with other empty-when-no-data sections in the template).

### Data Sources for the Agent

The agent populating this section has two paths:

1. **Provenance data available** (orchestrator passes component-map.json path or the agent is running inside the architecture-context tree): Look up the component's `org/repo` in `component-map.json → provenance.repos`, extract the chain, and render the table directly. Aliases can be inferred from upstream name mismatches.

2. **No provenance data** (standalone `/repo-to-architecture-summary` on a bare checkout): Use git remote, scan for sync workflows, check if the GitHub repo page indicates a fork. This produces a partial table -- which is still valuable.

### SKILL.md Changes

Add a new step between the current Step 5 (Git Information) and Step 6 (Generate):

**Step 5a: Provenance Analysis**

Instructions for the agent:
1. Check if `component-map.json` is accessible (either passed via context or in a known location)
2. If yes: extract provenance for this component's `org/repo` key from the `provenance.repos` map
3. If no: fall back to local repo analysis (git remote, sync workflow scanning)
4. Detect aliases using both heuristics and explicit mappings:
   - **Auto-detect**: compare upstream repo name vs midstream repo name (e.g., `kagenti-extensions` → `agents-operator`); scan for `-legacy` or `-archive` suffixed sibling repos in the same org
   - **Known aliases**: consult `KNOWN_NAME_ALIASES` from `parse_repo_provenance.py` for cases heuristics miss (e.g., `llama-stack` → `ogx`)
5. Populate the Provenance section tables

### Validation Script Changes

Update `validate_architecture.py` to:
- Accept `## Provenance` as a valid section heading
- Validate it appears after `## Metadata` and before `## Purpose`
- Check that the Repo Lineage table has the expected columns if present

## Files to Modify

| File | Change |
|------|--------|
| `.claude/skills/repo-to-architecture-summary/references/architecture-template.md` | Add `## Provenance` section with Repo Lineage and Aliases tables |
| `.claude/skills/repo-to-architecture-summary/SKILL.md` | Add Step 5a with provenance analysis instructions |
| `.claude/skills/repo-to-architecture-summary/scripts/validate_architecture.py` | Add `Provenance` to known sections, validate column headers |

## Resolved Questions

1. **Include sync workflow filenames?** Yes -- added as a `Sync Workflows` column in the Repo Lineage table. Helps engineers find the actual automation.
2. **Alias detection strategy?** Both -- auto-detect from `-legacy`/`-archive` suffixed repos AND from upstream name mismatches, plus consult an explicit known-aliases list (e.g., `KNOWN_NAME_ALIASES` in `parse_repo_provenance.py`) as a fallback for cases that heuristics miss.

## Status

Done
