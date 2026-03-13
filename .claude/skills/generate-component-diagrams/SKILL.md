---
name: generate-component-diagrams
description: Generate diagrams for all component architecture files in an organized architecture directory. Processes each component sequentially, creating Mermaid, C4, and security diagrams. Skips components that already have diagrams.
allowed-tools: Read, Glob, Bash(python scripts/generate_diagram_pngs.py *), Bash(ls *), Bash(mkdir *)
disable-model-invocation: false
---

# Generate Component Diagrams

Automatically generate diagrams for all component architecture files in an organized architecture directory (e.g., `architecture/odh-3.3.0/`).

## Arguments

Required:
- `--architecture-dir=<path>` - Path to architecture directory (e.g., `architecture/odh-3.3.0/`)

Optional:
- `--skip-existing` - Skip components that already have diagrams (default: false)
- `--formats=<comma-separated>` - Specific formats to generate (default: all)

Examples:
```bash
# Generate diagrams for all components
/generate-component-diagrams --architecture-dir=architecture/odh-3.3.0/

# Skip components that already have diagrams (resumable)
/generate-component-diagrams --architecture-dir=architecture/odh-3.3.0/ --skip-existing

# Generate only specific formats
/generate-component-diagrams --architecture-dir=architecture/odh-3.3.0/ --formats=mermaid,security
```

## Instructions

**CRITICAL**: This skill processes components SEQUENTIALLY in a single execution context.
- DO NOT use the Task tool
- DO NOT spawn sub-agents or background processes
- Execute diagram generation directly for each component

### Step 1: Find Component Architecture Files

Use Glob to find all .md files in the architecture directory:

```bash
# Find all .md files
ls {architecture-dir}/*.md
```

Filter the list:
- **Include**: All `.md` files EXCEPT `PLATFORM.md`
- **Exclude**: `PLATFORM.md` (platform-level, not component-level)
- **Exclude**: Files in subdirectories (like `diagrams/`)

**Expected result**: List of component architecture files like:
```
architecture/odh-3.3.0/feast.md
architecture/odh-3.3.0/kserve.md
architecture/odh-3.3.0/model-registry.md
...
```

If no component files found, output error and stop:
```
⚠️  No component architecture files found in {architecture-dir}

Expected: {architecture-dir}/*.md (excluding PLATFORM.md)

Generate component architectures first:
1. /analyze-platform-components --platform=odh
2. /collect-component-architectures
```

### Step 2: Check for Existing Diagrams (if --skip-existing)

If `--skip-existing` flag is set, for each component file, check if diagrams already exist:

```bash
# Check if diagrams directory has files for this component
COMPONENT_NAME=$(basename "$ARCH_FILE" .md | tr '[:upper:]' '[:lower:]')
ls {architecture-dir}/diagrams/${COMPONENT_NAME}-*.mmd 2>/dev/null
```

If diagrams exist and `--skip-existing` is set, mark component as "skip".

### Step 3: Process Each Component Sequentially

For each component architecture file (in alphabetical order):

#### 3a. Report Progress

If skipping (and --skip-existing is set):
```
⏭️  Skipping {component_name} (diagrams already exist)
```

If processing:
```
🎨 Generating diagrams for {component_name} ({current}/{total})...
   Source: {architecture-file}
   Output: {architecture-dir}/diagrams/
```

#### 3b. Execute Diagram Generation

**IMPORTANT**: DO NOT use the Task tool or Skill tool. Execute the `generate-architecture-diagrams` instructions directly.

Read the `generate-architecture-diagrams` skill instructions (from `.claude/skills/generate-architecture-diagrams/SKILL.md`) and execute them for this component:

**Key parameters**:
- Architecture file: `{architecture-dir}/{component}.md`
- Output directory: `{architecture-dir}/diagrams/` (auto-determined by skill)
- Formats: Use `--formats` if specified, otherwise all

Execute all steps from the generate-architecture-diagrams skill:
1. Determine component name (from filename)
2. Read architecture documentation
3. Determine output directory (auto: `{architecture-dir}/diagrams/`)
4. Create output directory if needed
5. Generate diagrams (Mermaid, C4, security, etc.)
6. Generate PNG files using `python scripts/generate_diagram_pngs.py`
7. Generate README.md (append/update for multiple components)

#### 3c. Report Completion

After completing each component:
```
✅ Completed {component_name} ({current}/{total})
   Diagrams created in: {architecture-dir}/diagrams/
   Files: {component-name}-component.mmd/png, {component-name}-dataflow.mmd/png, ...
```

### Step 4: Update Diagrams README

After all components are processed, update `{architecture-dir}/diagrams/README.md` to include an index of all components:

