# arch-query

A purpose-built CLI for querying RHOAI/ODH architecture-context documentation. Replaces filesystem exploration (`ls`, `grep`, `cat`) with structured subcommands that parse component markdown docs and return concise, structured results.

## Why

LLM agents consume architecture-context via filesystem tools — `ls` to discover versions, `cat` to read component docs, `grep` to search across files. Analysis of agent traces revealed this pattern is expensive and error-prone:

- **54% of tool calls** are spent on navigation (listing directories, reading files that turn out to be irrelevant, re-reading the same file for different sections)
- **20% of traces** read nothing useful — the agent navigates to a file, reads it, and extracts no actionable information
- **Agents hallucinate** when they don't find data — e.g., concluding a component uses only OpenShift Routes when the docs clearly show both Route and HTTPRoute (Gateway API), because the agent read the wrong section or stopped reading too early
- **Token cost scales linearly** with the number of components — reading 70 component docs at ~300 lines each consumes massive context windows

`arch-query` replaces the `ls | grep | cat` loop with structured queries that return exactly the data needed. A single `arch-query component kserve` replaces 3-5 tool calls and returns a parsed fact sheet. `arch-query grep httproute` searches all 70 components across all parsed fields in one call. `arch-query diff --all rhoai-3.3 rhoai-3.4` produces a platform-wide change summary that would take an agent dozens of file reads to assemble manually.

Expected impact: **85-90% reduction in tool calls and tokens** for architecture-context queries.

## Install

