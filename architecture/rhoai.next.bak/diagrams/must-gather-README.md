# Architecture Diagrams for must-gather

Generated from: `architecture/rhoai.next/must-gather.md`
Date: 2026-06-30

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./must-gather-component.mmd) - Internal components (gather.sh dispatcher, 13 parallel component gatherers, LLM-D sub-gatherers, dependency collectors)
- [Data Flows](./must-gather-dataflow.mmd) - Sequence diagrams for OpenShift must-gather, xKS Job, and parallel collection flows
- [Dependencies](./must-gather-dependencies.mmd) - Component dependency graph showing all 20+ CRD read targets

### For Architects
- [C4 Context](./must-gather-c4-context.dsl) - System context in C4 format (Structurizr) showing must-gather's relationship to all RHOAI components
- [Component Overview](./must-gather-component.mmd) - High-level component view with script hierarchy

### For Security Teams
- [Security Network Diagram (Mermaid)](./must-gather-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./must-gather-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./must-gather-rbac.mmd) - RBAC permissions comparing OpenShift (cluster-admin) vs xKS (read-only) modes

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
/generate-architecture-diagrams --architecture=../must-gather.md
```
