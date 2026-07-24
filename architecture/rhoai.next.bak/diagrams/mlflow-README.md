# Architecture Diagrams for MLflow

Generated from: `architecture/rhoai.next/mlflow.md`
Date: 2026-06-30

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./mlflow-component.mmd) - Internal components (Flask/FastAPI server, K8s plugins, UI, GC CronJob)
- [Data Flows](./mlflow-dataflow.mmd) - Sequence diagrams for SDK tracking, UI access, and OTLP trace ingestion
- [Dependencies](./mlflow-dependencies.mmd) - Component dependency graph (PostgreSQL, S3, K8s API, platform integrations)

### For Architects
- [C4 Context](./mlflow-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./mlflow-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./mlflow-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./mlflow-security-network.txt) - Precise text format for SAR submissions (includes RBAC, secrets, crypto, NetworkPolicy)
- [RBAC Visualization](./mlflow-rbac.mmd) - RBAC permissions, bindings, and auth plugin flow

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
/generate-architecture-diagrams --architecture=../mlflow.md
```
