# Architecture Diagrams for kube-auth-proxy

Generated from: `architecture/rhoai.next/kube-auth-proxy.md`
Date: 2026-06-30

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./kube-auth-proxy-component.mmd) - Internal middleware chain, auth endpoints, reverse proxy
- [Data Flows](./kube-auth-proxy-dataflow.mmd) - OAuth2 login, bearer token validation, K8s SA token, sign-out flows
- [Dependencies](./kube-auth-proxy-dependencies.mmd) - Identity providers, APIs, Go libraries, session stores

### For Architects
- [C4 Context](./kube-auth-proxy-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kube-auth-proxy-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./kube-auth-proxy-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./kube-auth-proxy-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kube-auth-proxy-rbac.mmd) - RBAC permissions, auth mechanisms, secrets

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
/generate-architecture-diagrams --architecture=../kube-auth-proxy.md
```
