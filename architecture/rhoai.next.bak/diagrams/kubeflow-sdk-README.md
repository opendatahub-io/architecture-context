# Architecture Diagrams for Kubeflow SDK

Generated from: `../kubeflow-sdk.md`
Date: 2026-06-22

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./kubeflow-sdk-component.mmd) - Internal SDK modules, backends, and CRD interactions
- [Data Flows](./kubeflow-sdk-dataflow.mmd) - Sequence diagram of training job creation, progression tracking, and checkpoint flows
- [Dependencies](./kubeflow-sdk-dependencies.mmd) - Platform and Python library dependency graph

### For Architects
- [C4 Context](./kubeflow-sdk-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./kubeflow-sdk-component.mmd) - High-level SDK component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./kubeflow-sdk-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./kubeflow-sdk-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kubeflow-sdk-rbac.mmd) - RBAC permissions and bindings required by SDK users

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
/generate-architecture-diagrams --architecture=../kubeflow-sdk.md
```
