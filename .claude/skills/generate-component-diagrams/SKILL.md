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

**IMPORTANT**: DO NOT use the Task tool or Skill tool. Execute diagram generation directly by following these steps.

**CRITICAL**: Diagrams MUST be generated from the ACTUAL content in the component's .md file, NOT from templates or hardcoded metadata.

**PROHIBITED**:
- ❌ DO NOT create Python scripts with hardcoded component metadata
- ❌ DO NOT generate template/placeholder diagrams
- ❌ DO NOT skip reading the architecture .md files
- ✅ MUST read each component's .md file and extract actual data from markdown tables

For this component's architecture file (`{architecture-dir}/{component}.md`):

**Step 1: Read the component architecture file**

Use the Read tool to read `{architecture-dir}/{component}.md`:
```
Read: {architecture-dir}/{component}.md
```

**Step 2: Extract structured data from markdown tables**

Parse the architecture markdown to extract (following generate-architecture-diagrams skill):
- **Component metadata**: From "## Metadata" section
- **Architecture components**: From "## Architecture Components" table
- **CRDs**: From "### Custom Resource Definitions" table
- **HTTP/gRPC endpoints**: From "## APIs Exposed" tables
- **Dependencies**: From "## Dependencies" tables (external and internal)
- **Network services**: From "### Services" table in "## Network Architecture"
- **Ingress/Egress**: From network tables
- **RBAC**: From "## Security" → "### RBAC" tables
- **Data flows**: From "## Data Flows" section
- **Integration points**: From "## Integration Points" table

**Step 3: Generate diagram files based on extracted data**

Create diagram files in `{architecture-dir}/diagrams/` using the component name from the filename:

1. **`{component-name}-component.mmd`** - Mermaid component diagram showing:
   - Internal architecture components
   - CRDs and their relationships
   - External dependencies
   - Internal integrations

2. **`{component-name}-dataflow.mmd`** - Mermaid sequence diagram from "## Data Flows" section

3. **`{component-name}-security-network.txt`** - ASCII security network diagram with:
   - Exact ports, protocols, encryption from network tables
   - Trust boundaries (external, ingress, service mesh, egress)
   - RBAC summary from security tables
   - Service mesh configuration
   - Secrets from security tables

4. **`{component-name}-security-network.mmd`** - Mermaid version of security network

5. **`{component-name}-c4-context.dsl`** - C4 context from dependencies and integration points

6. **`{component-name}-dependencies.mmd`** - Mermaid dependency graph from "## Dependencies" tables

7. **`{component-name}-rbac.mmd`** - Mermaid RBAC visualization from security tables

**Step 4: Generate PNG files for this component**

After creating all .mmd files for this component, run the PNG generation script once for the entire diagrams directory:
```bash
python scripts/generate_diagram_pngs.py {architecture-dir}/diagrams/ --width=10000
```

**Note**: The script processes ALL .mmd files in the directory, which is fine - it will regenerate PNGs for previously completed components (they'll be identical) and create new PNGs for this component's diagrams. This is simpler than trying to filter for specific files.

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
