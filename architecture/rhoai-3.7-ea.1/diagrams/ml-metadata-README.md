# Architecture Diagrams for ML Metadata (ml-metadata)

Generated from: `architecture/rhoai-3.7-ea.1/ml-metadata.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: Konflux ships only the `metadata_store_server` binary, as `quay.io/rhoai/odh-mlmd-grpc-server-rhel9`. The repo has no Kubernetes manifests. Deployment by the Data Science Pipelines Operator and the DSP client integrations are inferred and labeled that way. The Python client and Go bindings appear as dashed "not shipped" elements.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./ml-metadata-component.mmd) - gRPC server, MetadataStore, RDBMS sources (including the silent in-memory fallback), DSP integrations
- [Data Flows](./ml-metadata-dataflow.mmd) - Sequence diagram: startup/schema migration, lineage recording and querying
- [Dependencies](./ml-metadata-dependencies.mmd) - Runtime DBs, statically linked build deps (BoringSSL, gRPC, libpq), platform integrations

### For Architects
- [C4 Context](./ml-metadata-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./ml-metadata-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./ml-metadata-security-network.mmd) - Plaintext and unauthenticated gRPC 8080, DB egress
- [Security Network Diagram (ASCII)](./ml-metadata-security-network.txt) - Precise text format for SAR submissions: ports, TLS, BoringSSL/FIPS, secrets
- [RBAC Visualization](./ml-metadata-rbac.mmd) - No Kubernetes RBAC; application access model and credentials

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks - renders automatically!
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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/ml-metadata.md
```
