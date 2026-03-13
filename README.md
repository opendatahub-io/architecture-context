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

The tool provides subcommands for each processing phase:

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
python main.py fetch red-hat-data-services --branch rhoai-2.13 --checkouts-dir checkouts/rhoai-2.13
python main.py fetch red-hat-data-services --branch rhoai-2.14 --checkouts-dir checkouts/rhoai-2.14
python main.py fetch red-hat-data-services --branch rhoai-2.15 --checkouts-dir checkouts/rhoai-2.15
```

### Phase 2: Parse Component Manifests

Extract component information from `get_all_manifests.sh`:

```bash
python main.py parse-manifests

# With custom script path:
python main.py parse-manifests --script-path path/to/get_all_manifests.sh
```

### Run All Phases

Execute all phases in sequence:

```bash
python main.py all

# With custom organization:
python main.py all --org my-github-org
```

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

## Requirements

- Python 3.11+
- `gh-org-clone` CLI tool (for Phase 1)
- Git

## Environment Variables

See `.env.example` for required environment variables, particularly for Vertex AI integration.
