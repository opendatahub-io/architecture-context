# Architecture Diagrams for rhoai-mcp

Generated from: `architecture/rhoai-3.7-ea.1/rhoai-mcp.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./rhoai-mcp-component.mmd) - Server, plugin manager, domain/composite plugins, auth subsystem, embedded Planner
- [Data Flows](./rhoai-mcp-dataflow.mmd) - OIDC tool call, SA-mode tool call, Planner benchmark sync, Model Registry query
- [Dependencies](./rhoai-mcp-dependencies.mmd) - Library and platform dependency graph

### For Architects
- [C4 Context](./rhoai-mcp-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./rhoai-mcp-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./rhoai-mcp-security-network.mmd) - Trust zones, ports, TLS, auth per hop
- [Security Network Diagram (ASCII)](./rhoai-mcp-security-network.txt) - Precise text format for SAR submissions (both SA and OIDC postures)
- [RBAC Visualization](./rhoai-mcp-rbac.mmd) - SA-mode vs OIDC-mode ClusterRole permissions

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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/rhoai-mcp.md
```
