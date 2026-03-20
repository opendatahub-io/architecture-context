> **Agents**: If you are an AI agent using the data in this repo (rather than running the pipeline), read [AGENT_USAGE.md](AGENT_USAGE.md) for how to navigate the `architecture/` directory.

# RHOAI Architecture Diagrams

Automated pipeline that clones ODH/RHOAI component repositories, generates per-component architecture summaries using Claude agents, aggregates them into platform-level documents, and produces Mermaid/C4 diagrams. All driven by `main.py`.

## How it works

The pipeline has 6 phases, each runnable independently or together via `main.py all`.

### Phase 1: Fetch (`fetch`)

Uses `gh-org-clone` to clone all repositories from a GitHub org. For RHOAI, the `--branch` flag filters to repos that have that branch and creates a versioned checkout directory:

```
checkouts/red-hat-data-services.rhoai-3.4-ea.1/
  rhods-operator/
  kserve/
  odh-dashboard/
  notebooks/
  ...  (~49 repos)
```

### Phase 2: Parse manifests (`parse-manifests`)

Parses the operator's `get_all_manifests.sh` script to extract the `COMPONENT_MANIFESTS` bash associative arrays. This identifies ~17 components that the operator directly manages via kustomize manifests.

### Phase 3: Generate component architecture (`generate-architecture`)

For each component repo that lacks a `GENERATED_ARCHITECTURE.md`, spawns a Claude agent (via `claude-agent-sdk`) that reads the repo's source code and writes a structured architecture summary. Agents run concurrently (default 5 at a time).

**Component discovery** works in three layers:
1. **Manifest components** (~17) — parsed from `get_all_manifests.sh`
2. **Operator** (+1) — the operator itself, added explicitly
3. **Adjacent components** (+~31, RHOAI only) — all other repos in the checkout directory that aren't already covered by manifests, minus an exclusion list of utility repos

**Build metadata** from `RHOAI-Build-Config` is injected into each agent's prompt:
- Product version, supported OCP versions, CPU architectures (amd64, arm64, ppc64le, s390x)
- Operator feature flags (FIPS compliance, disconnected support, etc.)
- Container image count and the image-to-source-repo mapping from Konflux snapshot files

**Kustomize overlay context** is extracted from the operator's Go source and injected into each component agent's prompt so it knows exactly which kustomize overlay the rhods-operator applies for RHOAI:
- The `*_support.go` files in `internal/controller/components/{component}/` define per-platform overlay paths (e.g., `rhoai/onprem` for dashboard, `overlays/rhoai` for datasciencepipelines, `overlays/odh` for kserve)
- Image parameter mappings (`imageParamMap` / `imagesMap`) showing which `RELATED_IMAGE_*` env vars override params.env placeholders at deploy time
- The actual `params.env` values from `prefetched-manifests/{component}/{overlay}/params.env`, giving the agent concrete image references and configuration defaults
- This ensures agents analyze the correct overlay kustomization.yaml rather than the base, and understand what parameters the operator injects

### Phase 4: Collect architectures (`collect-architectures`)

Copies `GENERATED_ARCHITECTURE.md` files from checkouts into an organized `architecture/` directory:

```
architecture/
  rhoai-3.4-ea.1/
    kserve.md
    odh-dashboard.md
    notebooks.md
    PLATFORM.md
    diagrams/
      kserve-component.mmd
      kserve-component.png
      ...
  rhoai-3.4-ea.2/
    ...
```

### Phase 5: Generate platform architecture (`generate-platform-architecture`)

Spawns a Claude agent that reads all component `.md` files in an architecture version directory and produces a `PLATFORM.md` — an aggregated platform-level architecture document. Build metadata (OCP versions, shipped image topology) is included in the prompt.

### Phase 6: Generate diagrams (`generate-diagrams`)

Spawns Claude agents that read each component and platform `.md` file and produce:
- Mermaid diagrams (`.mmd`): component, dataflow, dependencies, RBAC, security/network
- C4 context diagrams (`.dsl`)
- PNG renders via `scripts/generate_diagram_pngs.py`

## Project structure

