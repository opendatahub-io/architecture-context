# Architecture Diagrams for Model Registry Operator

Generated from: `architecture/rhoai-3.7-ea.1/model-registry-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./model-registry-operator-component.mmd) - One binary, three operators (AIHub, ModelRegistry, Catalog), their CRs and the per-registry and catalog workloads they create
- [Data Flows](./model-registry-operator-dataflow.mmd) - Sequence diagram: module installation, ModelRegistry provisioning, client access via data-science-gateway, catalog data image update
- [Dependencies](./model-registry-operator-dependencies.mmd) - Go libraries, rhods-operator, container images, gateway, consumers

### For Architects
- [C4 Context](./model-registry-operator-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./model-registry-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./model-registry-operator-security-network.mmd) - Trust zones, dual ingress (Gateway API + reencrypt Route), kube-rbac-proxy enforcement, plaintext DB links
- [Security Network Diagram (ASCII)](./model-registry-operator-security-network.txt) - Precise text format for SAR submissions (ports, TLS, NetworkPolicies, RBAC, webhooks, secrets, risks)
- [RBAC Visualization](./model-registry-operator-rbac.mmd) - Operator and runtime service accounts, bindings, groups and permissions (highlights privileged aihub-manager-role)

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks; renders automatically
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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/model-registry-operator.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
