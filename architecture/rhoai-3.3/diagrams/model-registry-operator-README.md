# Architecture Diagrams for Model Registry Operator

Generated from: `architecture/rhoai-3.3/model-registry-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - Mermaid diagram showing internal components
- [Data Flows](./model-registry-operator-dataflow.png) ([mmd](./model-registry-operator-dataflow.mmd)) - Sequence diagram of request/response flows
- [Dependencies](./model-registry-operator-dependencies.png) ([mmd](./model-registry-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./model-registry-operator-component.png) ([mmd](./model-registry-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./model-registry-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./model-registry-operator-rbac.png) ([mmd](./model-registry-operator-rbac.mmd)) - RBAC permissions and bindings

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks - renders automatically!
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG regeneration** (if you edit .mmd files):

1. **Ensure Mermaid CLI is installed**:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. **Regenerate PNG** (3000px width):
   ```bash
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

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
/generate-architecture-diagrams --architecture=../model-registry-operator.md
```
