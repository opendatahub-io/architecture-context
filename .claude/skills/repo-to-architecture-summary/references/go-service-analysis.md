# Go Service Analysis

Analyze non-operator Go services and multi-component Go repositories. These are HTTP/gRPC servers, proxies, gateways, and CLI tools — they have `go.mod` and `cmd/` entry points but do NOT have Kubernetes controllers or CRDs (use `controller-analysis.md` for operators).

## When to use

The repository has:
- `go.mod` at the root (or subdirectory)
- `cmd/*/main.go` or root `main.go` entry point(s)
- Does NOT have `controllers/`, `internal/controller/`, or `PROJECT` file (those indicate an operator)

Multi-component repos are common: each `Dockerfile*konflux*` builds a different binary from a different `cmd/` entry point, but all share `internal/` and `pkg/`.

## When to use sub-agents

```bash
GO_COUNT=$(find . -path ./vendor -prune -o -name "*.go" ! -name "*_test.go" -print | wc -l)
PROTO_COUNT=$(find . -name "*.proto" -print | wc -l)
echo "Go files: $GO_COUNT, Proto files: $PROTO_COUNT"
```

- **50 or fewer files**: Read them yourself. No sub-agents needed.
- **More than 50 files**: Use sub-agents as described below.

## Step 1: Enumerate source files

```bash
# All non-test Go files (exclude vendor)
find . -path ./vendor -prune -o -name "*.go" ! -name "*_test.go" -print | sort

# Proto files
find . -name "*.proto" -print | sort

# Config and template files
find . -maxdepth 3 \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
  ! -path "*/vendor/*" ! -path "*/testdata/*" -print | sort

# Identify entry points
find . -path ./vendor -prune -o -name "main.go" -print | sort
```

## Step 2: Identify components from entry points

Each `cmd/*/main.go` typically maps to one deployable component. Cross-reference with Konflux Dockerfiles to confirm:

```bash
# Entry points
find . -path ./vendor -prune -o -name "main.go" -print | sort

# Konflux Dockerfiles (each builds one component)
find . -maxdepth 3 -name "*Dockerfile*konflux*" | sort

# Read each Dockerfile to see which cmd/ it builds
```

### Common multi-component patterns

| Pattern | Example | How to identify |
|---------|---------|----------------|
| **Separate cmd/ dirs** | batch-gateway: `cmd/apiserver/`, `cmd/batch-gc/`, `cmd/batch-processor/` | Multiple `cmd/*/main.go` files |
| **Dispatcher binary** | kube-auth-proxy: one binary, mode flag selects behavior | Single entry point with mode/subcommand selection |
| **Protocol gateway** | rest-proxy: translates REST→gRPC | `grpc-gateway` dependency in go.mod |
| **Hub + satellites** | model-registry: proxy server + controller + CSI driver | Multiple go.mod files in subdirectories |

## Step 3: Group files into sub-agent batches

**Grouping heuristics**:

1. **Per-component groups** — For multi-component repos, create one group per component: its `cmd/<name>/` entry point plus any component-specific directories. Include `internal/<name>/` if the component has its own internal package.

2. **Shared infrastructure** — `internal/` and `pkg/` directories shared across components. Group together — this code defines the common patterns (database access, auth middleware, HTTP utilities).

3. **Proto/API definitions** — `.proto` files, OpenAPI specs, generated code. Usually small enough to include with another group.

**Target**: 2-4 groups for multi-component repos. Single-component services rarely need sub-agents.

### Example groupings

**batch-gateway** (3 components, ~100 Go files):
| Group | Directories | Purpose |
|-------|------------|---------|
| 1 | `cmd/apiserver/`, `cmd/batch-gc/`, `cmd/batch-processor/` | All entry points — flags, config, server setup |
| 2 | `internal/`, `pkg/` | Shared: database, Redis, S3, HTTP handlers, job processing |

