# Plan: Integrate Central Sync Config into Discovery & Provenance

## Problem

The provenance system currently detects sync mechanisms by scanning each repo's `.github/workflows/` directory for filenames containing "sync", "rebase", or "upstream". This misses the centralized sync infrastructure used by RHOAI: all ODH ↔ RHDS sync is managed by `red-hat-data-services/rhods-devops-infra`, not by per-repo workflows. As a result, most downstream repos show `sync_mechanism: "manual"` when they're actually `auto_merge` on a 4-hour cadence.

Beyond provenance accuracy, the sync config is a curated manifest of "repos that matter enough to ship downstream." That's a stronger signal for component discovery than anything the LLM agent can infer. If a repo has a sync config entry, it's almost certainly a real component — we can pre-seed it and skip the expensive agent classification.

## Data Source

`rhods-devops-infra/src/config/upstream-source-map.yaml` — 58 entries, each with:

```yaml
- name: kserve                       # sync rule name
  automerge: 'no'                    # 'yes' = centralized auto_merge, 'no' = manual or disabled
  manual-sync: 'yes'                 # optional: explicit manual flag
  ignore-files: .tekton/*            # files excluded from sync
  src:
    url: https://github.com/opendatahub-io/kserve.git
    branch: release-v0.17            # upstream branch (varies: main, stable, rhoai, release-*)
  dest:
    url: https://github.com/red-hat-data-services/kserve.git
    branch: main                     # downstream always merges to main
```

Key observations from the data:

- **Multi-hop chains are explicit**: `feast-upstream` (feast-dev → opendatahub-io) + `feast-downstream` (opendatahub-io → red-hat-data-services) show the full 3-tier path
- **Cross-org upstreams revealed**: trustyai-explainability, project-codeflare, foundation-model-stack, ogx-ai, kagenti, llm-d-incubation — orgs the current provenance script doesn't always catch
- **Renamed repos are mapped**: `opendatahub-operator` → `rhods-operator` (currently hardcoded in `KNOWN_DOWNSTREAMS`)
- **Sync mechanism is authoritative**: `automerge: 'yes'` = centralized auto_merge; `automerge: 'no'` + `manual-sync: 'yes'` = manual; `automerge: 'no'` alone = disabled/manual
- **Branch info tells us what's shipped**: repos syncing from `stable` or `rhoai` branches are actively curated

Related config files in the same repo:

| File | What it tells us |
|---|---|
| `main-release-source-map.yaml` | Stage 2: RHDS `main` → `rhoai-x.y` release branches (65 entries) |
| `releases.yaml` | Which release versions are active (currently: `rhoai-3.5`) |
| `rhoai-supported-versions.yaml` | Which versions are supported (EUS, stable, fast) |
| `rhoai-shared-components.yaml` | Shared container images with lifecycle info |

## Changes

### 1. platforms.yaml — Add `sync_config` field

**File:** `platforms.yaml`

Add a new optional field `sync_config` that declares where the central sync configuration lives. This makes the relationship explicit and lets the pipeline find the config automatically.

```yaml
_rhoai_common: &rhoai_common
  orgs:
    - red-hat-data-services
  sync_config:
    org: red-hat-data-services
    repo: rhods-devops-infra
    upstream_map: src/config/upstream-source-map.yaml
  # ... rest unchanged
```

Schema for `sync_config`:

| Field | Type | Required | Description |
|---|---|---|---|
| `org` | string | yes | GitHub org that owns the sync config repo |
| `repo` | string | yes | Repo name within that org |
| `upstream_map` | string | yes | Path within the repo to the upstream source map YAML |

The `odh` platform should also reference this — the sync config is equally relevant when discovering ODH components (it tells us which ODH repos have downstream mirrors):

```yaml
odh:
  suffix: head
  orgs:
    - opendatahub-io
  sync_config:
    org: red-hat-data-services
    repo: rhods-devops-infra
    upstream_map: src/config/upstream-source-map.yaml
  # ... rest unchanged
```

### 2. Lint script — Validate `sync_config`

**File:** `scripts/lint_platforms.py`

- Add `"sync_config"` to `KNOWN_KEYS`
- Add `_check_sync_config(value, errors)` that validates:
  - Must be a dict
  - Required string fields: `org`, `repo`, `upstream_map`
  - `upstream_map` must not contain `..` or start with `/` (path traversal safety, consistent with `exclude_files` checks)