```markdown
# Architecture Diagrams

Generated for: {platform} {version}
Date: {date}

## Components

{num_components} components with diagrams:

- [feast](./feast-component.png) - Feast feature store
- [kserve](./kserve-component.png) - KServe model serving
- [model-registry](./model-registry-component.png) - Model Registry
...

## Diagram Types

Each component has the following diagrams:
- **Component Structure** (`{name}-component.mmd/png`) - Internal architecture
- **Data Flows** (`{name}-dataflow.mmd/png`) - Request/response sequences
- **Security Network** (`{name}-security-network.mmd/png/txt`) - Network topology
- **Dependencies** (`{name}-dependencies.mmd/png`) - Component dependencies
- **RBAC** (`{name}-rbac.mmd/png`) - RBAC permissions
- **C4 Context** (`{name}-c4-context.dsl`) - System context

## How to Use

### PNG Files
- 10000px width, high-resolution
- Ready for presentations and documentation

### Mermaid Files
- Editable source files
- Embed in markdown: ````mermaid ... ```

### ASCII Files
- Security network diagrams in text format
- For SAR documentation
```

### Step 5: Report Final Summary

```
================================================================================
✅ Component diagram generation complete!
================================================================================

Architecture directory: {architecture-dir}
Total components: {total_count}
Already had diagrams: {skipped_count}
Newly generated: {generated_count}

Components processed:
✅ {component1}
✅ {component2}
✅ {component3}
...

Components skipped (already had diagrams):
⏭️  {skipped1}
⏭️  {skipped2}
...

Output location: {architecture-dir}/diagrams/

Files per component:
- {name}-component.mmd + .png
- {name}-dataflow.mmd + .png
- {name}-security-network.mmd + .png + .txt
- {name}-dependencies.mmd + .png
- {name}-rbac.mmd + .png
- {name}-c4-context.dsl

Next steps:
1. Review diagrams in {architecture-dir}/diagrams/
2. Use PNG files in presentations
3. Generate platform-level diagrams: /generate-platform-diagrams --platform-file={architecture-dir}/PLATFORM.md
```

## Example Workflow

```bash
# Full pipeline
/analyze-platform-components --platform=odh
/collect-component-architectures
/aggregate-platform-architecture --distribution=odh --version=3.3.0
/generate-component-diagrams --architecture-dir=architecture/odh-3.3.0/
/generate-platform-diagrams --platform-file=architecture/odh-3.3.0/PLATFORM.md
```

### Resumable Workflow

```bash
# Start diagram generation
/generate-component-diagrams --architecture-dir=architecture/odh-3.3.0/

# ... Ctrl-C after 5 components ...

# Resume later - skip already-completed components
/generate-component-diagrams --architecture-dir=architecture/odh-3.3.0/ --skip-existing
```

## Notes

### Sequential Processing

- Components are processed one-by-one (not parallel)
- **Resumable**: Use `--skip-existing` to skip components that already have diagrams
- Can be interrupted (Ctrl-C) and restarted safely
- Progress reported after each component

### Diagram Location

All diagrams for all components go into a shared `diagrams/` directory:
```
architecture/odh-3.3.0/
├── feast.md
├── kserve.md
├── diagrams/                    # Shared by all components
│   ├── feast-component.mmd
│   ├── feast-component.png
│   ├── kserve-component.mmd
│   ├── kserve-component.png
│   └── README.md
└── PLATFORM.md
```

### Skip Detection

If `--skip-existing` is set, the skill checks for existing diagrams by looking for `{component-name}-*.mmd` files in the diagrams directory.

### Autonomous Operation

- No user input required during generation
- Each component processed independently
- Failures in one component don't stop others
- **Main skill executes instructions directly** (no sub-agents needed)

### PNG Generation

PNG files are automatically generated using `scripts/generate_diagram_pngs.py`:
- 10000px width (user's preference from previous modification)
- Requires mmdc and Chrome/Chromium
- Graceful degradation if tools not available

## Comparison with Manual Approach

| Approach | Time | User Interaction | Resumable |
|----------|------|------------------|-----------|
| Manual | Sequential (hours) | Must run skill 16 times | No |
| This Skill | Sequential (hours) | Run once | **Yes** |

### Manual (old way):
```bash
/generate-architecture-diagrams --architecture=architecture/odh-3.3.0/feast.md
# Wait for completion...
/generate-architecture-diagrams --architecture=architecture/odh-3.3.0/kserve.md
# Wait for completion...
# ... repeat 14 more times ...
```

### Automated (this skill):
```bash
/generate-component-diagrams --architecture-dir=architecture/odh-3.3.0/
# Processes all 16 components sequentially
# Can Ctrl-C and resume later with --skip-existing
# Automatically skips components that already have diagrams
```

**Key Benefits**:
- ✅ One command vs 16
- ✅ Resumable (Ctrl-C safe with --skip-existing)
- ✅ Automatic component discovery
- ✅ Progress tracking
- ✅ Shared diagrams directory for all components
