# Architecture Diagrams for Trainer (Kubeflow Trainer V2)

Generated from: `architecture/rhoai-3.5-ea.1/trainer.md`
Date: 2026-05-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./trainer-component.mmd) - Internal components: controller, plugin framework (Torch, MPI, TorchTune, Coscheduling, Volcano), RHAI extensions, webhook server
- [Data Flows](./trainer-dataflow.mmd) - Sequence diagrams: TrainJob reconciliation, RHAI progression tracking, MPI training setup
- [Dependencies](./trainer-dependencies.mmd) - Component dependency graph showing JobSet, scheduler-plugins, Volcano, Kueue integrations

### For Architects
- [C4 Context](./trainer-c4-context.dsl) - System context in C4 format (Structurizr DSL)
- [Component Overview](./trainer-component.mmd) - High-level component view with plugin framework

### For Security Teams
- [Security Network Diagram (Mermaid)](./trainer-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./trainer-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, FIPS details
- [RBAC Visualization](./trainer-rbac.mmd) - RBAC permissions and bindings including controller, edit, admin, and view roles

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
/generate-architecture-diagrams --architecture=../trainer.md
```
