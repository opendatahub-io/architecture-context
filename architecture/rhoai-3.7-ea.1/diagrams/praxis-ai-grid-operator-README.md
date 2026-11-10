# Architecture Diagrams for praxis-ai-grid-operator (AI Grid Network)

Generated from: `architecture/rhoai-3.7-ea.1/praxis-ai-grid-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: The AI Grid Network (AGN) is a technical-preview, multi-site inference routing control plane. Each site runs one `grid-operator`. It watches five cluster-scoped `grid.praxis.fast/v1alpha1` CRDs, gossips provider state with peer sites over encrypted SWIM (7946/UDP), scores candidates, and publishes content-addressed routing overlay ConfigMaps. Praxis AI gateways consume those overlays through the `overlay-sync` sidecar or the `grid-gateway` operand. The operator stays out of the request path. It also serves a signals exporter (9091/TCP, mTLS with pins). The optional `grid-enrollment` service (8443/TCP) acts as the Grid CA signer for site identities. The diagrams also call out the main risks: the shipped Konflux images are built without the `fips` feature, and SWIM origin pinning is not fully wired yet.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./praxis-ai-grid-operator-component.mmd) - Operator internals (reconcilers, SWIM, CRDT, scoring, overlay publisher, signals, trust), enrollment, data-plane consumers, CRDs
- [Data Flows](./praxis-ai-grid-operator-dataflow.mmd) - Sequence diagram: overlay publication, signals exchange, cross-site inference, site enrollment
- [Dependencies](./praxis-ai-grid-operator-dependencies.mmd) - Rust/Go libraries, platform integrations, external services

### For Architects
- [C4 Context](./praxis-ai-grid-operator-c4-context.dsl) - System context, containers and operator components in C4 format (Structurizr)
- [Component Overview](./praxis-ai-grid-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./praxis-ai-grid-operator-security-network.mmd) - Trust zones, internal LBs, ports, TLS/mTLS and auth per hop
- [Security Network Diagram (ASCII)](./praxis-ai-grid-operator-security-network.txt) - Precise text format for SAR submissions, including RBAC, VAPs, secrets and key risks
- [RBAC Visualization](./praxis-ai-grid-operator-rbac.mmd) - Operator and metrics-scraper ServiceAccount permissions plus ValidatingAdmissionPolicy guardrails

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks
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

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/praxis-ai-grid-operator.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
