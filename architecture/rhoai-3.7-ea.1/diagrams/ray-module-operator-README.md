# Architecture Diagrams for Ray Module Operator

Generated from: `architecture/rhoai-3.7-ea.1/ray-module-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: The module operator reconciles the cluster-scoped `Ray/default-ray` module CR and installs, upgrades, and removes the KubeRay operator (operand). The diagrams show the resources the module renders and SSA-applies from its vendored manifests. KubeRay runtime internals are out of scope; see the `kuberay-*` diagrams for those. Examples are webhook handler semantics, Ray dashboard HTTPRoutes, and RayCluster mTLS.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./ray-module-operator-component.mmd) - Manager, reconciler action pipeline, TLS profile watcher, vendored manifests, operand resources
- [Data Flows](./ray-module-operator-dataflow.mmd) - Sequence diagram: enablement and operand deployment, removal/deletion, metrics scrape, TLS profile change
- [Dependencies](./ray-module-operator-dependencies.mmd) - Platform integrations, cluster add-ons (cert-manager hard prerequisite), Go libraries

### For Architects
- [C4 Context](./ray-module-operator-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./ray-module-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./ray-module-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./ray-module-operator-security-network.txt) - Precise text format for SAR submissions, including RBAC, secrets, admission control and risks
- [RBAC Visualization](./ray-module-operator-rbac.mmd) - Module ClusterRole (privilege superset of KubeRay), notebook `ray` ClusterRole, operand roles

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks to render automatically
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
- Include in security reviews as-is

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/ray-module-operator.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
