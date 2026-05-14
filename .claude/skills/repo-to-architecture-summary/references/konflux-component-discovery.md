# Konflux Component Discovery

Parse Konflux Dockerfiles to identify every shippable container image a repository produces. Each `Dockerfile*konflux*` maps to one deployable component — a repo with 9 Konflux Dockerfiles produces 9 container images.

This step runs **before** any language-specific analysis. Its output — a component inventory — drives which source directories need deeper analysis and which reference doc to use.

## When to use

Always. Run this as the first analysis step for every repository. Even single-component repos benefit from reading the Konflux Dockerfile to understand base images, build stages, and entry points.

## Step 1: Find all Konflux build files

```bash
find . -maxdepth 3 \( -name "*Dockerfile*konflux*" -o -name "*Containerfile*konflux*" \) -print | sort
```

If no Konflux files exist, fall back to regular `Dockerfile` / `Containerfile` files:
```bash
find . -maxdepth 3 \( -name "Dockerfile*" -o -name "Containerfile*" \) ! -name "*.md" -print | sort
```

## Step 2: Read every Dockerfile

Konflux Dockerfiles are small (typically 30-80 lines). Read ALL of them — no sub-agents needed for this step.

For each Dockerfile, extract:

| Field | What to look for | Example |
|-------|-----------------|---------|
| **Component name** | Filename suffix after `konflux` | `Dockerfile.konflux.genai` → `genai` |
| **Base image** | `FROM` lines (build + runtime stages) | `registry.access.redhat.com/ubi9/nodejs-22`, `ubi9-minimal` |
| **Build stages** | Named `AS` stages | `AS builder`, `AS ui-builder`, `AS bff-builder` |
| **Source paths** | `COPY` directives (what source dirs are included) | `COPY cmd/ cmd/`, `COPY pkg/ pkg/`, `COPY frontend/ frontend/` |
| **Entry command** | `CMD` or `ENTRYPOINT` | `CMD ["npm", "run", "start"]`, `ENTRYPOINT ["/bff"]` |
| **Exposed ports** | `EXPOSE` directives | `EXPOSE 8080` |
| **Build args** | `ARG` directives revealing config | `ARG MODULE_NAME=gen-ai`, `ARG GOTAGS="distro"` |
| **Language** | Base image + build commands | `go-toolset` → Go, `nodejs-22` → Node, `python-311` → Python |
| **FIPS compliance** | FIPS-related build flags — **carry forward to Security → FIPS Compliance** | `GOEXPERIMENT=strictfipsruntime`, `-tags strictfipsruntime`, `CGO_ENABLED=1` |
| **Hermeto prefetch** | Hermetic dependency injection (formerly cachi2) — **carry forward to Security → Build Hermeticity** | `if [ -f /cachi2/cachi2.env ]; then . /cachi2/cachi2.env`, `COPY $REMOTE_SOURCES`, `/cachi2/output/deps/` |
| **Dep install commands** | How deps are fetched — hermetic vs network | `go mod download`, `pip install --require-hashes --no-deps`, `npm ci`, `pip install -r requirements.txt` (non-hermetic) |
| **User** | Runtime user for security analysis | `USER 65532:65532`, `USER 1001` |

## Step 3: Build component inventory table

Produce a table mapping each Dockerfile to a component:

| Dockerfile | Component | Intent | Language | Source Dirs | Port | Entry | Base Image |
|-----------|-----------|--------|----------|-------------|------|-------|------------|
| `Dockerfile.konflux` | main | Primary service | Go | `cmd/`, `pkg/`, `internal/` | 8080 | `/manager` | ubi9/go-toolset → ubi9-minimal |
| `Dockerfile.konflux.genai` | genai | Sidecar module | Go+TS | `packages/gen-ai/bff/`, `packages/gen-ai/frontend/` | 8080 | `/bff` | go-toolset + nodejs-22 → ubi9-minimal |

