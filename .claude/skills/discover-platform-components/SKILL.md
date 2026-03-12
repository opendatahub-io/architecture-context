---
name: discover-platform-components
description: Auto-discover all components of ODH/RHOAI platform, clone repositories, analyze each one, and generate platform architecture. Automates the full analysis workflow.
allowed-tools: Read, Glob, Grep, Write, Bash(gh *), Bash(git *), Bash(ls *), Bash(find *), Bash(mkdir *), Bash(cd *), Skill
disable-model-invocation: true
---

# Discover Platform Components

Automatically discover which repositories are part of the ODH/RHOAI platform, clone them, analyze each component, and aggregate into a platform architecture document.

This skill orchestrates the full workflow:
1. Discover component repositories from GitHub organization
2. Clone repositories to a working directory
3. Run `/repo-to-architecture-summary` on each component
4. Run `/aggregate-platform-architecture` to combine results

## Arguments

Required/optional arguments:
- `--org=<github-org>` (default: opendatahub-io for ODH, red-hat-data-services for RHOAI)
- `--distribution=odh|rhoai` (default: rhoai)
- `--version=X.Y` (default: 3.3)
- `--branch=<branch>` (default: main for ODH, rhoai-X.Y for RHOAI)
- `--output-dir=<path>` (default: ./platform-analysis)

Example: `/discover-platform-components --distribution=rhoai --version=3.3`

## Instructions

Automate the full platform discovery and analysis workflow:

### Step 1: Determine GitHub Organization and Branch

Based on `--distribution`:
- **ODH**: org=`opendatahub-io`, default branch=`main`
- **RHOAI**: org=`red-hat-data-services`, default branch=`rhoai-{version}` (e.g., rhoai-3.3)

### Step 2: Discover Platform Components

Use GitHub CLI to list repositories in the organization:

```bash
gh repo list {org} --limit 200 --json name,description,primaryLanguage
```

Filter for component repositories (exclude docs, tests, tooling):
- Include repos likely to be components: operators, services, dashboards, controllers
- Look for keywords: operator, controller, service, server, dashboard, registry, serving, pipelines, workloads, training, model
- Exclude: documentation, tests, ansible, ci-cd, tooling repos

Use the `opendatahub-operator` repository's configuration to find the canonical list of components:
1. Clone `{org}/opendatahub-operator`
2. Check for component lists in:
   - `config/` directory
   - `components/` directory
   - `manifests/` directory
   - Any YAML files listing components

This gives the authoritative list of what's part of the platform.

### Step 3: Create Working Directory

```bash
mkdir -p {output-dir}/repos
mkdir -p {output-dir}/platform-architecture
cd {output-dir}/repos
```

### Step 4: Clone Component Repositories

For each component identified:

```bash
gh repo clone {org}/{component-repo} {output-dir}/repos/{component-repo}
cd {output-dir}/repos/{component-repo}
git checkout {branch}  # Use specified branch or default
cd {output-dir}/repos
```

Track progress:
- Total components: {count}
- Successfully cloned: {count}
- Failed to clone: {list}

### Step 5: Analyze Each Component

For each cloned repository, run the repo-to-architecture-summary skill:

```bash
cd {output-dir}/repos/{component-repo}
# Invoke the skill (using Skill tool)
/repo-to-architecture-summary --distribution={distribution} --version={version}
```

This creates `GENERATED_ARCHITECTURE.md` in each component's repository.

Track progress:
- Components analyzed: {count}/{total}
- Successful analyses: {count}
- Failed analyses: {list with errors}

### Step 6: Aggregate Platform Architecture

Once all component summaries are generated, aggregate them:

```bash
cd {output-dir}
# Invoke the aggregate skill
/aggregate-platform-architecture --distribution={distribution} --version={version} --repos-dir={output-dir}/repos
```

This creates `{distribution}-{version}-PLATFORM.md` in `{output-dir}/platform-architecture/`

### Step 7: Generate Summary Report

