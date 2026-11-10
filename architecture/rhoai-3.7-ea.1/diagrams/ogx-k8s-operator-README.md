# Architecture Diagrams for OGX K8s Operator

Generated from: `architecture/rhoai-3.7-ea.1/ogx-k8s-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: Two operators live in this repo. `ogx-module` reconciles the cluster-scoped `OGX` CR and installs the root OGX operator. The root operator reconciles namespaced `OGXServer` CRs into OGX server workloads. Both Praxis mode and legacy external-access mode are shown.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./ogx-k8s-operator-component.mmd) - ogx-module, the OGX operator (controller, webhook, config generator, kustomize deployer), per-OGXServer resources
- [Data Flows](./ogx-k8s-operator-dataflow.mmd) - Sequence diagram: module install, OGXServer reconciliation, Praxis-mode traffic, legacy external access
- [Dependencies](./ogx-k8s-operator-dependencies.mmd) - Go libraries, platform integrations, external services

### For Architects
- [C4 Context](./ogx-k8s-operator-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./ogx-k8s-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./ogx-k8s-operator-security-network.mmd) - Trust zones, ports, TLS, auth (editable)
- [Security Network Diagram (ASCII)](./ogx-k8s-operator-security-network.txt) - Precise text format for SAR submissions, with RBAC, NetworkPolicy, TLS and Secrets summary
- [RBAC Visualization](./ogx-k8s-operator-rbac.mmd) - Service accounts, bindings, roles and permissions for both operators and per-OGXServer SAs

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks; it renders automatically
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
- Suited to security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/ogx-k8s-operator.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
