# Plan: Glob Branch Resolution for extra_repos

## Goal

Allow `extra_repos` entries in `platforms.yaml` to specify a branch glob
pattern (e.g., `release-*`) instead of a literal branch name. The pipeline
resolves the pattern at fetch time by querying remote refs and selecting the
latest matching branch using numeric version sorting.

Immediate use case: add `openshift/kueue-operator` to the `_rhoai_3x_common`
base template with `branch: "release-*"`, so each pipeline run automatically
clones the latest `release-X.Y` branch without manual pin updates.

## Context

Branch values in `platforms.yaml` are currently literal strings passed directly
to `git clone -b`. There is no template expansion, pattern matching, or version
sorting. The `_clone_repo` function in `lib/fetch.py` (line 406) receives the
branch string and passes it verbatim to `git clone`. If the branch does not
exist, the clone is silently skipped (line 474).

The `openshift/kueue-operator` repo uses `release-X.Y` branches (e.g.,
`release-1.2`, `release-1.10`). Pinning a literal branch means every new
release requires a platforms.yaml update. A glob pattern lets the pipeline
self-resolve to the latest.

## Acceptance Criteria

- [ ] `platforms.yaml` supports glob characters (`*`, `?`) in `branch` values
      for `extra_repos` entries
- [ ] When a glob branch is specified, the pipeline queries remote refs,
      sorts matches by the numeric version suffix, and clones the latest
- [ ] `openshift/kueue-operator` is added to `_rhoai_3x_common.extra_repos`
      with `branch: "release-*"`
- [ ] `kueue-operator` is added to `include_components` in platforms that
      use the 3.x common template
- [ ] `scripts/lint_platforms.py` accepts glob characters in branch values
- [ ] Sorting is numeric (so `release-1.10` sorts after `release-1.2`)
- [ ] Resolution failure (no matching branches) logs a message and skips
      the repo, matching existing behavior for missing literal branches
- [ ] The resolved branch name is logged so runs are reproducible

## Design

### 1. New helper: `_resolve_branch_glob`

Add to `lib/fetch.py`:

```python
async def _resolve_branch_glob(
    org: str,
    repo: str,
    pattern: str,
    protocol: str = "https",
) -> str | None:
    """Resolve a branch glob pattern to the latest matching branch.

    Queries remote refs with `git ls-remote --heads`, filters by the glob
    pattern, sorts by the numeric version suffix, and returns the latest.
    Returns None if no branches match.
    """
```

Implementation notes:

- Run `git ls-remote --heads <url> '<pattern>'` to get matching refs.
  The glob is passed to ls-remote so filtering happens server-side.
- Parse each ref to extract the branch name (`refs/heads/release-1.10`
  becomes `release-1.10`).
- Extract the version suffix after the last `-` (or after a known prefix
  like `release-`). Split on `.` and compare each segment as an integer.
  Use `packaging.version.Version` if available, otherwise a simple
  tuple-of-ints comparison on the numeric suffix.
- Return the branch name with the highest version, or `None` if no
  matches.

Sort key example for `release-X.Y`:
```python
def _version_sort_key(branch: str) -> tuple:
    # "release-1.10" -> (1, 10)
    suffix = branch.rsplit("-", 1)[-1]
    parts = suffix.split(".")
    return tuple(int(p) for p in parts if p.isdigit())
```

This handles `release-1.2` vs `release-1.10` correctly because it
compares `(1, 2)` vs `(1, 10)` numerically.

### 2. Call site: `_clone_repo`

In `_clone_repo` (`lib/fetch.py`, line 406), before the `git clone`
subprocess call:

```python
if branch and any(c in branch for c in ("*", "?")):
    resolved = await _resolve_branch_glob(org, repo, branch, protocol)
    if resolved is None:
        _log(f"  Skipped {org}/{repo} (no branches match '{branch}')")
        return
    _log(f"  {org}/{repo}: resolved '{branch}' -> '{resolved}'")
    branch = resolved
```

