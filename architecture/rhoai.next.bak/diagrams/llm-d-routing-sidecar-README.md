# Architecture Diagrams for llm-d-routing-sidecar

Generated from: `architecture/rhoai.next/llm-d-routing-sidecar.md`
Date: 2026-06-30

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./llm-d-routing-sidecar-component.mmd) - Internal components (proxy server, P/D connectors, allowlist validator, TLS manager)
- [Data Flows](./llm-d-routing-sidecar-dataflow.mmd) - Sequence diagrams for P/D disaggregation, pass-through, and SSRF allowlist update flows
- [Dependencies](./llm-d-routing-sidecar-dependencies.mmd) - Component dependency graph (vLLM, InferencePool, K8s libraries)

### For Architects
- [C4 Context](./llm-d-routing-sidecar-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./llm-d-routing-sidecar-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./llm-d-routing-sidecar-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./llm-d-routing-sidecar-security-network.txt) - Precise text format for SAR submissions (includes RBAC, secrets, FIPS details)
- [RBAC Visualization](./llm-d-routing-sidecar-rbac.mmd) - RBAC permissions, role bindings, and SSRF protection enforcement

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ` ```mermaid ` code blocks - renders automatically!
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
/generate-architecture-diagrams --architecture=../llm-d-routing-sidecar.md
```
