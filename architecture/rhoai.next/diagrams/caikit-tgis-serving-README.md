# Architecture Diagrams for caikit-tgis-serving

Generated from: `architecture/rhoai.next/caikit-tgis-serving.md`
Date: 2026-06-22

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./caikit-tgis-serving-component.mmd) - Internal components (Caikit runtime, TGIS, storage initializer, API endpoints)
- [Data Flows](./caikit-tgis-serving-dataflow.mmd) - Sequence diagrams: HTTP inference, gRPC inference, streaming, metrics, model loading
- [Dependencies](./caikit-tgis-serving-dependencies.mmd) - Python library, platform, and external service dependencies

### For Architects
- [C4 Context](./caikit-tgis-serving-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./caikit-tgis-serving-component.mmd) - High-level component view with pod structure

### For Security Teams
- [Security Network Diagram (Mermaid)](./caikit-tgis-serving-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./caikit-tgis-serving-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./caikit-tgis-serving-rbac.mmd) - RBAC context (platform-managed, with Istio auth details)

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
/generate-architecture-diagrams --architecture=../caikit-tgis-serving.md
```
