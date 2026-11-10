# Architecture Diagrams for llm-d-autoscaling

Generated from: `architecture/rhoai-3.7-ea.1/llm-d-autoscaling.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: On `main` (b6be439), llm-d-autoscaling ships KEDA `ScaledObject` blueprints and a benchmark test bed. It adds no runtime of its own: KEDA does the scaling, using Prometheus queries. The Workload-Variant-Autoscaler (WVA) controller is deprecated and frozen in `legacy/`. It is drawn grey/dashed, and it is the only source of the network and RBAC surface shown here. This branch has no Konflux build.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./llm-d-autoscaling-component.mmd) - Blueprints, staging scenarios, benchmark, Kind emulator; legacy WVA reconcilers and engines
- [Data Flows](./llm-d-autoscaling-dataflow.mmd) - KEDA blueprint scaling, the WVA optimize loop (two trips through Prometheus), scale-from-zero
- [Dependencies](./llm-d-autoscaling-dependencies.mmd) - KEDA, Prometheus, llm-d-benchmark; WVA Go libraries and platform integrations

### For Architects
- [C4 Context](./llm-d-autoscaling-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./llm-d-autoscaling-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./llm-d-autoscaling-security-network.mmd) - Trust zones; the plaintext EPP scrape that carries a bearer token is highlighted
- [Security Network Diagram (ASCII)](./llm-d-autoscaling-security-network.txt) - Precise text format for SAR submissions: ports, TLS, auth, RBAC, secrets, observations
- [RBAC Visualization](./llm-d-autoscaling-rbac.mmd) - Service accounts, bindings, ClusterRoles; write permissions highlighted

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks
- **Live editor**: https://mermaid.live

**Manual PNG generation** (if needed):
```bash
npm install -g @mermaid-js/mermaid-cli
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
```

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor; include as-is in security reviews

## Updating Diagrams

```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/llm-d-autoscaling.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