**data-science-pipelines** (5 components, ~500+ Go files):
| Group | Directories | Purpose |
|-------|------------|---------|
| 1 | `backend/src/apiserver/` | API server — REST handlers, resource management |
| 2 | `backend/src/v2/cmd/driver/`, `backend/src/v2/cmd/launcher-v2/` | Pipeline execution engine |
| 3 | `backend/src/agent/persistence/` | Persistence agent — artifact management |
| 4 | `backend/src/crd/controller/scheduledworkflow/` | Scheduled workflow controller |
| 5 | `backend/src/common/`, `api/` | Shared libraries, API types |

## Step 4: Spawn sub-agents

For each group, spawn a sub-agent using the Task tool with `subagent_type=Explore`. Launch up to **3 sub-agents in parallel**.

### Sub-agent prompt template

```
Analyze the following Go source files from {repo_path}.
This group covers: {group_description}.

Read EVERY file listed below. Do not skip any. Do not read *_test.go files.

Files to read:
{file_list}

For EACH file you read, extract and report ALL of the following that apply:

## Entry Points
Every main() function, flag/arg parsing, and server startup.
Report as a table:

| File | Line(s) | Binary Name | Flags/Args | Server Type | Port | Purpose |
|------|---------|-------------|------------|-------------|------|---------|

## HTTP Handlers
Every HTTP route registration, handler function, and middleware.
Report as a table:

| File | Line(s) | Method | Path | Middleware | Auth | Purpose |
|------|---------|--------|------|------------|------|---------|

Include: gorilla/mux routes, httprouter handlers, net/http HandleFunc,
gin routes, echo routes, chi routes, grpc-gateway mappings.

## gRPC Services
Every gRPC server or client implementation.
Report as a table:

| File | Line(s) | Service | Method | Direction | Streaming | Purpose |
|------|---------|---------|--------|-----------|-----------|---------|

Direction = server (implements servicer) or client (dials remote).

## Upstream/Downstream Calls
Every outbound HTTP, gRPC, database, cache, or queue call.
Report as a table:

| File | Line(s) | Target | Protocol | Client Library | Purpose |
|------|---------|--------|----------|----------------|---------|

Include: http.Client calls, grpc.Dial, sql.Open, redis.NewClient,
S3 client init, K8s client-go calls.

## Configuration
Every flag, env var, or config struct field.
Report as a table:

| File | Line(s) | Name | Source | Type | Default | Purpose |
|------|---------|------|--------|------|---------|---------|

Source = flag, env, config file, etc.

## Authentication & Authorization
Every auth-related code: token validation, OIDC, JWT, RBAC checks.
Report as a table:

| File | Line(s) | Mechanism | Details | Purpose |
|------|---------|-----------|---------|---------|

## Health & Metrics
Every health endpoint, readiness check, and metrics registration.
Report as a table:

| File | Line(s) | Endpoint | Protocol | What It Checks | Purpose |
|------|---------|----------|----------|----------------|---------|

CRITICAL: Read EVERY file. Report EVERY finding. Include file paths and
line numbers for all entries.
```

## Step 5: Aggregate sub-agent findings

After all sub-agents return, merge their findings:

1. **Entry Points tables** → Architecture Components. One component per binary/entry point. Include the command-line interface.

2. **HTTP Handlers + gRPC Services** → Network Architecture (Services, Ingress). Document every exposed endpoint with port, protocol, and auth requirements.

3. **Upstream/Downstream Calls** → Integration Points. Every outbound call is an integration point. For multi-component repos, identify inter-component communication (shared database, message queue, direct API calls).

4. **Configuration tables** → Deployment Configuration. Group by component, noting shared vs. component-specific config.

5. **Auth tables** → Security (Authentication & Authorization). Document the auth chain — how tokens flow from client through proxy to upstream.

6. **Health & Metrics tables** → Network Architecture + Deployment.

### Key patterns to synthesize for multi-component repos

- **Shared state**: Do components share a database (PostgreSQL, MySQL)? A cache (Redis)? A message queue? Document the shared infrastructure.
- **Inter-component calls**: Does component A call component B's API? Document the dependency graph.
- **Protocol boundaries**: Does a gateway translate protocols (REST→gRPC)? Document the translation layer.
- **Deployment topology**: Which components must run together vs. can be independently scaled?
