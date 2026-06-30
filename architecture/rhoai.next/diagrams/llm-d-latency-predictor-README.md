# Architecture Diagrams for llm-d-latency-predictor

Generated from: `architecture/rhoai.next/llm-d-latency-predictor.md`
Date: 2026-06-30

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./llm-d-latency-predictor-component.mmd) - Internal components (training server, prediction server, model sync)
- [Data Flows](./llm-d-latency-predictor-dataflow.mmd) - Sequence diagram of model training, sync, and prediction flows
- [Dependencies](./llm-d-latency-predictor-dependencies.mmd) - Component dependency graph (llm-d ecosystem + Python ML libraries)

### For Architects
- [C4 Context](./llm-d-latency-predictor-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./llm-d-latency-predictor-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./llm-d-latency-predictor-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./llm-d-latency-predictor-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./llm-d-latency-predictor-rbac.mmd) - RBAC permissions and bindings (highlights gaps - no RBAC configured)

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
/generate-architecture-diagrams --architecture=../llm-d-latency-predictor.md
```
