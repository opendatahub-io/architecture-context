# Architecture Diagrams for Praxis Policy Engine (PPE)

Generated from: `architecture/rhoai.next/praxis-policy.md`
Date: 2026-10-07

**Note**: PPE is an embeddable Rust library (not a Kubernetes service), so diagrams emphasize the internal crate structure, plugin pipeline, and egress connections rather than ingress/service topology. Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./praxis-policy-component.mmd) - 11-crate workspace: facade, core runtime, APL layer, builtin extensions, test/bench
- [Data Flows](./praxis-policy-dataflow.mmd) - Sequence diagram: JWT identity resolution, OAuth token delegation, session taint propagation
- [Dependencies](./praxis-policy-dependencies.mmd) - Cargo dependency graph: runtime, TLS stack, PDP engines, session/cache, crypto

### For Architects
- [C4 Context](./praxis-policy-c4-context.dsl) - System context: PPE embedded in Praxis Proxy, external IdP/Valkey/Vault
- [Component Overview](./praxis-policy-component.mmd) - High-level crate and plugin architecture

### For Security Teams
- [Security Network Diagram (Mermaid)](./praxis-policy-security-network.mmd) - Visual: trust boundaries, egress flows, SSRF protection, crypto stack
- [Security Network Diagram (ASCII)](./praxis-policy-security-network.txt) - Precise text: ports, protocols, TLS, auth, secrets, supply chain controls
- [RBAC / Authorization Visualization](./praxis-policy-rbac.mmd) - Internal policy enforcement: identity → PDP → effects (no K8s RBAC)

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
/generate-architecture-diagrams --architecture=architecture/rhoai.next/praxis-policy.md
```
