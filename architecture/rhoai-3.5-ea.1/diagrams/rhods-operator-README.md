# Architecture Diagrams for rhods-operator

Generated from: `../rhods-operator.md`
Date: 2026-05-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./rhods-operator-component.mmd) - Internal components (manager, cloudmanager, 16 component controllers, 14 webhooks)
- [Data Flows](./rhods-operator-dataflow.mmd) - Sequence diagrams: platform init, component deployment, gateway auth, legacy redirects
- [Dependencies](./rhods-operator-dependencies.mmd) - Full dependency graph (infrastructure, platform services, 16 managed components, external services)

### For Architects
- [C4 Context](./rhods-operator-c4-context.dsl) - System context in C4 format (Structurizr) — operator in the RHOAI ecosystem
- [Component Overview](./rhods-operator-component.mmd) - High-level component view with controller hierarchy

### For Security Teams
- [Security Network Diagram (Mermaid)](./rhods-operator-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./rhods-operator-security-network.txt) - Precise text format for SAR submissions (includes RBAC, secrets, auth, FIPS details)
- [RBAC Visualization](./rhods-operator-rbac.mmd) - RBAC permissions: SA → ClusterRoleBinding → ClusterRole → Resources

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
/generate-architecture-diagrams --architecture=../rhods-operator.md
```
