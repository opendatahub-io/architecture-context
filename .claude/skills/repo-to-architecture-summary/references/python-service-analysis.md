# Python Service Analysis

Analyze Python ML/AI services to extract API surfaces, serving protocols, model loading patterns, configuration, health probes, and dependencies. Covers both REST (FastAPI/Flask) and gRPC services, as well as dual-protocol servers.

## When to use

The repository has ANY of:
- `pyproject.toml`, `setup.py`, or `requirements.txt` at the root
- Python source directories with server/entrypoint code
- `.proto` files defining gRPC services

## When to use sub-agents

```bash
PY_COUNT=$(find . -path ./vendor -prune -o -path ./.venv -prune -o -name "*.py" ! -name "*test*" ! -name "*_test.py" ! -path "*/tests/*" -print | wc -l)
PROTO_COUNT=$(find . -name "*.proto" -print | wc -l)
echo "Python files: $PY_COUNT, Proto files: $PROTO_COUNT"
```

- **100 or fewer files**: Read them yourself. No sub-agents needed.
- **More than 100 files**: Use sub-agents as described below.

## Step 1: Enumerate source files

```bash
# All non-test Python files (exclude venv, vendor, tests)
find . -path ./.venv -prune -o -path ./vendor -prune -o -path ./.tox -prune -o \
  -name "*.py" ! -name "*test*" ! -name "*_test.py" ! -name "conftest.py" \
  ! -path "*/tests/*" ! -path "*/test/*" ! -path "*/__pycache__/*" -print | sort

# Proto files
find . -name "*.proto" -print | sort

# Config files
find . -maxdepth 3 \( -name "*.yaml" -o -name "*.yml" -o -name "*.toml" -o -name "*.cfg" \) \
  ! -path "*/tests/*" ! -name "tox.ini" -print | sort
```

## Step 2: Group files into sub-agent batches

**Grouping heuristics** (adapt based on what you find):

1. **Entrypoints and server** — `__main__.py`, `server.py`, `app.py`, `cli/`, `entrypoints/`, `cmd/`. The server startup, route registration, and request handling. Start here — this is the most architecturally critical group.

2. **API layer** — `api/`, `routes/`, `rest/`, `grpc/`, `handlers/`, `views/`. REST route handlers, gRPC servicers, request/response models.

3. **Core/engine** — The main business logic. For ML services: model loading, inference engine, tokenization, batching. For platforms: experiment tracking, artifact management, workflow execution.

4. **Configuration and infrastructure** — `config/`, `settings/`, `utils/`, `common/`. Config models, logging, metrics, health probes.

5. **Proto/gRPC definitions** — `.proto` files and generated code. Document the service definitions and message types.

**Target**: 3-5 groups. Fewer for smaller services.

### Example groupings

**caikit** (~300 .py files):
| Group | Directories | Purpose |
|-------|------------|---------|
| 1 | `caikit/runtime/`, `caikit_health_probe/` | Server startup, gRPC+HTTP servers, health probes |
| 2 | `caikit/core/` | Module system, task definitions, data model |
| 3 | `caikit/config/`, `caikit/interfaces/` | Configuration, public interfaces |

**vllm-cpu** (~2700 .py files):
| Group | Directories | Purpose |
|-------|------------|---------|
| 1 | `vllm/entrypoints/` | All server entrypoints (OpenAI, gRPC, API) |
| 2 | `vllm/engine/`, `vllm/executor/` | Inference engine, scheduling, execution |
| 3 | `vllm/model_executor/` | Model loading, weight management |
| 4 | `vllm/config.py`, `vllm/sampling_params.py`, `vllm/utils/` | Configuration, common utilities |

## Step 3: Spawn sub-agents

For each group, spawn a sub-agent using the Task tool with `subagent_type=Explore`. Launch up to **3 sub-agents in parallel**.

### Sub-agent prompt template

