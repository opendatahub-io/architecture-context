# Architecture Diagrams for KServe

Generated from: `../kserve.md`
Date: 2026-06-30

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./kserve-component.mmd) - Internal components (controllers, sidecars, init containers, routing)
- [Data Flows](./kserve-dataflow.mmd) - Sequence diagrams for InferenceService deployment, LLM disaggregated serving, and InferenceGraph routing
- [Dependencies](./kserve-dependencies.mmd) - Component dependency graph (Knative, Istio, Gateway API, KEDA, llm-d, vLLM runtimes)

### For Architects
- [C4 Context](./kserve-c4-context.dsl) - System context in C4 format (Structurizr) showing KServe in the broader ODH/RHOAI ecosystem
- [Component Overview](./kserve-component.mmd) - High-level component view with CRDs and external dependencies

### For Security Teams
- [Security Network Diagram (Mermaid)](./kserve-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./kserve-security-network.txt) - Precise text format for SAR submissions with ports, protocols, TLS, auth, RBAC, secrets
- [RBAC Visualization](./kserve-rbac.mmd) - RBAC permissions and bindings for kserve-manager-role

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
/generate-architecture-diagrams --architecture=../kserve.md
```
