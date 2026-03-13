# Library Modules

This directory contains modular components for repository processing and analysis.

## Modules

### `fetch.py`
Phase 1: Fetch and clone repositories from GitHub organizations using `gh-org-clone`. Supports filtering by branch.

### `manifest_parser.py`
Phase 2: Parse `get_all_manifests.sh` script to extract component repository information.

**Key Functions:**
- `process_manifest_script()` - Silent data processing, returns structured ComponentInfo dict
- `display_component_summary()` - Human-readable output for CLI
- `components_to_json()` - Convert to JSON for programmatic use
- `components_to_dict()` - Convert to Python dict

Parses bash associative arrays (ODH_COMPONENT_MANIFESTS or RHOAI_COMPONENT_MANIFESTS) containing component metadata including repo organization, name, git reference, and source folder. Automatically maps components to local checkouts and checks for GENERATED_ARCHITECTURE.md files.

**Design Philosophy:** Data processing is separate from display. The parser is silent and returns structured data that can be consumed by other tools.

## Usage

These modules are imported and orchestrated by the main CLI in `main.py`.

Example:
```python
from lib.fetch import fetch_repositories
from lib.manifest_parser import process_manifest_script

# Run individual phases
await fetch_repositories("opendatahub-io")
await fetch_repositories("red-hat-data-services", branch="rhoai-2.14")

# Parse manifests
components = await process_manifest_script(
    script_path="checkouts/opendatahub-io/opendatahub-operator/get_all_manifests.sh",
    platform="odh"
)

# Returns dict of ComponentInfo objects with checkout paths and architecture status
for key, component in components.items():
    print(f"{key}: {component.repo_org}/{component.repo_name} @ {component.ref}")
    print(f"  Checkout: {component.checkout_path}")
    print(f"  Has architecture: {component.has_architecture}")
```
