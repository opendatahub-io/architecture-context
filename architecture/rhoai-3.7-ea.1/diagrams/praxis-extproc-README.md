# Architecture Diagrams for praxis-extproc

Generated from: `architecture/rhoai-3.7-ea.1/praxis-extproc.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: A Rust Envoy External Processing (ExtProc) gRPC server that runs Praxis filter pipelines for the MaaS AI gateway. It replaces the Go Inference Payload Processor. One image is deployed twice in `openshift-ingress`. `payload-pre-processing` runs before Kuadrant auth and derives `X-Gateway-Model-Name` from the request body. `payload-processing` runs after Kuadrant and strips credentials and `x-maas-*` headers. Both are wired into `maas-default-gateway` by an Istio EnvoyFilter over TLS (service-CA), and both fail closed.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./praxis-extproc-component.mmd) - Rust modules, Praxis filter crates, the two Kubernetes instances, EnvoyFilter wiring
- [Data Flows](./praxis-extproc-dataflow.mmd) - Sequence diagram: inference request through the pre-auth and post-auth chains, metrics scrape, startup and readiness
- [Dependencies](./praxis-extproc-dependencies.mmd) - Rust crates, system OpenSSL, platform integrations

### For Architects
- [C4 Context](./praxis-extproc-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./praxis-extproc-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./praxis-extproc-security-network.mmd) - Trust zones, ports, TLS and auth for each hop
- [Security Network Diagram (ASCII)](./praxis-extproc-security-network.txt) - Precise text format for SAR submissions, including RBAC, EnvoyFilter, NetworkPolicy, secrets, FIPS and key risks
- [RBAC Visualization](./praxis-extproc-rbac.mmd) - Metrics-auth and metrics-reader ClusterRoles and bindings

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown inside a ```` ```mermaid ```` code block and it renders automatically
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
- Suited to security reviews because the technical details are exact

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/praxis-extproc.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
