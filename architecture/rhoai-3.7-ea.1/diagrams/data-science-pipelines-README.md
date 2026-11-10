# Architecture Diagrams for Data Science Pipelines

Generated from: `architecture/rhoai-3.7-ea.1/data-science-pipelines.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./data-science-pipelines-component.mmd) - API server (compiler, webhook, MLflow plugin), persistence agent, ScheduledWorkflow controller, driver/launcher, CRDs
- [Data Flows](./data-science-pipelines-dataflow.mmd) - Sequence diagram of run submission, task execution, status persistence, recurring runs, PipelineVersion admission
- [Dependencies](./data-science-pipelines-dependencies.mmd) - Go libraries, runtime services, RHOAI integrations (DSPO, Argo, MLMD, MLflow, Dashboard)

### For Architects
- [C4 Context](./data-science-pipelines-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./data-science-pipelines-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./data-science-pipelines-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./data-science-pipelines-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./data-science-pipelines-rbac.mmd) - RBAC permissions and bindings (highlights the broad `pipeline-runner` Role)

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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/data-science-pipelines.md
```
