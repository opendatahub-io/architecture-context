# RHOAI Architecture Diagrams

Repository processing and analysis tool for Red Hat OpenShift AI (RHOAI) components.

## Overview

This tool helps automate the process of:
1. Cloning repositories from GitHub organizations (with optional branch filtering)
2. Parsing component manifests to understand dependencies

## Project Structure

```
.
├── main.py                 # Main CLI entry point
├── lib/                    # Modular library components
│   ├── fetch.py           # Phase 1: Repository fetching
│   └── manifest_parser.py # Phase 2: Manifest parsing
└── checkouts/             # Cloned repositories (gitignored)
```

## Installation

1. Install dependencies:
```bash
uv sync
```

2. Set up environment variables (copy `.env.example` to `.env`):
```bash
cp .env.example .env
# Edit .env with your configuration
```

## Usage

The tool provides subcommands for each processing phase.

### Quick Start Examples

For OpenDataHub (ODH):
```bash
# Fetch all ODH repos
python main.py fetch opendatahub-io

# Parse manifests
python main.py parse-manifests --platform odh

# Or run all phases
python main.py all --platform odh
```

For Red Hat OpenShift AI (RHOAI) with versioning:
```bash
# Fetch RHOAI 2.14 repos
python main.py fetch red-hat-data-services --branch rhoai-2.14

# Parse manifests for RHOAI 2.14
python main.py parse-manifests --platform rhoai --branch rhoai-2.14

# Or run all phases
python main.py all --platform rhoai --branch rhoai-2.14
```

### Detailed Command Reference

### Phase 1: Fetch Repositories

Clone all repositories from a GitHub organization:

```bash
python main.py fetch <org-name>

# Example:
python main.py fetch red-hat-data-services

# With custom checkout directory:
python main.py fetch red-hat-data-services --checkouts-dir my-checkouts

# Clone only repos with a specific branch:
python main.py fetch red-hat-data-services --branch main

# Clone versioned checkouts for different releases:
# Note: --branch automatically creates <org>.<branch>/ directories
python main.py fetch red-hat-data-services --branch rhoai-2.13
python main.py fetch red-hat-data-services --branch rhoai-2.14
python main.py fetch red-hat-data-services --branch rhoai-2.15

# This creates:
#   checkouts/red-hat-data-services.rhoai-2.13/
#   checkouts/red-hat-data-services.rhoai-2.14/
#   checkouts/red-hat-data-services.rhoai-2.15/
```

### Phase 2: Parse Component Manifests

Extract component information from `get_all_manifests.sh`:

```bash
# For ODH (human-readable summary):
python main.py parse-manifests --platform odh

# For RHOAI with specific version:
python main.py parse-manifests --platform rhoai --branch rhoai-2.14

# Get structured JSON output for programmatic use:
python main.py parse-manifests --platform odh --format json

# With custom organization override:
python main.py parse-manifests --platform odh --org my-custom-org

# With custom script path override:
python main.py parse-manifests --platform odh --script-path path/to/get_all_manifests.sh
```

The parser extracts component information from bash associative arrays in the script:
- `ODH_COMPONENT_MANIFESTS` for ODH platform
- `RHOAI_COMPONENT_MANIFESTS` for RHOAI platform

Each component includes:
- Repository organization and name
- Git reference (branch/tag/commit)
- Source folder within the repo
- Checkout path (if repo is cloned)
- Whether GENERATED_ARCHITECTURE.md exists

#### Output Formats

**Summary format** (default, `--format summary`):
- Human-readable output with status indicators
- Shows analyzed vs. missing components
- Displays full component details

**JSON format** (`--format json`):
- Structured data suitable for piping to other tools
- Can be used programmatically in scripts
- See `examples/use_manifest_data.py` for usage examples

### Run All Phases

Execute all phases in sequence:

```bash
# For ODH (default):
python main.py all --platform odh

# For RHOAI with specific version:
python main.py all --platform rhoai --branch rhoai-2.14
```

## Programmatic Usage

The manifest parser can be used programmatically in your own Python scripts:

```python
from lib.manifest_parser import process_manifest_script, components_to_json

# Get structured component data (silent - no output)
components = await process_manifest_script(
    script_path="checkouts/opendatahub-io/opendatahub-operator/get_all_manifests.sh",
    platform="odh"
)

# Filter components needing analysis
needs_analysis = {
    key: comp
    for key, comp in components.items()
    if not comp.has_architecture
}

# Export to JSON
json_output = components_to_json(components, indent=2)

# Access component data
for key, component in components.items():
    print(f"{key}: {component.repo_org}/{component.repo_name}")
    print(f"  Checkout: {component.checkout_path}")
    print(f"  Ref: {component.ref}")
```

See `examples/use_manifest_data.py` for complete examples.

## Development

### Adding New Phases

1. Create a new module in `lib/`
2. Add the phase logic as async functions
3. Update `main.py` to add a new subcommand
4. Import and call the phase function

### Code Structure

All phase modules follow this pattern:
- Async functions for main operations
- Clear function signatures with type hints
- Dataclasses for structured data
- Proper error handling
- **Separation of concerns**: Data processing functions are silent and return structured data, display functions handle output

## Requirements

- Python 3.11+
- `gh-org-clone` CLI tool (for Phase 1)
- Git

## Environment Variables

See `.env.example` for required environment variables, particularly for Vertex AI integration.