**Intent values** — classify each component:
- **Primary service**: The main binary/server the repo exists to produce
- **Sidecar module**: Runs alongside primary in the same pod (BFF modules, kube-rbac-proxy)
- **Build variant**: Same component with instrumentation or different config (e.g., sealights)
- **Utility image**: CLI tool, migration runner, init container — note that for init containers, the Dockerfile `CMD` is a default often overridden by the consuming deployment's `command:` field; describe the actual deployed behavior, not just the image default
- **Optional module**: Only deployed when a feature is enabled in platform config

Intent drives the Sub-Component Details section. For multi-component repos, every component except build variants gets a dedicated subsection.

## Step 4: Identify multi-component patterns

Common multi-component patterns to recognize:

### Monorepo with separate cmd/ entries
```
Dockerfile.konflux.apiserver  → cmd/apiserver/main.go
Dockerfile.konflux.gc         → cmd/batch-gc/main.go
Dockerfile.konflux.processor  → cmd/batch-processor/main.go
```
All share `internal/` and `pkg/` — analyze shared code once, entry points separately.

### Frontend + BFF packages
```
Dockerfile.konflux            → frontend/ + backend/ (host app)
Dockerfile.konflux.genai      → packages/gen-ai/frontend/ + packages/gen-ai/bff/
Dockerfile.konflux.mlflow     → packages/mlflow/frontend/ + packages/mlflow/bff/
```
Each package is an independently deployable module federation remote.

### Multi-stage build producing one binary
```
FROM go-toolset AS builder     → builds Go binary
FROM ubi9-minimal              → copies binary + config only
```
Source analysis focuses on the builder stage's COPY paths.

### Dispatcher pattern
```
Dockerfile.konflux → builds multiple binaries, single entry point selects mode
```
Look for mode-switching in the entry point (e.g., kube-auth-proxy).

## Step 5: Map components to analysis strategies

Use the component inventory to select which reference doc(s) apply:

| Component language | Source pattern | Reference doc |
|-------------------|---------------|---------------|
| Go + `controllers/` or `internal/controller/` | Operator | `controller-analysis.md` |
| Go + `cmd/*/main.go` (no controllers) | Service | `go-service-analysis.md` |
| TypeScript + `frontend/` + Go `bff/` | Frontend+BFF | `frontend-bff-analysis.md` |
| Python + `pyproject.toml`/`setup.py` | ML service | `python-service-analysis.md` |
| Rust + `Cargo.toml` | Rust service | `rust-service-analysis.md` |
| Only Dockerfile (no significant source) | Container image | `container-image-analysis.md` |

Multi-language repos use multiple reference docs. For example, kserve has Go controllers AND a Python SDK — use both `controller-analysis.md` and `python-service-analysis.md`.

## Aggregation

The component inventory table feeds into the architecture template:
- **Architecture Components** section: one row per component
- **Sub-Component Details** section (multi-component repos): one `###` subsection per component with intent, API routes, upstream deps, and configuration — populated by deeper analysis in subsequent steps
- **Container Images** section: base images, build stages, FIPS compliance, intent column
- **Network Architecture → Services**: ports from EXPOSE directives (verified against source)
- **Security → FIPS Compliance**: FIPS build flags from Dockerfiles (`GOEXPERIMENT=strictfipsruntime`, `CGO_ENABLED=1`, `-tags strictfipsruntime`) MUST be written into the FIPS Compliance table. If NO FIPS flags were found in any Dockerfile, document that absence — it is architecturally significant (the component may rely on base image FIPS mode or may not be FIPS-compliant at all)
- **Security → Build Hermeticity**: Document lock files found at each layer (RPM: `rpms.lock.yaml`, language: `go.sum`/`uv.lock`/`poetry.lock`/`Pipfile.lock`/`package-lock.json`/`yarn.lock`/`Cargo.lock`/`pixi.lock`, artifacts: `artifacts.lock.yaml`) and Hermeto (formerly cachi2) prefetch usage from the Dockerfile. Note hermeticity gaps — a missing layer means that layer's deps are not reproducibly locked. Also note if the branch is upstream (lock files often absent) vs downstream release (lock files added during hardening)
- **Security**: runtime user, base image provenance
