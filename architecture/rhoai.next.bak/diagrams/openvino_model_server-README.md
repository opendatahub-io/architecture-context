# Architecture Diagrams for OpenVINO Model Server (OVMS)

Generated from: `../openvino_model_server.md`
Date: 2026-06-30

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./openvino_model_server-component.mmd) - Internal components (core server, inference pipelines, MediaPipe calculators, storage layer)
- [Data Flows](./openvino_model_server-dataflow.mmd) - Sequence diagrams: REST inference, LLM streaming, cloud model loading, HuggingFace pull
- [Dependencies](./openvino_model_server-dependencies.mmd) - Component dependency graph (OpenVINO, bundled libs, cloud services, platform)

### For Architects
- [C4 Context](./openvino_model_server-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./openvino_model_server-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./openvino_model_server-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./openvino_model_server-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./openvino_model_server-rbac.mmd) - Auth mechanisms: kube-rbac-proxy sidecar, Bearer token, endpoint protection

## Key Security Notes

- **No built-in TLS**: OVMS uses plaintext HTTP/gRPC — TLS is provided by kube-rbac-proxy sidecar
- **gRPC**: Uses `InsecureServerCredentials()` by design
- **Auth**: Optional Bearer token only on `/v3/*` generative endpoints; `/v1/*`, `/v2/*` rely on sidecar auth
- **No Kubernetes RBAC**: OVMS is a standalone server binary, RBAC managed by KServe ServingRuntime

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
/generate-architecture-diagrams --architecture=../openvino_model_server.md
```
