# Architecture Diagrams for vLLM Gaudi

Generated from: `architecture/rhoai.next/vllm-gaudi.md`
Date: 2026-05-13

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./vllm-gaudi-component.mmd) - Internal components (plugin core, attention backends, custom ops, model overrides, worker runtime)
- [Data Flows](./vllm-gaudi-dataflow.mmd) - Sequence diagram of inference request, model loading, tensor parallelism, and KV cache disaggregation flows
- [Dependencies](./vllm-gaudi-dependencies.mmd) - Component dependency graph (SynapseAI, PyTorch, vLLM, KServe, Ray, NIXL)

### For Architects
- [C4 Context](./vllm-gaudi-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./vllm-gaudi-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./vllm-gaudi-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./vllm-gaudi-security-network.txt) - Precise text format for SAR submissions (includes RBAC, secrets, FIPS status)
- [RBAC Visualization](./vllm-gaudi-rbac.mmd) - RBAC permissions, auth enforcement, and secrets

## Key Security Notes

- **FIPS**: OpenSSL FIPS provider is explicitly **removed** in the container image — non-FIPS crypto in use
- **Intra-cluster**: HCCL, NIXL, and Ray communication is plaintext with no authentication
- **Auth**: All external API auth is delegated to kube-rbac-proxy sidecar (not in-app)
- **Secrets**: Model storage credentials and HuggingFace tokens are user-provisioned, no auto-rotation

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
/generate-architecture-diagrams --architecture=../vllm-gaudi.md
```
