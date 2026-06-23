# Architecture Diagrams for ML Metadata (MLMD)

Generated from: `architecture/rhoai.next/ml-metadata.md`
Date: 2026-06-22

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./ml-metadata-component.mmd) - Internal components
- [Data Flows](./ml-metadata-dataflow.mmd) - Sequence diagram of request/response flows
- [Dependencies](./ml-metadata-dependencies.mmd) - Component dependency graph

### For Architects
- [C4 Context](./ml-metadata-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./ml-metadata-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./ml-metadata-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./ml-metadata-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./ml-metadata-rbac.mmd) - RBAC permissions and bindings

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
/generate-architecture-diagrams --architecture=../ml-metadata.md
```
