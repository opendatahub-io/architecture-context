# Architecture Diagrams for openvino_model_server

Generated from: `architecture/rhoai-3.7-ea.1/openvino_model_server.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: OpenVINO Model Server (OVMS 2026.4.0) is a C++ inference server shipped as the `odh-openvino-model-server-rhel9` runtime image. KServe deploys it through the `kserve-ovms` ServingRuntime template from ODH Model Controller. It serves KServe v2, TFS v1 and OpenAI-compatible `/v3` APIs over plain HTTP (8888) and insecure gRPC (8001). It defines no CRDs and no RBAC. TLS and authentication come from the platform; the only built-in auth is an optional static API key on `/v3`.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./openvino_model_server-component.mmd) - REST/gRPC frontends, model manager, GenAI pipelines, cloud filesystems, pull module, pyovms, KServe deployment path
- [Data Flows](./openvino_model_server-dataflow.mmd) - Sequence diagram: model loading, KServe v2 REST inference, OpenAI generation (SSE), in-cluster gRPC, metrics scrape
- [Dependencies](./openvino_model_server-dependencies.mmd) - RPM and Python dependencies, platform integrations, external services

### For Architects
- [C4 Context](./openvino_model_server-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./openvino_model_server-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./openvino_model_server-security-network.mmd) - Trust zones, ports, plaintext in-pod listeners, egress
- [Security Network Diagram (ASCII)](./openvino_model_server-security-network.txt) - Precise text format for SAR submissions, including secrets, FIPS risks, hermeticity and key findings
- [RBAC Visualization](./openvino_model_server-rbac.mmd) - No Kubernetes RBAC; which application endpoints are open and which use the optional API key

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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/openvino_model_server.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
