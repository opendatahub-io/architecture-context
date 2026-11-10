# Architecture Diagrams for MCP Lifecycle Module Operator

Generated from: `architecture/rhoai-3.7-ea.1/mcp-lifecycle-module-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: The module operator deploys and manages the MCP Lifecycle Operator (operand), which owns the `MCPServer` and `MCPGatewayBinding` APIs. Operand internals such as webhook handlers and MCPServer reconciliation are out of scope. The diagrams show only the resources the module creates.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./mcp-lifecycle-module-operator-component.mmd) - Reconciler, KustomizeProvider, TLS subsystem, gateway discovery, storage migration, operand resources
- [Data Flows](./mcp-lifecycle-module-operator-dataflow.mmd) - Sequence diagram: platform enablement with conversion gate, metrics scrape, TLS profile change
- [Dependencies](./mcp-lifecycle-module-operator-dependencies.mmd) - Platform integrations, Go libraries, required and optional cluster add-ons

### For Architects
- [C4 Context](./mcp-lifecycle-module-operator-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./mcp-lifecycle-module-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./mcp-lifecycle-module-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./mcp-lifecycle-module-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./mcp-lifecycle-module-operator-rbac.mmd) - Module and operand RBAC, including the module's privilege-superset ClusterRole

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks to render automatically
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
- Include in security reviews as-is

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/mcp-lifecycle-module-operator.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
