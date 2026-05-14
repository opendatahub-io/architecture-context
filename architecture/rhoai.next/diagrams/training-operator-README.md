# Architecture Diagrams for Training Operator

Generated from: `architecture/rhoai.next/training-operator.md`
Date: 2026-05-13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./training-operator-component.mmd) - Internal components (6 framework controllers, shared JobController base, webhook server)
- [Data Flows](./training-operator-dataflow.mmd) - Sequence diagrams of PyTorch job lifecycle and MPI communication pattern
- [Dependencies](./training-operator-dependencies.mmd) - Component dependency graph (Kubernetes, Volcano, scheduler-plugins, cert-controller, Kueue)

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions (includes RBAC summary, secrets, FIPS compliance)
- [RBAC Visualization](./training-operator-rbac.mmd) - RBAC permissions and bindings (ClusterRoles, aggregate roles, per-MPI-job roles)

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
/generate-architecture-diagrams --architecture=../training-operator.md
```
