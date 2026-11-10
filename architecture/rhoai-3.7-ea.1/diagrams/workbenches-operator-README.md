# Architecture Diagrams for workbenches-operator

Generated from: `architecture/rhoai-3.7-ea.1/workbenches-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./workbenches-operator-component.mmd) - Manager, reconciler, webhooks, TLS ensurer, bundled manifests and deployed operands
- [Data Flows](./workbenches-operator-dataflow.mmd) - Reconciliation, Notebook admission, and metrics scrape sequences
- [Dependencies](./workbenches-operator-dependencies.mmd) - Platform orchestrator, operands, webhook-time dependencies, cert providers

### For Architects
- [C4 Context](./workbenches-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./workbenches-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./workbenches-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./workbenches-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./workbenches-operator-rbac.mmd) - ClusterRoles, Roles, bindings and the resourceNames-scoped bind/escalate role

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks; renders automatically
- **Live editor**: https://mermaid.live (paste code, edit, export)

**Manual PNG generation** (if needed):
```bash
npm install -g @mermaid-js/mermaid-cli
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
```

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor; include in security reviews as-is

## Updating Diagrams

```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/workbenches-operator.md
```
