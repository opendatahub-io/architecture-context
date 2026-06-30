# Architecture Diagrams for ai4rag

Generated from: `architecture/rhoai.next/ai4rag.md`
Date: 2026-06-30

**Note**: ai4rag is a Python library (not a Kubernetes operator/service). Diagrams reflect its library architecture with a single egress point to OGX Server. Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./ai4rag-component.mmd) - Internal components: orchestrator, optimizers, RAG pipeline, provider adapters, event handlers
- [Data Flows](./ai4rag-dataflow.mmd) - Sequence diagram of the 3-phase RAG optimization: model pre-selection → HPO → results
- [Dependencies](./ai4rag-dependencies.mmd) - External Python packages and internal platform dependencies

### For Architects
- [C4 Context](./ai4rag-c4-context.dsl) - System context in C4 format (Structurizr) showing ai4rag in the RHOAI ecosystem
- [Component Overview](./ai4rag-component.mmd) - High-level component view with all internal classes and OGX integration

### For Security Teams
- [Security Network Diagram (Mermaid)](./ai4rag-security-network.mmd) - Visual network topology showing trust boundaries and egress
- [Security Network Diagram (ASCII)](./ai4rag-security-network.txt) - Precise text format for SAR submissions with port/protocol/auth details
- [RBAC Visualization](./ai4rag-rbac.mmd) - Secrets and authentication flow (no K8s RBAC — library delegates to consumer)

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
/generate-architecture-diagrams --architecture=../ai4rag.md
```
