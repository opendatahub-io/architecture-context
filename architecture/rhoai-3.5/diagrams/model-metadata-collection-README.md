# Architecture Diagrams for model-metadata-collection

Generated from: `architecture/rhoai-3.5/model-metadata-collection.md`
Date: 2026-07-23

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./model-metadata-collection-component.mmd) - Internal components and pipeline stages
- [Data Flows](./model-metadata-collection-dataflow.mmd) - Sequence diagram of all three catalog pipelines (model, MCP, agents)
- [Dependencies](./model-metadata-collection-dependencies.mmd) - Component dependency graph

### For Architects
- [C4 Context](./model-metadata-collection-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./model-metadata-collection-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./model-metadata-collection-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./model-metadata-collection-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./model-metadata-collection-rbac.mmd) - Authentication and credential summary (no K8s RBAC — CLI tool)

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
/generate-architecture-diagrams --architecture=../model-metadata-collection.md
```
