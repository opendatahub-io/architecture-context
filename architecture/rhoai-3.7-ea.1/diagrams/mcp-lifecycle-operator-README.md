# Architecture Diagrams for mcp-lifecycle-operator

Generated from: `architecture/rhoai-3.7-ea.1/mcp-lifecycle-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: A single controller-runtime operator that reconciles `MCPServer` (mcp.x-k8s.io v1beta1) into managed Deployment/Service/NetworkPolicy resources or BYO references. It verifies each server with an MCP `initialize` handshake and can expose it through an existing Gateway API Gateway (`httproute` provider) or a Kuadrant MCP gateway (`kuadrant` provider). The opendatahub-operator deploys it through the DSC `mcplifecycleoperator` component.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./mcp-lifecycle-operator-component.mmd) - Manager, controllers, gateway providers, CRD watcher, webhooks, managed/BYO resources
- [Data Flows](./mcp-lifecycle-operator-dataflow.mmd) - Sequence diagram: managed deployment + handshake verification, httproute gateway exposure, metrics scrape
- [Dependencies](./mcp-lifecycle-operator-dependencies.mmd) - Go libraries, cluster add-ons, optional gateway providers, platform integrations

### For Architects
- [C4 Context](./mcp-lifecycle-operator-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./mcp-lifecycle-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./mcp-lifecycle-operator-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./mcp-lifecycle-operator-security-network.txt) - Precise text format for SAR submissions (RBAC, admission, secrets, TLS, risks)
- [RBAC Visualization](./mcp-lifecycle-operator-rbac.mmd) - ServiceAccount, bindings, ClusterRole permissions, aggregated user roles

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks; they render automatically.
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
- Suited to security reviews because every technical detail is spelled out

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/mcp-lifecycle-operator.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
