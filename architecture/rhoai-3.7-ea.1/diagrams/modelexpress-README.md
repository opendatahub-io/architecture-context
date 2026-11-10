# Architecture Diagrams for ModelExpress

Generated from: `architecture/rhoai-3.7-ea.1/modelexpress.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: RHOAI 3.7.0-ea.1 ships two images, `odh-modelexpress-operator-rhel9` (Rust/kube-rs operator) and `odh-modelexpress-rhel9` (gRPC coordinator). The operator turns each namespaced `ModelExpressServer` CR into a coordinator instance in that namespace. The Python client, the Go stubs and the Helm chart are not shipped as RHOAI images.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./modelexpress-component.mmd) - Operator, per-CR generated resources, server internals (AuthLayer, gRPC services, metadata backend, cache, reaper), and the CRDs
- [Data Flows](./modelexpress-dataflow.mmd) - Sequence diagram: CR reconciliation, P2P source discovery (enforce mode), server-coordinated download and cache, metrics scraping
- [Dependencies](./modelexpress-dependencies.mmd) - Platform integrations, optional Redis, model sources, key Rust libraries (FIPS OpenSSL vs. excluded rustls/ring)

### For Architects
- [C4 Context](./modelexpress-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./modelexpress-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./modelexpress-security-network.mmd) - Trust zones, ports, TLS, auth, and the open-by-default NetworkPolicy
- [Security Network Diagram (ASCII)](./modelexpress-security-network.txt) - Precise text format for SAR submissions, with RBAC, auth, TLS, secrets and key risks
- [RBAC Visualization](./modelexpress-rbac.mmd) - Operator ClusterRoles, per-CR server Role, auth-delegator binding, escalation surface

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks and they render automatically.
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
- Use for security reviews, where the exact technical details matter

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/modelexpress.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
