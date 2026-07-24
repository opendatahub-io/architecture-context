# Plan: Integrate `parse_repo_provenance.py` into the full pipeline

## Context

`parse_repo_provenance.py` maps upstream/midstream/downstream fork relationships across checkout repos using the GitHub API, sync workflow detection, and cross-org name matching. The script exists at `.claude/skills/discover-components/scripts/parse_repo_provenance.py` and is fully functional, but completely orphaned — nothing invokes it, nothing consumes its output, the schema has no place for the data, and arch-query can't query it. This plan wires it into all four integration layers.

## Changes

### 1. Schema — `output-schema.md`
**File:** `.claude/skills/discover-components/references/output-schema.md`

Add a `provenance` top-level section to the JSON structure (same level as `dependency_graph`, `excluded`). Document the nested structure: `provenance.metadata` (generation stats) and `provenance.repos` (keyed by `org/repo`, each with `is_fork`, `upstream`, `upstream_detection`, `downstream`, `downstream_detection`, `sync_mechanism`, `sync_workflows`). Add a note that this section is populated automatically by the harness, not the agent.

### 2. Skill docs — `SKILL.md`
**File:** `.claude/skills/discover-components/SKILL.md`

Add a Step 5.3 after Step 5.2, documenting `parse_repo_provenance.py` with invocation syntax, what it does, and output format. Include a note that the harness merges provenance automatically post-discovery — the agent can optionally invoke it for classification context but does NOT need to write the provenance section.

### 3. Post-processing — `discover.py`
**File:** `lib/phases/discover.py`

Add `_add_provenance(map_file, checkouts_dirs)` function that:
- Runs `parse_repo_provenance.py` via `subprocess.run()` with the resolved `checkouts_dirs`
- Parses stdout JSON
- Sets `generated_at` timestamp
- Merges as `data["provenance"]` into the existing component-map.json
- Warns but does not fail on errors (provenance is supplemental)

Call it right after `_apply_map_overrides()` at line 208. New imports: `subprocess`, `sys`, `datetime`.

### 4. Validation — `validate_component_map.py`
**File:** `.claude/skills/discover-components/scripts/validate_component_map.py`

Add optional provenance validation after the `excluded` block (line 171). When `provenance` key exists:
- Validate `metadata` has expected int fields (`total_repos`, `repos_with_upstream`, `repos_with_downstream`)
- Validate each repo entry: `org`/`repo` are strings, `is_fork` is bool, `downstream`/`sync_workflows` are lists
- Validate enum fields: `upstream_detection` in `{github_api, sync_workflow}`, `downstream_detection` in `{cross_org_match}`, `sync_mechanism` in `{sync_workflow, rebase_workflow, auto_merge, manual}`
- Cross-check `total_repos` matches actual repo count

Add corresponding constant sets: `VALID_UPSTREAM_DETECTION`, `VALID_DOWNSTREAM_DETECTION`, `VALID_SYNC_MECHANISMS`.

### 5. Go types — `types.go`
**File:** `src/arch-query/internal/types/types.go`

Add three types after `VersionData`:
- `ProvenanceRepo` — per-repo fields (`Org`, `Repo`, `IsFork`, `Upstream`, `UpstreamDetection`, `Downstream`, `DownstreamDetection`, `SyncMechanism`, `SyncWorkflows`)
- `ProvenanceMetadata` — summary stats
- `Provenance` — wraps `Metadata` + `Repos map[string]ProvenanceRepo`

Add `Provenance *Provenance` field to `VersionData`.

### 6. Loader — `loader.go`
**File:** `src/arch-query/internal/loader/loader.go`

Add `loadProvenance(fsys, versionDir)` following the `loadBuildInfo` pattern — reads `component-map.json`, unmarshals only the `provenance` key via an anonymous wrapper struct. Wire into `LoadVersion()` after `loadBuildInfo`.

Add `LoadComponentRepoMapping(fsys, versionDir)` (exported) — reads `component-map.json`, builds `map[string]string` from component key to `org/repo`. Used by the provenance subcommand for component-name lookups.

### 7. Subcommand — `provenance.go` (new)
**File:** `src/arch-query/cmd/provenance.go`

New Cobra subcommand following the `ports.go` pattern:
- `arch-query provenance` — lists all repos with provenance data (tab-writer: ORG/REPO, UPSTREAM, SYNC, DOWNSTREAM)
- `arch-query provenance <component>` — single-component lookup (resolves component name → org/repo via `LoadComponentRepoMapping`)
- `arch-query provenance <org/repo>` — direct repo lookup
- `--upstream-only` flag — filter to repos that have an upstream
- `-o json` — JSON output

## Verification

1. **Python changes:** Run `python .claude/skills/discover-components/scripts/validate_component_map.py architecture/odh/component-map.json` before and after adding provenance to confirm validation passes
2. **Post-processing:** Run `python .claude/skills/discover-components/scripts/parse_repo_provenance.py` against a checkouts dir to confirm JSON output, then verify the merge logic writes it correctly into component-map.json
3. **Go changes:** `cd src/arch-query && go build ./...` to confirm compilation, then `go test ./...` to run existing tests
4. **End-to-end:** Run `arch-query provenance` and `arch-query provenance kserve` against an architecture directory that has provenance data
