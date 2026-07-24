# Architecture Diagrams for codeflare-sdk

Generated from: `architecture/rhoai.next/codeflare-sdk.md`
Date: 2026-06-22

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./codeflare-sdk-component.mmd) - Internal SDK modules (Cluster, RayJobClient, AWManager, Auth, Kueue, Widgets, CertGen)
- [Data Flows](./codeflare-sdk-dataflow.mmd) - Sequence diagrams: cluster creation, job submission, TLS cert generation, teardown
- [Dependencies](./codeflare-sdk-dependencies.mmd) - Python library deps, platform operator deps, runtime service deps

### For Architects
- [C4 Context](./codeflare-sdk-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./codeflare-sdk-component.mmd) - High-level view of SDK modules and their K8s interactions

### For Security Teams
- [Security Network Diagram (Mermaid)](./codeflare-sdk-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./codeflare-sdk-security-network.txt) - Precise text format for SAR submissions with RBAC summary, auth details, crypto risks
- [RBAC Visualization](./codeflare-sdk-rbac.mmd) - User-provided RBAC roles required for SDK operation

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ` ```mermaid ` code blocks - renders automatically!
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
/generate-architecture-diagrams --architecture=architecture/rhoai.next/codeflare-sdk.md
```
