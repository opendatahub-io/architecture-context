---
name: analyze-platform-components
description: Analyze all components for a platform (ODH or RHOAI) sequentially by parsing get_all_manifests.sh and executing repo-to-architecture-summary for each. Skips components that already have GENERATED_ARCHITECTURE.md. Fully autonomous and resumable.
allowed-tools: Read, Write, Bash(python *), Glob, Grep
---

# Analyze Platform Components

Automatically discover and analyze all components for ODH or RHOAI by:
1. Parsing `get_all_manifests.sh` from the operator repository to get the authoritative component list
2. Reading the `repo-to-architecture-summary` skill instructions once
3. For each component (sequentially):
   - Skip if `GENERATED_ARCHITECTURE.md` already exists (resumable!)
   - Execute the analysis instructions directly
   - Write `GENERATED_ARCHITECTURE.md`
   - Report progress
4. User grants **Write permission once** at the start

This is a fully autonomous, resumable process. Can be interrupted (Ctrl-C) and restarted - it skips already-completed components.

## Arguments

Required:
- `--platform=odh|rhoai` - Platform to analyze

Optional:
- `--checkouts-dir=<path>` (default: ./checkouts)
- `--filter=<pattern>` - Only analyze components matching pattern (e.g., "kserve", "model*")

Examples:
```bash
# Analyze all ODH components in parallel
/analyze-platform-components --platform=odh

# Analyze all RHOAI components
/analyze-platform-components --platform=rhoai

# Analyze specific components only
/analyze-platform-components --platform=odh --filter=kserve
/analyze-platform-components --platform=odh --filter="model*"
```

## Instructions

This skill uses parallel sub-agents to analyze multiple components simultaneously.

### Step 1: Parse Component List

Use the Python script to discover components from `get_all_manifests.sh`:

```bash
python scripts/parse_manifests_script.py --platform={platform} --checkouts-dir={checkouts-dir} --format=paths
```

This returns a list of checkout paths for all components defined in the operator's manifest script.

**Example output**:
```
checkouts/opendatahub-io/kserve
checkouts/opendatahub-io/odh-dashboard
checkouts/opendatahub-io/model-registry-operator
...
```

If no components found, output error and stop:
```
⚠️  No component checkouts found for {PLATFORM}

Make sure components are checked out in {checkouts-dir}/{platform-org}/

Platform org:
- ODH: opendatahub-io
- RHOAI: red-hat-data-services
```

### Step 2: Apply Filter (if provided)

If `--filter` is provided, filter the component list:
- Simple match: `--filter=kserve` matches "kserve" exactly
- Glob pattern: `--filter="model*"` matches "model-registry-operator", "odh-model-controller", etc.

### Step 3: Read the repo-to-architecture-summary Skill Instructions

Read the skill file to get the complete instructions that will be executed for each component:

```bash
cat .claude/skills/repo-to-architecture-summary/SKILL.md
```

Extract the ## Instructions section and all its content. Store this in memory for the loop.

### Step 4: Process Each Component Sequentially

For each component path (in order):

#### 4a. Check if Already Completed

```bash
ls {component_path}/GENERATED_ARCHITECTURE.md
```

If the file exists:
- Print: `⏭️  Skipping {component_name} (already analyzed)`
- Continue to next component

If the file doesn't exist:
- Print: `🔍 Analyzing {component_name} ({current}/{total})...`
- Proceed with analysis

#### 4b. Execute Analysis Instructions

For components that need analysis, execute the full `repo-to-architecture-summary` instructions:

