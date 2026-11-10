# Architecture Diagrams for llm-d-batch-gateway

Generated from: `architecture/rhoai-3.7-ea.1/llm-d-batch-gateway.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: Three Go binaries deployed by the `batch-gateway` Helm chart: `batch-gateway-apiserver` (Deployment), `batch-gateway-processor` (StatefulSet) and `batch-gateway-gc` (Deployment). They coordinate only through PostgreSQL. Authentication is delegated entirely to the platform Gateway (Kuadrant AuthPolicy). The older `batch-gateway-*` files in this directory come from the previous component name. The `llm-d-batch-gateway-*` files are the current set.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./llm-d-batch-gateway-component.mmd) - apiserver, processor, gc, shared data/inference libraries, PostgreSQL/S3/Redis plane, External and Internal Gateways
- [Data Flows](./llm-d-batch-gateway-dataflow.mmd) - Sequence diagram covering upload and batch creation, sync dispatch with AIMD, async dispatch through Redis and llm-d-async, GC and orphan recovery, status polling
- [Dependencies](./llm-d-batch-gateway-dependencies.mmd) - External services, internal RHOAI integrations, key Go libraries

### For Architects
- [C4 Context](./llm-d-batch-gateway-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./llm-d-batch-gateway-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./llm-d-batch-gateway-security-network.mmd) - Trust zones, ports, TLS and auth per hop. Unauthenticated surfaces are highlighted.
- [Security Network Diagram (ASCII)](./llm-d-batch-gateway-security-network.txt) - Precise text format for SAR submissions, with RBAC, gateway policies, secrets and security observations
- [RBAC Visualization](./llm-d-batch-gateway-rbac.mmd) - The single namespaced Role `gc-pod-watcher`, ServiceAccounts and mounted secrets

## Key Security Points
- The API server has no in-process authentication. It trusts the `X-MaaS-Username` header (last value wins, defaults to `default`), and no NetworkPolicy ships with the chart. Any in-cluster caller that reaches 8000/TCP can impersonate any tenant.
- User `Authorization` headers (`passThroughHeaders: [Authorization]`) are stored in plaintext in PostgreSQL batch tags. In async mode they are also stored in Redis messages. They are replayed to the Internal Gateway for per-model SubjectAccessReview.
- The gateway → apiserver hop is plain HTTP unless `apiserver.tls.enabled` is set. OTLP export is insecure by default, and PostgreSQL TLS depends on `sslmode`.
- The observability ports 8081, 9090 and 9091 are unauthenticated plain HTTP. Optional pprof is served on the same listener.
- RBAC is minimal: one namespaced Role (pods and statefulsets, read-only) for the gc reconciler, and no ClusterRoles.
- The upstream Dockerfiles (`CGO_ENABLED=0`, distroless static) would fail the Konflux FIPS check-payload gate.

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks and it renders automatically.
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG generation** (if needed):
```bash
npm install -g @mermaid-js/mermaid-cli
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
```

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Suited to security reviews because the technical details are exact

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/llm-d-batch-gateway.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