### 3. Fetch phase — Clone sync config repo

**File:** `lib/fetch.py`

After cloning platform orgs/repos, if `sync_config` is present, ensure the sync config repo is cloned into the appropriate checkouts directory. It should be treated like an implicit `extra_repos` entry — clone to `checkouts/{org}.{suffix}/{repo}` if not already present.

The repo may already be cloned if the platform's `orgs` list includes the sync config's org (e.g., RHOAI platforms already clone all of `red-hat-data-services`). The fetch phase should check and skip if it exists.

### 4. New script — `parse_sync_config.py`

**File:** `.claude/skills/discover-components/scripts/parse_sync_config.py`

Parse `upstream-source-map.yaml` and produce structured JSON. This script does NOT replace `parse_repo_provenance.py` — it supplements it with authoritative sync data.

**Input:** Path to `upstream-source-map.yaml`

**Output JSON:**

```json
{
  "metadata": {
    "source_file": "upstream-source-map.yaml",
    "total_sync_rules": 58,
    "auto_merge_count": 48,
    "manual_sync_count": 5
  },
  "sync_rules": [
    {
      "name": "kserve",
      "automerge": false,
      "manual_sync": true,
      "sync_mechanism": "manual",
      "ignore_files": [".tekton/*"],
      "src_org": "opendatahub-io",
      "src_repo": "kserve",
      "src_branch": "release-v0.17",
      "dest_org": "red-hat-data-services",
      "dest_repo": "kserve",
      "dest_branch": "main"
    }
  ],
  "repo_index": {
    "opendatahub-io/kserve": {
      "downstream": ["red-hat-data-services/kserve"],
      "sync_mechanism": "manual",
      "sync_branch": "release-v0.17"
    },
    "red-hat-data-services/kserve": {
      "upstream": "opendatahub-io/kserve",
      "sync_mechanism": "manual",
      "sync_branch": "release-v0.17"
    }
  }
}
```

The `repo_index` is a derived view keyed by `org/repo` — it collapses multi-hop chains and makes lookups fast for both provenance and discovery.

Sync mechanism classification:
- `automerge: 'yes'` → `"auto_merge"`
- `automerge: 'no'` + `manual-sync: 'yes'` → `"manual"`
- `automerge: 'no'` (no manual-sync) → `"manual"`

### 5. Provenance integration — Use sync config as primary source

**File:** `lib/phases/discover.py` (`_add_provenance`)
**File:** `.claude/skills/discover-components/scripts/parse_repo_provenance.py`

Two options for how to integrate:

**Option A (preferred): Merge in `_add_provenance()`**

After running `parse_repo_provenance.py`, load the sync config data and overlay it. For any repo that appears in the sync config's `repo_index`:
- Set `sync_mechanism` from the sync config (overrides the per-repo workflow scan)
- Add `upstream`/`downstream` if not already set
- Set `upstream_detection: "sync_config"` (new enum value)
- Set `downstream_detection: "sync_config"` (new enum value)

This keeps `parse_repo_provenance.py` unchanged and does the merge in the harness.

**Option B: Feed sync config into `parse_repo_provenance.py`**

Pass the sync config path as a CLI arg. The script reads it internally and uses it as a higher-priority source than workflow scanning or KNOWN_UPSTREAMS. This is cleaner but couples the script to the sync config format.

**Recommendation:** Option A. The provenance script stays a general-purpose tool, and the sync config overlay is platform-specific knowledge that belongs in the harness.

Add new detection enum values:
- `VALID_UPSTREAM_DETECTION`: add `"sync_config"`
- `VALID_DOWNSTREAM_DETECTION`: add `"sync_config"`

### 6. Discovery integration — Pre-seed components from sync config

**File:** `lib/phases/discover.py` (`run_discover_components_phase`)

This is the high-value optimization. Before running the expensive agent-based discovery skill:

