# Architecture Diagrams for llm-d-routing-sidecar

Generated from: `architecture/rhoai-3.7-ea.1/llm-d-routing-sidecar.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Note**: The upstream repository is deprecated. The sidecar code moved to `llm-d-inference-scheduler` (`cmd/pd_sidecar`). RHOAI injects the sidecar into decode pods through KServe `LLMInferenceService`.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./llm-d-routing-sidecar-component.mmd) - Proxy server, P/D connectors, LRU cache, SSRF allowlist, decode pod topology
- [Data Flows](./llm-d-routing-sidecar-dataflow.mmd) - Sequence diagram: NIXL v2 P/D completion, non-P/D pass-through, SSRF allowlist watches
- [Dependencies](./llm-d-routing-sidecar-dependencies.mmd) - vLLM peers, EPP header contract, InferencePool, KServe injection, Go libraries

### For Architects
- [C4 Context](./llm-d-routing-sidecar-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./llm-d-routing-sidecar-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./llm-d-routing-sidecar-security-network.mmd) - Trust zones, ports, TLS, Gateway-bypass path
- [Security Network Diagram (ASCII)](./llm-d-routing-sidecar-security-network.txt) - Precise text format for SAR submissions, including SSRF, TLS and FIPS risks
- [RBAC Visualization](./llm-d-routing-sidecar-rbac.mmd) - SSRF allowlist Role and scaffold exec Role

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks; it renders automatically.
- **Live editor**: https://mermaid.live (paste code, edit, export)

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
- Suited to security reviews (precise technical details)

## Updating Diagrams

```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/llm-d-routing-sidecar.md
```
