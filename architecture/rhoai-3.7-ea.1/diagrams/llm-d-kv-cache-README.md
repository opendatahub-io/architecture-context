# Architecture Diagrams for llm-d-kv-cache

Generated from: `architecture/rhoai-3.7-ea.1/llm-d-kv-cache.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: This repo is a library plus a sidecar plus a utility. It is not an operator and defines no CRDs. RHOAI ships three things from it: the Go KV-cache indexer library (linked into the llm-d EPP scheduler), the UDS tokenizer sidecar (`odh-llm-d-kv-cache-rhel9`), and the Go PVC evictor (`odh-llm-d-kv-pvc-evictor-rhel9`). The demo `kv-cache-manager`, the example Pod reconciler, the Python evictor and `llmd_fs_backend` appear as dashed "not shipped" elements.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./llm-d-kv-cache-component.mmd) - Go library packages, UDS tokenizer, PVC evictor, and how they connect to the EPP scheduler, KServe and vLLM
- [Data Flows](./llm-d-kv-cache-dataflow.mmd) - Sequence diagram: KV event ingestion, precise prefix-cache scoring, PVC eviction
- [Dependencies](./llm-d-kv-cache-dependencies.mmd) - Internal RHOAI integrations, external services, Go and Python libraries

### For Architects
- [C4 Context](./llm-d-kv-cache-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./llm-d-kv-cache-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./llm-d-kv-cache-security-network.mmd) - Pod-local UDS trust boundary, plaintext ZMQ/OTLP/Redis channels, HF egress
- [Security Network Diagram (ASCII)](./llm-d-kv-cache-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./llm-d-kv-cache-rbac.mmd) - No Roles or bindings; evictor SA without a token; filesystem-based controls

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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/llm-d-kv-cache.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
