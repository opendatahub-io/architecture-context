# Architecture Diagrams for Argo Workflows

Generated from: `architecture/rhoai-3.7-ea.1/argo-workflows.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: RHOAI ships only `workflow-controller` and `argoexec`. Data Science Pipelines Operator (DSPO) deploys one namespaced controller per DSPA. The upstream `argo-server`, `argo` CLI, SSO and SQL archive appear as dashed "not shipped" elements.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./argo-workflows-component.mmd) - workflow-controller, step pod (argoexec init/main/wait), agent pod, the 8 argoproj.io CRDs, DSPO/KFP integration
- [Data Flows](./argo-workflows-dataflow.mmd) - Sequence diagram: KFP pipeline run execution, HTTP template execution via agent, metrics scrape
- [Dependencies](./argo-workflows-dependencies.mmd) - Internal RHOAI integrations, required Go libraries, optional artifact drivers, argo-server-only libraries

### For Architects
- [C4 Context](./argo-workflows-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./argo-workflows-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./argo-workflows-security-network.mmd) - Trust zones: monitoring namespaces, control plane, DSPA namespace, external services
- [Security Network Diagram (ASCII)](./argo-workflows-security-network.txt) - Precise text format for SAR submissions, with RBAC, NetworkPolicy, secrets and security observations
- [RBAC Visualization](./argo-workflows-rbac.mmd) - DSPO namespace Role (RHOAI) and the upstream argo-cluster-role / argo-role / argo-server-cluster-role

## Key Security Points
- No Routes, Ingress or Gateway resources. The controller listens on 9090/TCP (HTTPS metrics, self-signed, no auth, NetworkPolicy-restricted) and 6060/TCP (plain-HTTP `/healthz`, unauthenticated).
- argoexec has no listening ports. It sends egress to the kube API (6443), object storage (443), Git (443/22) and user HTTP endpoints.
- HTTP templates can turn off TLS verification per template (`insecureSkipVerify`).
- FIPS uses Go's native FIPS 140-3 module (`GOFIPS140=v1.0.0`, static, CGO disabled), not dynamically linked OpenSSL.

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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/argo-workflows.md
```
