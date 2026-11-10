# Architecture Diagrams for praxis-grid (AI Grid Network)

Generated from: `architecture/rhoai-3.7-ea.1/praxis-grid.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: AGN is a Technical Preview control plane. `grid-operator` federates inference providers across sites using SWIM gossip (7946/UDP) and mTLS signals (9091/TCP), and publishes routing overlays that `grid-overlay-sync` delivers to Praxis AI gateways. The operator is not in the request path. Enrollment, fleet-dashboard and grid-gateway are optional.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./praxis-grid-component.mmd) - grid-operator internals (reconcilers, SWIM, CRDT, scoring), the 5 CRDs, overlay/serving ConfigMaps, overlay-sync sidecar, hub services
- [Data Flows](./praxis-grid-dataflow.mmd) - Sequence diagram: site enrollment, overlay publication, cross-site membership and signals, data-plane inference
- [Dependencies](./praxis-grid-dependencies.mmd) - Library, platform and federation dependencies

### For Architects
- [C4 Context](./praxis-grid-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./praxis-grid-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./praxis-grid-security-network.mmd) - Trust zones, LoadBalancer exposure of SWIM and signals, mTLS and mesh-key boundaries
- [Security Network Diagram (ASCII)](./praxis-grid-security-network.txt) - Precise text format for SAR submissions: ports, TLS, auth, RBAC, admission policies, secrets, FIPS, key observations
- [RBAC Visualization](./praxis-grid-rbac.mmd) - grid-operator and metrics-scraper bindings, scoped verbs, and VAP fences

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks. They render automatically.
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
- Suited to security reviews because the technical details are exact

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/praxis-grid.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