Create a summary file `{output-dir}/DISCOVERY_REPORT.md`:

```markdown
# Platform Component Discovery Report

**Organization**: {org}
**Distribution**: {distribution}
**Version**: {version}
**Branch**: {branch}
**Date**: {current-date}

## Discovery Results

- **Repositories found**: {total-repos}
- **Component repos identified**: {component-count}
- **Repos successfully cloned**: {cloned-count}
- **Components successfully analyzed**: {analyzed-count}
- **Components with errors**: {error-count}

## Components Analyzed

| Component | Status | GENERATED_ARCHITECTURE.md |
|-----------|--------|---------------------------|
| {component1} | ✅ Success | Yes |
| {component2} | ✅ Success | Yes |
| {component3} | ❌ Failed | Error: {error} |

## Platform Architecture

- **Platform architecture file**: `platform-architecture/{distribution}-{version}-PLATFORM.md`
- **Total CRDs**: {count}
- **Total Services**: {count}
- **Total Dependencies**: {count}

## Directory Structure

```
{output-dir}/
├── DISCOVERY_REPORT.md (this file)
├── repos/
│   ├── kserve/
│   │   └── GENERATED_ARCHITECTURE.md
│   ├── odh-dashboard/
│   │   └── GENERATED_ARCHITECTURE.md
│   ├── data-science-pipelines/
│   │   └── GENERATED_ARCHITECTURE.md
│   └── ... (all component repos)
└── platform-architecture/
    └── {distribution}-{version}-PLATFORM.md
```

## Failed Components

{If any components failed, list them here with error details}

| Component | Error |
|-----------|-------|
| {component} | {error message} |

## Next Steps

1. Review platform architecture: `{output-dir}/platform-architecture/{distribution}-{version}-PLATFORM.md`
2. Review individual component summaries in `{output-dir}/repos/*/GENERATED_ARCHITECTURE.md`
3. Fix any failed component analyses (see errors above)
4. Generate diagrams from the structured markdown
5. Share with Architecture Council for review
6. Use for Security Architecture Review (SAR) documentation
```

### Step 8: Report Results

Output a final summary to the user:

```
✅ Platform component discovery complete!

Organization: {org}
Distribution: {distribution}
Version: {version}
Branch: {branch}

Discovered: {total-repos} repositories
Components identified: {component-count}
Successfully cloned: {cloned-count}
Successfully analyzed: {analyzed-count}

Output directory: {output-dir}/
  repos/                  ({component-count} component repos)
    kserve/GENERATED_ARCHITECTURE.md
    dashboard/GENERATED_ARCHITECTURE.md
    ...
  platform-architecture/
    {distribution}-{version}-PLATFORM.md
  DISCOVERY_REPORT.md

Failed components: {error-count}
{List of failed components if any}

Next steps:
1. Review DISCOVERY_REPORT.md for complete analysis
2. Check platform-architecture/{distribution}-{version}-PLATFORM.md
3. Fix any failed component analyses
4. Generate diagrams from structured markdown
```

## Error Handling

Handle common errors gracefully:

1. **GitHub rate limiting**: If hit rate limits, inform user and suggest waiting or using a token
2. **Missing branches**: If branch doesn't exist, try `main` as fallback
3. **Clone failures**: Log error and continue with other components
4. **Analysis failures**: Log error, save partial results, continue with other components
5. **Permission errors**: Check if user has access to private repos (may need `gh auth login`)

## Notes

- This is a long-running operation (may take 10-30 minutes for 70+ components)
- Requires GitHub CLI (`gh`) to be installed and authenticated
- Uses the other two skills internally (repo-to-architecture-summary, aggregate-platform-architecture)
- Creates a self-contained analysis directory with all results
- Can be run multiple times (will re-clone and re-analyze)
- For RHOAI, may need access to private red-hat-data-services repos

## Performance Tips

- Run in background if possible (this is a long operation)
- Consider analyzing a subset first (5-10 components) to validate before running full platform
- Results are cached in the output directory (can review incrementally)
