# Architecture Diagrams for llm-d-model-service

Generated from: `architecture/rhoai-3.7-ea.1/llm-d-model-service.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned). This index is named `llm-d-model-service-README.md` so it does not overwrite the shared platform `README.md` in this directory.

**Lifecycle**: Upstream marks this operator deprecated, superseded by the `llm-d-incubation/llm-d-modelservice` Helm chart. No Konflux build exists on the analyzed branch.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./llm-d-model-service-component.mmd) - Reconciler pipeline (interpolate → merge → CreateOrUpdate) and child resources
- [Data Flows](./llm-d-model-service-dataflow.mmd) - Reconciliation, inference runtime path, metrics scrape
- [Dependencies](./llm-d-model-service-dependencies.mmd) - Go libraries, runtime CRDs, llm-d images, successor

### For Architects
- [C4 Context](./llm-d-model-service-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./llm-d-model-service-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./llm-d-model-service-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./llm-d-model-service-security-network.txt) - Precise text format for SAR submissions, including RBAC, secrets, findings
- [RBAC Visualization](./llm-d-model-service-rbac.mmd) - Controller and EPP RBAC, including the cluster-wide `$EPP_CLUSTER_ROLE` binding

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks - renders automatically
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
- Suited to security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/llm-d-model-service.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