This goes after the URL construction (line 448) and before the
`cmd = ["git", "clone"]` line (line 457). The rest of `_clone_repo`
uses the resolved literal branch unchanged.

### 3. Linter update: `scripts/lint_platforms.py`

In `_check_extra_repos` (line 127), the branch validation currently
only checks `isinstance(entry[opt], str)`. No change needed for type
validation — glob patterns are strings. However, add a note in the
platform header comment in `platforms.yaml` documenting that branch
supports glob patterns.

If the linter ever gains branch-existence checks, those must skip
glob patterns.

### 4. platforms.yaml changes

**How `extra_repos` and `include_components` relate:** `extra_repos`
tells the fetch phase to clone a repo. But discovery classifies repos
from non-primary orgs as "excluded." `include_components` promotes an
excluded repo back into the component map so it actually gets analyzed.
They must always be paired for cross-org repos — without
`include_components`, the repo is cloned but never processed.

Add `kueue-operator` to `_rhoai_3x_common.extra_repos` (line 60):

```yaml
_rhoai_3x_common: &rhoai_3x_common
  <<: *rhoai_common
  extra_orgs:
    - org: llm-d
  extra_repos:
    - org: project-codeflare
      repo: codeflare-sdk
    - org: opendatahub-io
      repo: kubeflow-sdk
    - org: openshift
      repo: kueue-operator
      branch: "release-*"
    - org: red-hat-data-services
      repo: models-perf-benchmark-data
      protocol: ssh
      exclude_files:
        - "data/"
```

Add `kueue-operator` to `include_components` in each platform config
that inherits `_rhoai_3x_common` and has its own `include_components`
(since YAML merge does not deep-merge lists):

```yaml
  include_components:
    - key: kueue-operator
      repo_org: openshift
      repo_name: kueue-operator
      type: operator
```

This needs to be added to: `rhoai.next`, `rhoai-3.6-ea.1`, `rhoai-3.5`,
`rhoai-3.5-ea.2`, `rhoai-3.5-ea.1`, `rhoai-3.4`, `rhoai-3.4-ea.2`,
`rhoai-3.4-ea.1`. The older platforms (`rhoai-3.3`, `rhoai-3.2`,
`rhoai-3.0`) inherit `extra_repos` from the anchor without override,
so they get it automatically — but they will also need
`include_components` if they don't already declare it.

### 5. Update platforms.yaml header comment

Add to the `branch` field documentation (line 8):

```yaml
##   branch            - specific branch to clone (skips repos without it)
##                       supports glob patterns (e.g., "release-*") which
##                       resolve to the latest matching branch by version sort
```

## Files to modify

| File | Change |
|---|---|
| `lib/fetch.py` | Add `_resolve_branch_glob`, call it from `_clone_repo` |
| `platforms.yaml` | Add kueue-operator entry, update header comment |
| `scripts/lint_platforms.py` | No code change needed, but verify glob patterns pass |

## Testing

- Unit test `_resolve_branch_glob` with mocked `git ls-remote` output
  containing `release-1.2`, `release-1.10`, `release-1.9` — verify it
  returns `release-1.10`.
- Unit test the sort key with edge cases: single-segment (`release-2`),
  multi-segment (`release-1.10.3`), non-numeric suffix (ignored/sorted
  last).
- Integration: run `python -c "..."` calling `_resolve_branch_glob`
  against `openshift/kueue-operator` to verify it resolves correctly.
- Run `make lint` to confirm `lint_platforms.py` accepts the glob branch.

## Risks

- **Network dependency at fetch time**: `git ls-remote` adds an extra
  network call per glob branch. This is one call per glob entry, not per
  platform, so the impact is minimal.
- **Ambiguous sort for non-semver branches**: If a repo has branches like
  `release-main` alongside `release-1.2`, the version extraction must
  handle non-numeric suffixes gracefully (skip them or sort them last).
- **Reproducibility**: Two runs on different days may clone different
  branches if a new release branch appears. The resolved branch is logged,
  and the checkout directory records what was actually cloned. Consider
  logging the resolved branch to a machine-readable location (e.g., the
  fetch log) for audit purposes.
