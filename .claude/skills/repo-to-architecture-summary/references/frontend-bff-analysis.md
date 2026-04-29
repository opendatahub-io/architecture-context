# Frontend + BFF Monorepo Analysis

Analyze TypeScript/React frontend monorepos with Go Backend-for-Frontend (BFF) services and module federation. The primary example is odh-dashboard: a host app (frontend + Node.js backend) plus 6+ federated plugin packages, each with its own React frontend and Go BFF producing an independent container image.

## When to use

The repository has ALL of:
- `package.json` at the root (npm workspaces or monorepo tool)
- `frontend/` directory with React/TypeScript source
- `packages/*/` directories (or similar plugin structure)
- One or more packages containing `bff/` subdirectories with `go.mod`

## When to use sub-agents

Count source files across all languages:

```bash
TS_COUNT=$(find . -path ./node_modules -prune -o \( -name "*.ts" -o -name "*.tsx" \) ! -name "*.test.*" ! -name "*.spec.*" -print | wc -l)
GO_COUNT=$(find . -path ./vendor -prune -o -name "*.go" ! -name "*_test.go" -print | wc -l)
echo "TypeScript/TSX: $TS_COUNT, Go: $GO_COUNT"
```

- **Under 200 total files**: Read them yourself. No sub-agents needed.
- **200+ files**: Use sub-agents as described below.

## Step 1: Understand the monorepo structure

```bash
# Root workspace configuration
cat package.json | grep -A 20 '"workspaces"'

# Find all packages with their own package.json
find . -maxdepth 3 -name "package.json" ! -path "*/node_modules/*" | sort

# Find all BFF services
find . -maxdepth 3 -type d -name "bff" | sort

# Find module federation configs
find . -path ./node_modules -prune -o -name "moduleFederation*" -print | sort

# Find all Konflux Dockerfiles (one per deployable component)
find . -maxdepth 2 -name "*Dockerfile*konflux*" | sort
```

## Step 2: Group files into sub-agent batches

**Grouping heuristics** (adapt based on what you find):

1. **Frontend core** — `frontend/src/` directory. This is the host application: routes, Redux store, API clients, plugin system, shared components. Often the largest group (2000+ files).
   - If very large, split into: `frontend/src/api/` + `frontend/src/services/` (API layer), `frontend/src/pages/` + `frontend/src/routes/` (routing), `frontend/src/components/` (shared UI).

2. **Backend (Node.js)** — `backend/src/` directory. The Node.js server (typically Fastify) that serves the frontend, proxies APIs, and manages WebSocket connections. Usually small (50-150 files).

3. **BFF packages** — one group per package that has both `frontend/` and `bff/` subdirectories. Each package is a self-contained plugin:
   - `packages/<name>/frontend/` — React components, module federation config
   - `packages/<name>/bff/` — Go HTTP server, handlers, OpenAPI specs
   - Group the frontend + BFF together since they form a single functional unit.
   - If there are many packages (6+), batch 2-3 packages per sub-agent.

4. **Shared packages** — packages without BFFs (e.g., `plugin-core`, `app-config`, `tsconfig`, `eslint-config`). Group together — they define shared types, plugin APIs, and build config.

**Target**: 4-8 groups depending on package count.

## Step 3: Spawn sub-agents

For each group, spawn a sub-agent using the Task tool with `subagent_type=Explore`. Launch up to **3 sub-agents in parallel**.

### Sub-agent prompt template

```
Analyze the following source files from a TypeScript/React + Go BFF monorepo at {repo_path}.
This group covers: {group_description}.

Read EVERY file listed below. Do not skip any. Do not read test files (*test*, *spec*, __tests__).

Files to read:
{file_list}

For EACH file you read, extract and report ALL of the following that apply:

## API Surface
Every REST endpoint, proxy target, or WebSocket handler.
Report as a table:

| File | Line(s) | Method | Path | Auth | Purpose |
|------|---------|--------|------|------|---------|

Include: Express/Fastify route registrations, Go httprouter handlers, proxy targets,
fetch/axios calls to backend APIs, gRPC-web calls.

## Module Federation
Every module federation configuration (host or remote).
Report as a table:

| File | Line(s) | Role | Name | Exposes/Remotes | Shared Deps |
|------|---------|------|------|-----------------|-------------|

## Frontend Routes
Every React Router route definition.
Report as a table:

| File | Line(s) | Path | Component | Auth Required | Purpose |
|------|---------|------|-----------|---------------|---------|

## State Management
Redux stores, slices, thunks, or context providers that manage shared state.
Report as a table:

| File | Line(s) | Store/Slice | Key State | API Calls | Purpose |
|------|---------|-------------|-----------|-----------|---------|

## BFF Handlers (Go)
Every HTTP handler function in Go BFF code.
Report as a table:

| File | Line(s) | Method | Path | Upstream Call | Auth | Purpose |
|------|---------|--------|------|---------------|------|---------|

## Upstream Service Calls
Every call to an external service (API, gRPC, database, K8s API).
Report as a table:

| File | Line(s) | Target Service | Protocol | Auth | Purpose |
|------|---------|----------------|----------|------|---------|

## Configuration
Every environment variable, CLI flag, or config file reference.
Report as a table:

| File | Line(s) | Name | Type | Default | Purpose |
|------|---------|------|------|---------|---------|

## Plugin Extension Points
Every plugin API surface — what extensions a package exposes or consumes.
Report as a table:

| File | Line(s) | Extension Point | Direction | Type Signature | Purpose |
|------|---------|-----------------|-----------|----------------|---------|

CRITICAL: Read EVERY file. Report EVERY finding. Include file paths and
line numbers for all entries.
```

## Step 4: Aggregate sub-agent findings

After all sub-agents return, merge their findings:

1. **API Surface tables** → Network Architecture (Services, Ingress). Map each endpoint to the component that serves it. Include proxy chains (frontend → backend proxy → BFF → upstream API).

2. **Module Federation tables** → Architecture Components. Document the host/remote relationship, shared singleton dependencies, and deployment topology.

3. **Frontend Routes tables** → Architecture Components. Map the user-facing navigation structure.

4. **BFF Handlers + Upstream Service Calls** → Integration Points. Each BFF-to-upstream call is an integration point. Document the full call chain: user → frontend → backend proxy → BFF → upstream service.

5. **Configuration tables** → Deployment Configuration. Group by component, noting which env vars are shared vs. component-specific.

6. **Plugin Extension Points** → Architecture Components. Document the plugin API contract between host app and federated modules.

### Key architectural patterns to synthesize

- **Proxy chain**: Frontend → Node.js backend (Fastify proxy) → Go BFF → upstream K8s/ML service. Document every hop.
- **Module federation topology**: Which packages are remotes, which is the host, what gets shared (React, PatternFly, SDK).
- **Auth flow**: How authentication propagates through the proxy chain (user token → backend → BFF → upstream).
- **Deployment modes**: Standalone (BFF serves its own frontend) vs. federated (host app loads remote entry).
