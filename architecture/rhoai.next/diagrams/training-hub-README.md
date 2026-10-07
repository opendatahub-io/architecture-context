# Architecture Diagrams for Training Hub

Generated from: `architecture/rhoai.next/training-hub.md`
Date: 2026-10-07

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./training-hub-component.mmd) - Internal components
- [Data Flows](./training-hub-dataflow.mmd) - Sequence diagram of request/response flows
- [Dependencies](./training-hub-dependencies.mmd) - Component dependency graph

### For Architects
- [C4 Context](./training-hub-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-hub-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./training-hub-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-hub-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-hub-rbac.mmd) - RBAC permissions and bindings

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
/generate-architecture-diagrams --architecture=../training-hub.md
```
