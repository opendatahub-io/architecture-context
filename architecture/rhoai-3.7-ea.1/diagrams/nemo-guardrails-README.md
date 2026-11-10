# Architecture Diagrams for NeMo-Guardrails

Generated from: `architecture/rhoai-3.7-ea.1/NeMo-Guardrails.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./nemo-guardrails-component.mmd) - Server, checks router, LLMRails engine, guardrails library, header forwarding, baked-in models, build-time filters
- [Data Flows](./nemo-guardrails-dataflow.mmd) - Sequence diagram: guarded chat completion, guardrail-only check, model listing, OTLP telemetry
- [Dependencies](./nemo-guardrails-dependencies.mmd) - Runtime libraries, TrustyAI operator, KServe/vLLM, AIPCC base and modelcars, optional SaaS

### For Architects
- [C4 Context](./nemo-guardrails-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./nemo-guardrails-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./nemo-guardrails-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./nemo-guardrails-security-network.txt) - Precise text format for SAR submissions (no in-app auth/TLS, credential forwarding, executable config, FIPS notes)
- [RBAC Visualization](./nemo-guardrails-rbac.mmd) - No Kubernetes RBAC; effective app-level access and outbound credential precedence

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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/NeMo-Guardrails.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