```
main.py                          # CLI entry point, all 6 phases
lib/
  fetch.py                       # Phase 1: gh-org-clone wrapper
  manifest_parser.py             # Phase 2: manifest parsing, adjacent discovery,
                                 #          build-config/bundle metadata extraction,
                                 #          kustomize overlay context extraction
scripts/
  collect_architectures.py       # Phase 4: file collection logic
  generate_diagram_pngs.py       # Mermaid→PNG rendering
.claude/skills/                  # Claude agent prompt templates
  repo-to-architecture-summary/  # Phase 3 skill
  aggregate-platform-architecture/# Phase 5 skill
  generate-component-diagrams/   # Phase 6 skill
architecture/                    # Output: organized architecture docs + diagrams
checkouts/                       # Cloned repositories (gitignored)
logs/                            # Agent execution logs per phase
```

## Usage

### Full pipeline

```bash
# RHOAI (specific version)
python main.py all --platform=rhoai --branch=rhoai-3.4-ea.1 --model=opus

# ODH
python main.py all --platform=odh --model=sonnet
```

### Individual phases

```bash
# Fetch repos
python main.py fetch red-hat-data-services --branch rhoai-3.4-ea.1

# Parse manifests (see what components are discovered)
python main.py parse-manifests --platform=rhoai --branch=rhoai-3.4-ea.1

# Generate architecture for a single component
python main.py generate-architecture --platform=rhoai --branch=rhoai-3.4-ea.1 \
  --component=kube-auth-proxy --model=sonnet

# Regenerate a specific component
python main.py generate-architecture --platform=rhoai --branch=rhoai-3.4-ea.1 \
  --component=kserve --force --model=opus

# Collect into architecture/ directory
python main.py collect-architectures --platform=rhoai

# Generate platform-level doc
python main.py generate-platform-architecture --platform=rhoai --version=3.4-ea.1

# Generate diagrams
python main.py generate-diagrams --platform=rhoai --version=3.4-ea.1
```

### Useful flags

| Flag | Phase | Description |
|------|-------|-------------|
| `--model` | 3, 5, 6 | Claude model: `sonnet` (default), `opus`, `haiku` |
| `--max-concurrent` | 3, 5, 6 | Parallel agent count (default: 5) |
| `--component` | 3 | Process a single component by key name |
| `--force` | 3 | Delete existing architecture and regenerate |
| `--force-regenerate` | 6 | Regenerate diagrams even if they exist |
| `--limit` | 3, 5, 6 | Cap number of items to process |

## Build metadata extraction

For RHOAI, the pipeline reads three files from `RHOAI-Build-Config/`:

| File | What it provides |
|------|------------------|
| `config/build-config.yaml` | Supported OCP versions (e.g. v4.19, v4.20, v4.21) |
| `bundle/csv-patch.yaml` | CPU architectures, min kube version, OLM feature flags |
| `bundle/bundle-patch.yaml` | Product version, all RELATED_IMAGE entries (84 images for 3.4-ea.1) |
| `release/*/stage/*/snapshot-components/*.yaml` | Konflux snapshot: container image → source repo + commit mapping |

This metadata is injected into agent prompts so they can factor in platform constraints (e.g., which k8s APIs are available given the OCP version range, multi-arch requirements, FIPS compliance).

## Kustomize overlay context

For each RHOAI component, the pipeline parses the operator's Go source to extract deployment context:

| Source | What it provides |
|--------|------------------|
| `internal/controller/components/{dir}/*_support.go` | Per-platform overlay paths (e.g., `rhoai/onprem`, `overlays/rhoai`) and image parameter mappings (`imageParamMap` / `imagesMap`) |
| `internal/controller/components/{dir}/*.go` | Named const source paths (e.g., `kserveManifestSourcePath = "overlays/odh"`) and computed kustomize variables (e.g., `sectionTitle`) |
| `prefetched-manifests/{key}/{overlay}/params.env` | Default image references and configuration values injected by the operator at deploy time |

The manifest key maps 1:1 to the operator component directory for most components. Special cases:
- `maas` → `modelsasservice/` directory
- `workbenches/*` (sub-keys like `workbenches/kf-notebook-controller`) → `workbenches/` directory
- `operator` → skipped (no kustomize overlay context for the operator itself)

This context is injected into Phase 3 agent prompts so they start analysis from the correct overlay `kustomization.yaml` rather than the base, and understand which image parameters and config values the operator substitutes.

## Requirements

- Python 3.13+
- `gh-org-clone` CLI tool
- `claude-agent-sdk` (installed via `uv sync`)
- `pyyaml`
- `ANTHROPIC_API_KEY` or Vertex AI credentials (see `.env.example`)

## Setup

```bash
uv sync
cp .env.example .env
# Edit .env with API credentials
```
