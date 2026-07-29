# Architecture Diagrams for rhds-llama-stack-distribution

Generated from: `architecture/rhoai.next/rhds-llama-stack-distribution.md`
Date: 2026-07-27

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./rhds-llama-stack-distribution-component.mmd) - Internal components, API surfaces, provider framework, and storage backends
- [Data Flows](./rhds-llama-stack-distribution-dataflow.mmd) - Sequence diagram of inference, safety, storage, evaluation, and telemetry flows
- [Dependencies](./rhds-llama-stack-distribution-dependencies.mmd) - Full dependency graph including inference providers, vector stores, safety/eval, and platform

### For Architects
- [C4 Context](./rhds-llama-stack-distribution-c4-context.dsl) - System context in C4 format (Structurizr) showing Llama Stack in the broader RHOAI ecosystem
- [Component Overview](./rhds-llama-stack-distribution-component.mmd) - High-level component view with 10 API surfaces and pluggable providers

### For Security Teams
- [Security Network Diagram (Mermaid)](./rhds-llama-stack-distribution-security-network.mmd) - Visual network topology with trust zones and credential flows
- [Security Network Diagram (ASCII)](./rhds-llama-stack-distribution-security-network.txt) - Precise text format for SAR submissions with port/protocol/auth details
- [RBAC Visualization](./rhds-llama-stack-distribution-rbac.mmd) - Security model showing platform-delegated auth and env-var credential management

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
/generate-architecture-diagrams --architecture=architecture/rhoai.next/rhds-llama-stack-distribution.md
```
