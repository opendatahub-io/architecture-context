# Architecture Diagrams for odh-model-controller

Generated from: `../odh-model-controller.md`
Date: 2026-05-07

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./odh-model-controller-component.mmd) - Internal components (8 controllers, 4 webhooks, sub-resource reconcilers, NIM handlers)
- [Data Flows](./odh-model-controller-dataflow.mmd) - Sequence diagrams: InferenceService deployment, NIM reconciliation, Gateway discovery
- [Dependencies](./odh-model-controller-dependencies.mmd) - Component dependency graph (required/optional external + internal platform)

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-model-controller-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-model-controller-rbac.mmd) - RBAC permissions and bindings (20+ API groups)

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
/generate-architecture-diagrams --architecture=../odh-model-controller.md
```
