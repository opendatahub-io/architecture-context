# Architecture Diagrams for vllm-gaudi

Generated from: `architecture/rhoai.next/vllm-gaudi.md`
Date: 2026-10-07

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./vllm-gaudi-component.mmd) - Internal components (plugin registration, platform, worker, custom ops, model overrides)
- [Data Flows](./vllm-gaudi-dataflow.mmd) - Sequence diagram of inference, model loading, and distributed flows
- [Dependencies](./vllm-gaudi-dependencies.mmd) - Component dependency graph (vLLM, SynapseAI, KServe, storage)

### For Architects
- [C4 Context](./vllm-gaudi-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./vllm-gaudi-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./vllm-gaudi-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./vllm-gaudi-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./vllm-gaudi-rbac.mmd) - RBAC permissions and bindings

## Key Security Notes

- ⚠️ **FIPS Disabled**: `openssl-fips-provider-so` explicitly removed from UBI 9 base image
- ⚠️ **Supply Chain Gap**: Python packages installed from upstream PyPI and Habana private index, not Red Hat pipelines
- ✅ **Non-root**: Container runs as UID 2000 / GID 0
- ✅ **Auth Delegated**: All authentication/authorization handled by KServe/Istio platform layer

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
/generate-architecture-diagrams --architecture=../vllm-gaudi.md
```
