# Architecture Diagrams for OpenShell

Generated from: `architecture/rhoai-3.7-ea.1/openshell.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./openshell-component.mmd) - Gateway, supervisor, sandbox tiers and drivers
- [Data Flows](./openshell-dataflow.mmd) - Sandbox creation, supervisor bootstrap, agent egress, interactive exec/SSH
- [Dependencies](./openshell-dependencies.mmd) - Component dependency graph

### For Architects
- [C4 Context](./openshell-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./openshell-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./openshell-security-network.mmd) - Trust tiers: control plane, policy enforcer, untrusted workload
- [Security Network Diagram (ASCII)](./openshell-security-network.txt) - Precise text format for SAR submissions (ports, TLS, auth, RBAC, secrets, FIPS)
- [RBAC Visualization](./openshell-rbac.mmd) - Gateway SA ClusterRole/Role permissions by workspaceMode

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
- View in any text editor; include in security reviews as-is

## Updating Diagrams

```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/openshell.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
