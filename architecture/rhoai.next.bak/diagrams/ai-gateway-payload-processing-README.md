# Architecture Diagrams for AI Gateway Payload Processing

Generated from: `architecture/rhoai.next/ai-gateway-payload-processing.md`
Date: 2026-06-30

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./ai-gateway-payload-processing-component.mmd) - Internal components, plugin pipeline, controllers, CRDs
- [Data Flows](./ai-gateway-payload-processing-dataflow.mmd) - Sequence diagram of inference request and provider reconciliation flows
- [Dependencies](./ai-gateway-payload-processing-dependencies.mmd) - Component dependency graph (framework, platform, providers)

### For Architects
- [C4 Context](./ai-gateway-payload-processing-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./ai-gateway-payload-processing-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./ai-gateway-payload-processing-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./ai-gateway-payload-processing-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./ai-gateway-payload-processing-rbac.mmd) - RBAC permissions and bindings

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
/generate-architecture-diagrams --architecture=../ai-gateway-payload-processing.md
```