```
Analyze the following Python source files from {repo_path}.
This group covers: {group_description}.

Read EVERY file listed below. Do not skip any. Do not read test files.

Files to read:
{file_list}

For EACH file you read, extract and report ALL of the following that apply:

## API Endpoints
Every REST endpoint (FastAPI/Flask/Starlette route) or gRPC servicer method.
Report as a table:

| File | Line(s) | Method | Path/RPC | Request Type | Response Type | Auth | Purpose |
|------|---------|--------|----------|-------------|--------------|------|---------|

Include: @app.get/post/put/delete decorators, router.add_api_route, Flask @route,
gRPC servicer methods, WebSocket endpoints.

## Proto/gRPC Definitions
Every service and message defined in .proto files.
Report as a table:

| File | Line(s) | Service | RPC Method | Request Message | Response Message | Streaming |
|------|---------|---------|------------|-----------------|-----------------|-----------|

## Configuration
Every config parameter, environment variable, CLI argument, or settings field.
Report as a table:

| File | Line(s) | Name | Source | Type | Default | Purpose |
|------|---------|------|--------|------|---------|---------|

Source = env var, CLI arg, YAML field, Pydantic field, etc.

## Health & Readiness
Every health check, liveness probe, or readiness endpoint.
Report as a table:

| File | Line(s) | Endpoint/Method | Protocol | What It Checks | Purpose |
|------|---------|-----------------|----------|----------------|---------|

## Dependencies & Integrations
Every external service call, database connection, or SDK client.
Report as a table:

| File | Line(s) | Target | Protocol | Client Library | Purpose |
|------|---------|--------|----------|----------------|---------|

Include: HTTP clients (requests, httpx, aiohttp), gRPC channels, database engines
(SQLAlchemy, psycopg2), K8s client, cloud SDKs (boto3), model registries.

## Model/Runtime Architecture
For ML services: how models are loaded, cached, and served.
Report as a table:

| File | Line(s) | Pattern | Details | Purpose |
|------|---------|---------|---------|---------|

Include: model loading (torch.load, transformers.from_pretrained), weight management,
device placement (CPU/GPU/TPU), batching strategy, tokenizer initialization,
runtime selection (pluggable backends).

## Network Exposure
Every port binding, TLS configuration, or protocol declaration.
Report as a table:

| File | Line(s) | Port | Protocol | TLS | Bind Address | Purpose |
|------|---------|------|----------|-----|--------------|---------|

CRITICAL: Read EVERY file. Report EVERY finding. Include file paths and
line numbers for all entries.
```

## Step 4: Aggregate sub-agent findings

After all sub-agents return, merge their findings:

1. **API Endpoints + Proto tables** → Network Architecture (Services, Ingress). Document both REST and gRPC interfaces with exact ports, paths, and protocols.

2. **Configuration tables** → Deployment Configuration. Group by purpose (server, model, auth, observability). Note which configs are required vs. optional.

3. **Health & Readiness tables** → Network Architecture + Deployment. Document probe endpoints and what they validate.

4. **Dependencies tables** → Integration Points. Every external service call is an integration point. Document the full dependency chain.

5. **Model/Runtime tables** → Architecture Components. For ML services, the model loading and serving pipeline is the core architecture. Document device requirements, supported model formats, and serving protocols.

6. **Network Exposure tables** → Network Architecture (Services). Every port + protocol combination.

### Common Python service patterns to recognize

| Pattern | Services | What to document |
|---------|----------|-----------------|
| **Dual-protocol** (REST + gRPC) | caikit, MLServer | Both servers, which port each uses, shared vs. separate health checks |
| **OpenAI API compatibility** | vllm | Map endpoints to OpenAI spec (v1/completions, v1/chat/completions, v1/models) |
| **KServe v2 dataplane** | MLServer | Standard endpoints (v2/health/live, v2/health/ready, v2/models/*/infer) |
| **Plugin/runtime system** | MLServer, caikit | How runtimes are discovered, loaded, and managed |
| **Multi-backend** (gunicorn/uvicorn) | mlflow | Server selection, worker configuration, WSGI vs. ASGI |
| **Separate health binary** | caikit | Dedicated health probe process vs. integrated endpoint |
