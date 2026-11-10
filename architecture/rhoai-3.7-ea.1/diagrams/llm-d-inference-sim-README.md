# Architecture Diagrams for llm-d-inference-sim

Generated from: `architecture/rhoai-3.7-ea.1/llm-d-inference-sim.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: A GPU-free simulator that imitates a vLLM model server (OpenAI-compatible HTTP, the vLLM gRPC engine API, Prometheus metrics, ZMQ KV-cache events). In RHOAI 3.7 EA.1 it is a test and development utility for the llm-d stack, not a production runtime. It has no CRDs, no RBAC and no authentication.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./llm-d-inference-sim-component.mmd) - cmux listener, HTTP/gRPC servers, engine personalities, simulator core, KV cache/ZMQ, render sidecar
- [Data Flows](./llm-d-inference-sim-dataflow.mmd) - Sequence diagram: HTTP inference, gRPC generate, KV-event publication/replay, metrics and `/admin/config`
- [Dependencies](./llm-d-inference-sim-dependencies.mmd) - Go libraries, llm-d-router library, runtime integrations, external services

### For Architects
- [C4 Context](./llm-d-inference-sim-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./llm-d-inference-sim-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./llm-d-inference-sim-security-network.mmd) - Trust zones, ports, encryption, unauthenticated surfaces
- [Security Network Diagram (ASCII)](./llm-d-inference-sim-security-network.txt) - Precise text format for SAR submissions, including TLS, secrets, FIPS and key risks
- [RBAC Visualization](./llm-d-inference-sim-rbac.mmd) - No Kubernetes RBAC; the application-level surfaces that are open without authentication

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks - renders automatically!
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
- Perfect for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/llm-d-inference-sim.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
