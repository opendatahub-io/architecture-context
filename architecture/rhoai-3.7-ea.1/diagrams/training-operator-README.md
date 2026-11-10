# Architecture Diagrams for Training Operator

Generated from: `architecture/rhoai-3.7-ea.1/training-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./training-operator-component.mmd) - Manager, six job reconcilers, Common JobController, webhook server, cert rotator, and resources created in user namespaces
- [Data Flows](./training-operator-dataflow.mmd) - Sequence diagram: startup TLS/cert bootstrap, job submission and admission, reconciliation, metrics scrape
- [Dependencies](./training-operator-dependencies.mmd) - Kubernetes/OpenShift APIs, Go libraries, optional gang schedulers, RHOAI operator, Kueue, monitoring, job init images

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions (ports, TLS profile, RBAC, NetworkPolicies, secrets, key risks)
- [RBAC Visualization](./training-operator-rbac.mmd) - Operator ClusterRole, webhook Secret Role, MPI launcher Role, aggregated user roles

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks; renders automatically
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
- Suitable for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/training-operator.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
