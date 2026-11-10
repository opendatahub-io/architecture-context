# Architecture Diagrams for vllm-orchestrator-gateway

Generated from: `architecture/rhoai-3.7-ea.1/vllm-orchestrator-gateway.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

> **Release status**: The RHOAI Konflux image is offboarded for 3.7-ea.1 (RHOAIENG-97573). Only the ODH image is referenced, and no RHOAI 3.7-ea.1 operator in the analyzed checkouts deploys the gateway.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./vllm-orchestrator-gateway-component.mmd) - Config loader, per-route handlers, detector injection, fallback substitution, orchestrator TLS/mTLS client
- [Data Flows](./vllm-orchestrator-gateway-dataflow.mmd) - Sequence diagram: non-streaming and streaming (SSE) guarded chat completions
- [Dependencies](./vllm-orchestrator-gateway-dependencies.mmd) - Rust crates, FMS Guardrails Orchestrator, detectors, vLLM, service-ca, operators

### For Architects
- [C4 Context](./vllm-orchestrator-gateway-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./vllm-orchestrator-gateway-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./vllm-orchestrator-gateway-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./vllm-orchestrator-gateway-security-network.txt) - Precise text format for SAR submissions (plain HTTP listener, bearer pass-through, implicit TLS/mTLS by file presence, DEBUG token logging)
- [RBAC Visualization](./vllm-orchestrator-gateway-rbac.mmd) - No Kubernetes RBAC; effective route-level access and delegated enforcement

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks; renders automatically
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
- Suited to security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/vllm-orchestrator-gateway.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