**Key substitutions when executing instructions**:
- Repository path: `{component_path}`
- Distribution: Auto-detect (ODH if path contains `opendatahub-io`, RHOAI if path contains `red-hat-data-services`)
- Version: Auto-detect from Makefile (follow the skill's version detection logic)
- Output file: `{component_path}/GENERATED_ARCHITECTURE.md`

Execute each step of the skill instructions:
1. Discover repository structure (in component_path)
2. Prepare repository (run `make get-manifests` for opendatahub-operator only)
3. Analyze code artifacts
4. Extract recent changes
5. Generate GENERATED_ARCHITECTURE.md with structured tables
6. **Write the file** using the Write tool

#### 4c. Report Progress

After completing each component:
```
✅ Completed {component_name} ({current}/{total})
   Created: {component_path}/GENERATED_ARCHITECTURE.md
```

### Step 5: Report Final Summary

After processing all components, output a summary:

```
================================================================================
✅ Platform component analysis complete!
================================================================================

Platform: {PLATFORM}
Total components: {total_count}
Already completed: {skipped_count}
Newly analyzed: {analyzed_count}

Components analyzed:
✅ {component1}
✅ {component2}
✅ {component3}
...

Components skipped (already had GENERATED_ARCHITECTURE.md):
⏭️  {skipped1}
⏭️  {skipped2}
...

Output location: Each component's checkout directory

Next steps:
1. Collect architectures: /collect-component-architectures
2. Aggregate platform: /aggregate-platform-architecture --distribution={platform} --version={version}
3. Generate diagrams: /generate-platform-diagrams
```

## Example Workflow

```bash
# 1. Analyze all ODH components (sequential, resumable)
/analyze-platform-components --platform=odh
# Grants Write permission once, then analyzes each component
# Creates GENERATED_ARCHITECTURE.md in each component checkout

# 2. Collect all generated architectures
/collect-component-architectures

# 3. Aggregate into platform view
/aggregate-platform-architecture --distribution=odh --version=3.3.0

# 4. Generate platform diagrams
/generate-platform-diagrams
```

### Resumable Workflow

```bash
# Start analysis
/analyze-platform-components --platform=odh

# ... Ctrl-C after 5 components ...

# Resume later - skips the 5 completed, continues with remaining 11
/analyze-platform-components --platform=odh
```

## Notes

### Sequential Processing

- Components are analyzed one-by-one (not parallel)
- **Resumable**: Skips components that already have `GENERATED_ARCHITECTURE.md`
- Can be interrupted (Ctrl-C) and restarted safely
- Progress reported after each component

### Component Discovery

- Component list comes from `get_all_manifests.sh` in the operator repository
- Only components with checkouts are analyzed
- Filters out components that aren't checked out locally

### Permission Handling

- **User grants Write permission ONCE** at the start of the skill
- No additional permission prompts during execution
- Much simpler than granting permission 16 times (one per component)

### Autonomous Operation

- No user input required during analysis
- Each component analyzed in isolation
- Failures in one component don't stop others
- **Main skill executes instructions directly** (no sub-agents needed)

### Output Location

Each component analysis creates `GENERATED_ARCHITECTURE.md` in its checkout directory:
```
checkouts/opendatahub-io/
├── kserve/
│   └── GENERATED_ARCHITECTURE.md        ← Created by agent
├── odh-dashboard/
│   └── GENERATED_ARCHITECTURE.md        ← Created by agent
└── model-registry-operator/
    └── GENERATED_ARCHITECTURE.md        ← Created by agent
```

Run `/collect-component-architectures` to organize these into `architecture/{platform}-{version}/`.

### Resource Usage

- Sequential processing (one component at a time)
- Lower resource usage than parallel approach
- Can run in background while you do other work
- Use `--filter` for analyzing specific components only

### Error Handling

- Each component processed independently
- If one component fails, skill continues with next component
- Failed components can be re-analyzed by deleting their `GENERATED_ARCHITECTURE.md` and re-running the skill
- Or analyze specific failed components manually:
  ```bash
  /repo-to-architecture-summary checkouts/opendatahub-io/kserve
  ```
- Progress is preserved - can resume after fixing issues

## Comparison with Manual Approach

| Approach | Time | Permissions | Resumable | User Interaction |
|----------|------|-------------|-----------|------------------|
| Manual | Sequential (hours) | 16 prompts | No | Must babysit |
| This Skill | Sequential (hours) | 1 prompt | **Yes** | Set and forget |

### Manual (old way):
```bash
/repo-to-architecture-summary checkouts/opendatahub-io/kserve
# Grant Write permission...
# Wait for completion...
/repo-to-architecture-summary checkouts/opendatahub-io/odh-dashboard
# Grant Write permission again...
# Wait for completion...
# ... repeat 14 more times (16 total permission grants!) ...
```

### Automated (this skill):
```bash
/analyze-platform-components --platform=odh
# Grant Write permission ONCE
# Analyzes all 16 components sequentially
# Can Ctrl-C and resume later
# Skips already-completed components automatically
```

**Key Benefits**:
- ✅ One permission grant vs 16
- ✅ Resumable (Ctrl-C safe)
- ✅ Automatic component discovery from operator manifest
- ✅ Progress tracking
- ✅ No babysitting required
