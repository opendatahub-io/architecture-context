# Architecture Diagrams for Text Generation Inference Server (TGIS)

Generated from: `architecture/rhoai.next/text-generation-inference.md`
Date: 2026-10-07

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./text-generation-inference-component.mmd) - Internal components (launcher, router, shards, custom kernels)
- [Data Flows](./text-generation-inference-dataflow.mmd) - Sequence diagrams: text generation request, health probe, model loading
- [Dependencies](./text-generation-inference-dependencies.mmd) - Rust, Python, system, and external service dependencies

### For Architects
- [C4 Context](./text-generation-inference-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./text-generation-inference-component.mmd) - High-level component view with process boundaries

### For Security Teams
- [Security Network Diagram (Mermaid)](./text-generation-inference-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./text-generation-inference-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./text-generation-inference-rbac.mmd) - RBAC permissions, pod security context, auth mechanisms

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
/generate-architecture-diagrams --architecture=../text-generation-inference.md
```
