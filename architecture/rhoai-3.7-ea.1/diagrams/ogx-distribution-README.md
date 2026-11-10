# Architecture Diagrams for ogx-distribution

Generated from: `architecture/rhoai-3.7-ea.1/ogx-distribution.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: `ogx-distribution` is a packaging repo. It builds the RHOAI OGX (formerly Llama Stack) server image `quay.io/rhoai/odh-ogx-core-rhel9` (OGX `1.4.1+rhaiv.0`) and its default config. The server listens on 8321/TCP over plain HTTP (`--insecure`), keeps all state in PostgreSQL, and is unauthenticated unless `AUTH_ISSUER` is set. Remote providers are turned on by environment variables. The repo defines no Service, Route, RBAC or NetworkPolicy; the OGX operator creates those. The diagrams draw operator- or platform-defined elements as dashed or labelled "not in this repo".

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./ogx-distribution-component.mmd) - Build tooling, image contents (entrypoint, config, server), always-on and env-gated providers
- [Data Flows](./ogx-distribution-dataflow.mmd) - Sequence diagram: chat/responses request with optional JWT, RAG file ingestion and file search
- [Dependencies](./ogx-distribution-dependencies.mmd) - Packaged OGX, required PostgreSQL and inference, optional providers, build-time inputs, consumers

### For Architects
- [C4 Context](./ogx-distribution-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./ogx-distribution-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./ogx-distribution-security-network.mmd) - Trust zones, plaintext 8321, unauthenticated metrics, egress with ports, TLS and auth
- [Security Network Diagram (ASCII)](./ogx-distribution-security-network.txt) - Precise text format for SAR submissions, with secrets, ABAC policy, build-time network and risks
- [RBAC Visualization](./ogx-distribution-rbac.mmd) - No Kubernetes RBAC; in-process OAuth2 JWT and owner-based ABAC rules; build identity

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks; they render automatically.
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
- Suited to security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/ogx-distribution.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