1. If `sync_config` is defined, parse `upstream-source-map.yaml`
2. Extract the set of repos that have sync rules (either as src or dest, depending on which platform we're discovering)
3. For ODH discovery: repos that appear as `src` in the sync config are high-confidence components
4. For RHOAI discovery: repos that appear as `dest` are high-confidence components
5. Write these as pre-seeded entries in the prompt or as a "hint file" the discovery skill can read

The pre-seeded repos get `discovered_via: "sync_config"` and `confidence: "high"`. The agent skill still runs on ALL repos (including pre-seeded ones) but can focus its expensive analysis on repos NOT in the sync config — these are the ones that need LLM classification (type, tier, architectural significance).

This could be implemented as:
- A new `--pre-seed-file=<path>` arg to the discovery skill that provides a JSON list of known components
- Or simply adding them to `include_components` before the skill runs (but this conflates manual includes with data-driven ones)
- Or a separate post-processing step that merges sync-config repos into the component map after the agent runs (similar to `_apply_map_overrides`)

**Recommendation:** Post-processing merge, consistent with how `_apply_map_overrides` and `_add_provenance` work. Add a new `_apply_sync_config_components()` function that runs before `_apply_map_overrides`:
1. Parse the sync config
2. For each repo in the sync config that maps to a repo in our checkouts:
   - If it's in `excluded`, promote it to `components` (like `include_components` does)
   - If it's already in `components`, leave it alone
   - If it's not in the map at all (missed by the agent), add it with `discovered_via: "sync_config"`

### 7. Schema updates

**File:** `.claude/skills/discover-components/references/output-schema.md`

- Add `"sync_config"` to valid `discovered_via` values
- Add `"sync_config"` to valid `upstream_detection` and `downstream_detection` values
- Document the `sync_config` field in provenance repos

**File:** `.claude/skills/discover-components/scripts/validate_component_map.py`

- Add `"sync_config"` to `VALID_DISCOVERED_VIA`
- Add `"sync_config"` to `VALID_UPSTREAM_DETECTION`
- Add `"sync_config"` to `VALID_DOWNSTREAM_DETECTION`

### 8. KNOWN_UPSTREAMS / KNOWN_DOWNSTREAMS cleanup

**File:** `.claude/skills/discover-components/scripts/parse_repo_provenance.py`

Once sync config integration is working, most entries in `KNOWN_UPSTREAMS` and `KNOWN_DOWNSTREAMS` become redundant — the sync config provides the same data more authoritatively. However, keep the dicts as fallbacks for when:
- The sync config repo isn't cloned (e.g., running provenance standalone)
- A repo's upstream isn't covered by the sync config (community forks not in the RHOAI pipeline)

No entries need to be removed immediately, but document that sync config takes precedence.

### 9. Provenance output — Add sync config source branch

The sync config gives us something provenance currently lacks: which branch the sync operates on. This is architecturally significant (a repo syncing from `stable` vs `main` vs `rhoai` tells you about the release model).

Add an optional `sync_branch` field to the provenance repo schema:

```json
{
  "upstream": "opendatahub-io/kserve",
  "upstream_detection": "sync_config",
  "sync_mechanism": "manual",
  "sync_branch": "release-v0.17"
}
```

### 10. arch-query — Show sync config data in provenance subcommand

**File:** `src/arch-query/cmd/provenance.go`
**File:** `src/arch-query/internal/types/types.go`

Add `SyncBranch` field to `ProvenanceRepo`. Update the table output to show the sync branch when available (e.g., in the single-repo detail view or as a `--verbose` column).

## Implementation Order

1. **parse_sync_config.py** — standalone script, can be tested immediately against the checked-out rhods-devops-infra
2. **platforms.yaml + lint** — add `sync_config` field and validation
3. **fetch.py** — ensure sync config repo gets cloned
4. **discover.py** — wire `_apply_sync_config_components()` post-processing and sync config overlay into `_add_provenance()`
5. **validate + schema** — add new enum values
6. **types.go + provenance.go** — add `SyncBranch`, update display
7. **Test end-to-end** — run discovery on ODH, verify sync config repos are promoted and provenance shows correct sync mechanisms

## Verification

1. `python parse_sync_config.py checkouts/red-hat-data-services.next/rhods-devops-infra/src/config/upstream-source-map.yaml` produces correct JSON
2. `python scripts/lint_platforms.py` passes with updated platforms.yaml
3. After discovery: repos in the sync config appear as components with `discovered_via: "sync_config"` or have correct provenance sync mechanisms
4. `arch-query provenance kserve` shows `sync_mechanism: manual` and `sync_branch: release-v0.17` (not the incorrect `manual` from workflow scanning)
5. `arch-query provenance` table shows `auto_merge` for most RHDS downstream repos instead of `manual`
