# Architecture Diagrams for Model Registry

Generated from: `architecture/rhoai-3.7-ea.1/model-registry.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: The RHOAI build ships one Go image, `odh-model-registry-rhel9`, with two roles: `proxy` (Model Registry REST) and `catalog` (Model Catalog). It also ships the Python `odh-model-registry-job-async-upload-rhel9` Job. The InferenceService controller is a library embedded in model-registry-operator. The upstream controller, UI/BFF, frontend and CSI are not built here and appear as dashed or upstream-only elements. Both servers serve plain HTTP with no in-process auth, so access control depends on the operator-managed proxy.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./model-registry-component.mmd) - proxy and catalog roles (catalog plugins, leader election), async-upload Job, ISVC controller library, data stores
- [Data Flows](./model-registry-dataflow.mmd) - Sequence diagram: dashboard registration/query, catalog ingestion and browsing, async upload Job, InferenceService sync
- [Dependencies](./model-registry-dependencies.mmd) - Data stores, key Go/Python libraries, internal RHOAI integrations, external services

### For Architects
- [C4 Context](./model-registry-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./model-registry-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./model-registry-security-network.mmd) - Trust zones, ports, TLS, auth, and the unauthenticated plain-HTTP surfaces highlighted in red
- [Security Network Diagram (ASCII)](./model-registry-security-network.txt) - Precise text format for SAR submissions, including RBAC, secrets and key risks
- [RBAC Visualization](./model-registry-rbac.mmd) - Upstream controller ServiceAccount, bindings, roles and permissions

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks - renders automatically!
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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/model-registry.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
