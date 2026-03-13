# Library Modules

This directory contains modular components for repository processing and analysis.

## Modules

### `fetch.py`
Phase 1: Fetch and clone repositories from GitHub organizations using `gh-org-clone`. Supports filtering by branch.

### `manifest_parser.py`
Phase 2: Parse `get_all_manifests.sh` script to extract component repository information including repos, branches, and commits.

## Usage

These modules are imported and orchestrated by the main CLI in `main.py`.

Example:
```python
from lib.fetch import fetch_repositories
from lib.manifest_parser import process_manifest_script

# Run individual phases
await fetch_repositories("red-hat-data-services")
await fetch_repositories("red-hat-data-services", branch="rhoai-2.14")
components = await process_manifest_script()
```
