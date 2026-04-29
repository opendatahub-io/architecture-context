# Rust Service Analysis

Analyze Rust HTTP/gRPC services. These are typically high-performance orchestration or serving layers built with tokio + axum (HTTP) and tonic (gRPC).

## When to use

The repository has:
- `Cargo.toml` at the root
- `src/main.rs` entry point
- Typically small enough to read without sub-agents (under 100 `.rs` files)

## When to use sub-agents

```bash
RS_COUNT=$(find . -name "*.rs" ! -path "*/target/*" ! -name "*test*" | wc -l)
PROTO_COUNT=$(find . -name "*.proto" | wc -l)
echo "Rust files: $RS_COUNT, Proto files: $PROTO_COUNT"
```

- **80 or fewer files**: Read them yourself. No sub-agents needed. Most Rust services in this ecosystem are under this threshold.
- **More than 80 files**: Use sub-agents as described below.

## Step 1: Enumerate source files

```bash
# All non-test Rust files (exclude target/)
find . -path ./target -prune -o -name "*.rs" ! -name "*test*" -print | sort

# Proto files (gRPC definitions)
find . -name "*.proto" -print | sort

# Build script (often compiles protos)
ls build.rs 2>/dev/null

# Config files
find . -maxdepth 2 \( -name "*.yaml" -o -name "*.yml" -o -name "*.toml" \) \
  ! -name "Cargo.toml" ! -name "rustfmt.toml" ! -path "*/target/*" -print | sort
```

## Step 2: Key files to read first

Rust services have a predictable structure. Read these in order:

1. **`Cargo.toml`** — Dependencies reveal the architecture (axum = HTTP, tonic = gRPC, tokio = async, rustls = TLS, serde = config)
2. **`build.rs`** — Proto compilation setup (which .proto files, which services)
3. **`src/main.rs`** — Entry point, server startup, config loading
4. **`src/server.rs`** or `src/server/mod.rs` — Route definitions, middleware
5. **`protos/*.proto`** — gRPC service definitions and message types
6. **`config/`** — Default configuration files

## Step 3: Group files (if sub-agents needed)

**Grouping heuristics** for large Rust services:

1. **Server and routes** — `src/main.rs`, `src/server/`, `src/routes/`. Entry point, HTTP/gRPC route registration, middleware.
2. **Business logic** — `src/orchestrator/`, `src/handlers/`, `src/services/`. Core processing logic.
3. **Clients and integrations** — `src/clients/`, `src/health/`. Outbound calls to downstream services.
4. **Proto and config** — `protos/`, `config/`, `build.rs`, `src/config/`. API definitions and configuration.

**Target**: 2-4 groups. Most Rust services don't need sub-agents.

## Step 4: Spawn sub-agents (if needed)

For each group, spawn a sub-agent using the Task tool with `subagent_type=Explore`. Launch up to **3 sub-agents in parallel**.

**Output via files**: Each sub-agent writes its findings to a temporary file using the Write tool. Before spawning, generate a unique output path per group:
```
/tmp/arch-analysis-{component}-group-{N}.md
```

### Sub-agent prompt template

```
Analyze the following Rust source files from {repo_path}.
This group covers: {group_description}.

Read EVERY file listed below. Do not skip any. Do not read test files.

Files to read:
{file_list}

For EACH file you read, extract and report ALL of the following that apply:

## HTTP Routes
Every Axum/Actix/Hyper route definition.
Report as a table:

| File | Line(s) | Method | Path | Middleware/Layers | Auth | Purpose |
|------|---------|--------|------|-------------------|------|---------|

Include: Router::new().route(), .layer(), middleware::from_fn.

## gRPC Services
Every tonic service definition (server or client).
Report as a table:

| File | Line(s) | Service | Method | Direction | Streaming | Purpose |
|------|---------|---------|--------|-----------|-----------|---------|

Direction = server (implements trait) or client (connects to remote).

## Proto Definitions
Every service and message in .proto files.
Report as a table:

| File | Line(s) | Service | RPC Method | Request | Response | Streaming |
|------|---------|---------|------------|---------|----------|-----------|

## Downstream Service Calls
Every outbound HTTP, gRPC, or other network call.
Report as a table:

| File | Line(s) | Target | Protocol | Client Type | Purpose |
|------|---------|--------|----------|-------------|---------|

Include: tonic client calls, reqwest/hyper HTTP clients, database connections.

## Configuration
Every config struct field, env var, or CLI argument.
Report as a table:

| File | Line(s) | Name | Source | Type | Default | Purpose |
|------|---------|------|--------|------|---------|---------|

Include: serde-derived config structs, clap/structopt args, std::env reads.

## TLS/mTLS
Every TLS configuration: server-side TLS, client mTLS, certificate handling.
Report as a table:

| File | Line(s) | Role | Library | Cert Source | Purpose |
|------|---------|------|---------|-------------|---------|

Role = server TLS, client mTLS, CA verification.

## Health & Observability
Every health endpoint, metrics registration, tracing setup.
Report as a table:

| File | Line(s) | Type | Endpoint/Setup | Details | Purpose |
|------|---------|------|----------------|---------|---------|

Include: health HTTP endpoints, OpenTelemetry setup, tracing subscriber,
Prometheus metrics, separate health server pattern.

CRITICAL: Read EVERY file. Report EVERY finding. Include file paths and
line numbers for all entries.

IMPORTANT: Write ALL of your findings to {output_file} using the Write tool.
Do NOT return findings as your response — the message parser cannot handle
certain patterns in large outputs. Write the file, then respond with only:
"Done. Findings written to {output_file}"
```

## Step 5: Aggregate findings

After all sub-agents complete, **read each output file** using the Read tool, then map findings to template sections:

1. **HTTP Routes + gRPC Services + Proto Definitions** → Network Architecture (Services, Ingress). Document every exposed endpoint.

2. **Downstream Service Calls** → Integration Points. Every outbound call is a dependency. For orchestration services, the downstream services ARE the architecture.

3. **Configuration** → Deployment Configuration. Rust services often have hierarchical YAML config with per-service sections.

4. **TLS/mTLS** → Security. Document which connections use TLS, which use mTLS, where certificates come from.

5. **Health & Observability** → Network Architecture + Deployment. Note the dual-server pattern (separate health port) if present.

### Rust service patterns to recognize

| Pattern | Example | What to document |
|---------|---------|-----------------|
| **Dual-server** | fms-guardrails-orchestrator | Separate health server on different port from main API |
| **Orchestration** | fms-guardrails-orchestrator | Routes requests to multiple downstream gRPC services (generation, detection, chunking) |
| **SSE streaming** | fms-guardrails-orchestrator | Server-Sent Events for long-running inference requests |
| **Proto compilation** | build.rs + tonic-build | gRPC client stubs generated at build time from .proto files |
| **Downstream health tracking** | Health checks of gRPC services | Monitors readiness of services it depends on |
