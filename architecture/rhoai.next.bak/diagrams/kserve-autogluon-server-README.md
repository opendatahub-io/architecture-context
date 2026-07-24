# Architecture Diagrams for kserve-autogluon-server

Generated from: `architecture/rhoai.next/kserve-autogluon-server.md`
Date: 2026-06-30

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./kserve-autogluon-server-component.mmd) - Internal components (predictor factory, tabular/timeseries models, kserve SDK)
- [Data Flows](./kserve-autogluon-server-dataflow.mmd) - Sequence diagram of model loading, tabular inference, and time series forecast flows
- [Dependencies](./kserve-autogluon-server-dependencies.mmd) - Component dependency graph (AutoGluon, kserve SDK, ML backends, cloud storage)

### For Architects
- [C4 Context](./kserve-autogluon-server-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kserve-autogluon-server-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./kserve-autogluon-server-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kserve-autogluon-server-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kserve-autogluon-server-rbac.mmd) - Auth delegation model (no RBAC roles; auth via kube-rbac-proxy sidecar)

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
/generate-architecture-diagrams --architecture=../kserve-autogluon-server.md
```