Pre-built binaries with embedded architecture data are available on the [releases page](https://github.com/opendatahub-io/architecture-context/releases). These are self-contained — no clone required.

```bash
# Download the latest release for your platform
curl -LO https://github.com/opendatahub-io/architecture-context/releases/latest/download/arch-query-linux-amd64
chmod +x arch-query-linux-amd64
./arch-query-linux-amd64 versions
```

Available binaries: `arch-query-linux-amd64`, `arch-query-linux-arm64`, `arch-query-darwin-amd64`, `arch-query-darwin-arm64`.

## Build from Source

```bash
# From project root
make build            # -> ./bin/arch-query (disk-only, reads ./architecture/)
make build-embedded   # -> ./bin/arch-query (bundled, architecture data compiled in)

# From src/arch-query/
make build            # -> ../../bin/arch-query
make test             # run tests
make smoke            # run smoke tests against real data
```

Requires Go 1.25+.

## Quick Start

```bash
# List all versions with component counts
arch-query versions

# List components in the default version (rhoai.next)
arch-query list

# Show a component fact sheet
arch-query component kserve

# Search across all parsed fields
arch-query grep httproute

# Compare two versions
arch-query diff --all rhoai-3.3 rhoai-3.4
```

## Global Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--base-dir` | `./architecture` | Path to the architecture directory |
| `--version` | `rhoai.next` | Version to query |
| `--output`, `-o` | `text` | Output format: `text`, `json`, `raw` |

## Subcommands

### versions

List available architecture-context versions with symlink aliases and component counts.

```
$ arch-query versions
25 versions available:

  rhoai-3.3         [current-ga]         (39 components)
  rhoai-3.4         [future-ga, newest]  (45 components)
  rhoai-3.4-ea.1    [latest-released]    (44 components)
  rhoai.next                             (70 components) (default)
```

### list

List all components in a version. Use `--names-only` for scripting.

```
$ arch-query list
$ arch-query list --names-only
$ arch-query list --version rhoai-3.3
```

### component

Show a full fact sheet for a component: metadata, CRDs, services, ingress, egress, HTTP endpoints, and dependencies. Use `--output json` for machine-readable output or `--output raw` for the unprocessed markdown source.

```text
$ arch-query component odh-dashboard
$ arch-query component odh-dashboard -o json
$ arch-query component odh-dashboard -o raw
# odh-dashboard
Purpose:         Web-based management console for RHOAI...
Type:            Frontend + BFF (Backend-for-Frontend)
Repository:      https://github.com/red-hat-data-services/odh-dashboard.git
Languages:       TypeScript, Go

## CRDs
  opendatahub.io/v1alpha       OdhDashboardConfig  Namespaced
  ...

## Services
  8443/TCP  HTTPS  odh-dashboard                Internal
  ...

## Ingress
  odh-dashboard  Route (OpenShift)        443/TCP   HTTPS  External
  odh-dashboard  HTTPRoute (Gateway API)  8443/TCP  HTTPS  External

## Egress
  Kubernetes API Server  6443/TCP  HTTPS  All K8s resource operations
  ...

## Dependencies
  External:
    Node.js - Runtime for backend BFF server
    ...
  Internal platform:
    Kubernetes API Server - All resource management
    ...
```

### search

Case-insensitive substring search on component names and purpose text.

```
$ arch-query search vllm
$ arch-query search "model serving"
```

### grep

Deep search across all parsed fields: CRDs, dependencies, services, endpoints, gRPC, RBAC, ingress, egress, architecture components, and raw section text. Shows every component that references the term and the context of each match.

```
$ arch-query grep httproute
kserve:
  [ext-dep]   Gateway API - HTTPRoute-based ingress for LLMInferenceService
  [ingress]   {isvc-name} HTTPRoute (Gateway API) 80/TCP or 443/TCP/HTTP/HTTPS External
  ...

odh-dashboard:
  [ingress]   odh-dashboard HTTPRoute (Gateway API) 8443/TCP/HTTPS External

$ arch-query grep envoy
$ arch-query grep gateway
```

### exists

Check if a component exists in the inventory. Exit code 0 if found, 1 if not. Shows closest matches on failure.

```
$ arch-query exists kserve
kserve exists in rhoai.next
  Type: Operator
  Doc:  ./architecture/rhoai.next/kserve.md

$ arch-query exists kserver
Component "kserver" not found in rhoai.next.
  Closest matches: kserve
```

### deps

Show forward and reverse dependencies for a component. Forward deps show what the component depends on; reverse deps scan all other components to find what depends on it.

```
$ arch-query deps kserve

kserve dependencies (rhoai.next):

  External:
    Knative Serving       Yes  Serverless model deployment
    Istio                 Yes  Service mesh for traffic routing
    Gateway API           Yes  HTTPRoute-based ingress
    ...

  Internal platform:
    Kubernetes API Server       API  Core resource management
    ...

  Reverse dependencies (components that depend on kserve):
    odh-dashboard         KServe (serving.kserve.io) - ServingRuntime management
    odh-model-controller  KServe - InferenceService monitoring
    ...
```

### crds

List CRDs across all components or for a specific component. Sorted by API group and kind.

```
$ arch-query crds              # all CRDs across all components
$ arch-query crds kserve       # CRDs for kserve only
```

### ports

List ports across all components or for a specific component. Aggregates from services, HTTP endpoints, and gRPC services. Deduplicates by port/protocol.

```
$ arch-query ports              # all ports
$ arch-query ports odh-dashboard
```

### platform

Show a condensed summary of the PLATFORM.md file: metadata, overview, and component inventory.

```
$ arch-query platform
$ arch-query platform --version rhoai-3.4
```

### overlays

List active overlays with their IDs, titles, affected components, and release scope.

```
$ arch-query overlays
4 active overlays:

  0001  KFP SDK 2.16 in RHOAI 3.4      releases: rhoai-3.4  affects: data-science-pipelines
  ...
```

### diff

Compare a single component or all components between two versions. Diffs CRDs, dependencies, services, HTTP endpoints, gRPC services, RBAC roles, ingress, and egress. Platform-wide diffs include cross-cutting aggregation of the most common changes.

```
# Single component
$ arch-query diff kserve rhoai-3.3 rhoai-3.4

# All components (also accepts "platform" as the component name)
$ arch-query diff --all rhoai-3.3 rhoai-3.4

rhoai-3.3 -> rhoai-3.4

  Added components (6):
    batch-gateway
    ...

  Changed (12 components):
    kserve: +3/-1 CRDs, +2 deps, +1 ingress
    ...

  Key changes across platform:
    Dependencies added:
      Gateway API (in 8 components)
      ...
    CRD API groups added:
      gateway.networking.k8s.io (12 CRDs)
      ...
```

## Data Model

`arch-query` parses the structured markdown format used by architecture-context component docs. Each `.md` file is split on `## ` headings and subsections are extracted by `### ` headings. Pipe-delimited markdown tables are parsed by column position.

### Parsed Sections

| Section | Subsection | Extracted Data |
|---------|------------|----------------|
| Metadata | - | Repository, version, languages, deployment type |
| Purpose | - | Short and detailed descriptions |
| Architecture Components | - | Name, type, purpose |
| APIs Exposed | Custom Resource Definitions | Group, version, kind, scope, purpose |
| APIs Exposed | HTTP Endpoints | Path, method, port, protocol, encryption, auth, purpose |
| APIs Exposed | gRPC Services | Service, port, protocol, encryption, auth, purpose |
| Dependencies | External Dependencies | Component, version, required, purpose |
| Dependencies | Internal Platform Dependencies | Component, interaction type, purpose |
| Network Architecture | Services | Name, type, port, target port, protocol, encryption, auth, exposure |
| Network Architecture | Ingress | Component, type (Route/HTTPRoute), hosts, port, protocol, encryption, TLS mode, exposure |
| Network Architecture | Egress | Destination, port, protocol, encryption, auth, purpose |
| Security | RBAC | Role name, API group, resources, verbs |

### Version Resolution

Versions are directories under `--base-dir` (default `./architecture/`). Symlinks are resolved to show aliases (e.g., `current-ga -> rhoai-3.3`). The default version is `rhoai.next`.

### Overlays

Overlay files in `architecture/overlays/` use YAML frontmatter (id, title, status, affects, release) with `## Fact`, `## Impact`, and `## Context` markdown body sections.

## Architecture

```
src/arch-query/
  main.go                          # entrypoint
  cmd/                             # cobra subcommands
    root.go                        # global flags (--base-dir, --version, --output)
    versions.go, list.go           # inventory queries
    component.go, search.go        # component lookup
    exists.go, deps.go             # dependency analysis
    crds.go, ports.go              # cross-component queries
    platform.go, overlays.go       # platform-level queries
    grep.go                        # deep search
    diff.go                        # version comparison
  internal/
    types/types.go                 # all shared structs
    markdown/
      parser.go                    # component doc parser (section splitting, delegation)
      table.go                     # pipe-delimited table parser
      metadata.go                  # "- **Key**: value" metadata parser
      platform.go                  # PLATFORM.md parser
    loader/
      loader.go                    # loads a version directory into VersionData
      versions.go                  # discovers versions, resolves symlinks
    overlay/
      overlay.go                   # YAML frontmatter + markdown body parser
    output/
      output.go                    # tabwriter wrappers, formatting helpers
```

## Dependencies

- [cobra](https://github.com/spf13/cobra) -- CLI framework
- [gopkg.in/yaml.v3](https://pkg.go.dev/gopkg.in/yaml.v3) -- YAML parsing for overlay frontmatter
- Everything else is Go stdlib
