# Architecture Diagrams for pipelines-components

Generated from: `architecture/rhoai-3.7-ea.1/pipelines-components.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: `pipelines-components` (Python package `kfp-components` 1.11.0) is a library of KFP v2 components and pipelines. It ships four Konflux images. `odh-pipelines-components` is a one-shot init container that DSPO adds to the KFP API server pod to stage managed pipelines in `/config/managed-pipelines`. `odh-automl` and `odh-autorag` are task runtime images. `odh-autorag-inference` is a placeholder. The repo runs no long-lived service and defines no Services, CRDs or RBAC. All network traffic comes from pipeline task pods. The agentic-rag starter kit is a template that AutoRAG emits; it is drawn with dashed borders.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./pipelines-components-component.mmd) - Library categories, build-time compiler, init container, runtime images, and the resources the components act on
- [Data Flows](./pipelines-components-dataflow.mmd) - Sequence diagram: managed-pipeline staging, AutoRAG optimization run, fine-tune and deploy
- [Dependencies](./pipelines-components-dependencies.mmd) - Python libraries, base images, platform integrations, external services

### For Architects
- [C4 Context](./pipelines-components-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./pipelines-components-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./pipelines-components-security-network.mmd) - Trust zones and task-pod egress with ports, TLS and auth; plain-HTTP Model Registry highlighted
- [Security Network Diagram (ASCII)](./pipelines-components-security-network.txt) - Precise text format for SAR submissions, including RBAC, secrets, crypto and supply-chain notes
- [RBAC Visualization](./pipelines-components-rbac.mmd) - Task pod identities and the namespace permissions they need. Roles are defined outside this repo, and verbs are inferred

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
- Use for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/pipelines-components.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
