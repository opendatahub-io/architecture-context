# Architecture Diagrams for vllm-cpu

Generated from: `architecture/rhoai-3.7-ea.1/vllm-cpu.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: vllm-cpu is the RHOAI fork of vLLM (0.24.0) that builds the `odh-vllm-cpu-rhel9` image for ppc64le and s390x. It serves the OpenAI-compatible API over plain HTTP on 8000/TCP (TLS optional). Bearer auth is opt-in and covers only `/v1`, `/v2` and `/inference`. It defines no CRDs, RBAC or Kubernetes manifests; KServe and odh-model-controller ServingRuntime templates deploy it. The build is non-hermetic and not AIPCC-based, and the IBM DevPI index with `unsafe-best-match` remains set in the runtime image.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./vllm-cpu-component.mmd) - API server, auth/CORS middleware, engine core, CPU kernels, tensorizer, inactive gRPC/DP supervisor, per-arch build layer
- [Data Flows](./vllm-cpu-dataflow.mmd) - Sequence diagram: model load, inference via KServe, unguarded root routes, metrics scrape
- [Dependencies](./vllm-cpu-dependencies.mmd) - Python/native dependencies, platform integrations, runtime and build-time external services

### For Architects
- [C4 Context](./vllm-cpu-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./vllm-cpu-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./vllm-cpu-security-network.mmd) - Trust zones, plaintext 8000 listener, runtime egress, non-hermetic build egress
- [Security Network Diagram (ASCII)](./vllm-cpu-security-network.txt) - Precise text format for SAR submissions, including endpoint auth matrix, secrets, FIPS, hermeticity and key risks
- [RBAC Visualization](./vllm-cpu-rbac.mmd) - No Kubernetes RBAC; which application endpoints use the opt-in API key and which are always open

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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/vllm-cpu.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
