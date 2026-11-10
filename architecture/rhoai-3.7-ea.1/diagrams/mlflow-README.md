# Architecture Diagrams for MLflow

Generated from: `architecture/rhoai-3.7-ea.1/mlflow.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: One shared MLflow tracking server (image `quay.io/rhoai/odh-mlflow-rhel9`), deployed by the MLflow Operator and reached through the ODH data science gateway at `/mlflow`. Each namespace is an MLflow workspace. The `kubernetes-auth` plugin authorizes every request with a SelfSubjectAccessReview. The AI Gateway, Assistant, job runner and telemetry are turned off in the image and are drawn as dashed elements.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./mlflow-component.mmd) - FastAPI routers, mounted Flask API, UI, kubernetes-auth plugin, workspace provider, disabled features
- [Data Flows](./mlflow-dataflow.mmd) - Sequence diagram: API request with SSAR, artifact proxying, workspace discovery
- [Dependencies](./mlflow-dependencies.mmd) - Plugin, Python libraries, platform integrations, backing services

### For Architects
- [C4 Context](./mlflow-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./mlflow-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./mlflow-security-network.mmd) - Trust zones, ports, TLS, auth per hop
- [Security Network Diagram (ASCII)](./mlflow-security-network.txt) - Precise text format for SAR submissions, including RBAC, multi-tenancy and secrets
- [RBAC Visualization](./mlflow-rbac.mmd) - Server ServiceAccount permissions and per-caller SSAR model (roles are operator-defined)

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks
- **Live editor**: https://mermaid.live (paste code, edit, export)

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
- Suitable for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/mlflow.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
