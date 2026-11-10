# Architecture Diagrams for Kueue Operator

Generated from: `architecture/rhoai-3.7-ea.1/kueue-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./kueue-operator-component.mmd) - Operator, Kueue CR, rendered operand resources, operand controller-manager
- [Data Flows](./kueue-operator-dataflow.mmd) - Sequence diagram: operator reconciliation, workload admission, metrics scrape
- [Dependencies](./kueue-operator-dependencies.mmd) - cert-manager hard gate, Prometheus Operator, job frameworks gated by Kueue

### For Architects
- [C4 Context](./kueue-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kueue-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./kueue-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kueue-operator-security-network.txt) - Precise text format for SAR submissions (NetworkPolicies, RBAC, secrets, admission risks)
- [RBAC Visualization](./kueue-operator-rbac.mmd) - Operator and operand service accounts, bindings, and permissions

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
- Suitable for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/kueue-operator.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
