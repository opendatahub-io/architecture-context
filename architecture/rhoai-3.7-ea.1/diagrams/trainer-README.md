# Architecture Diagrams for Trainer

Generated from: `architecture/rhoai-3.7-ea.1/trainer.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: Kubeflow Trainer v2 (upstream v2.3.0) as shipped in RHOAI 3.7-ea.1. It has two Go managers: the RHOAI module operator `trainer-operator`, driven by the platform through the `Trainer` CR, and the operand `kubeflow-trainer-controller-manager`, which turns TrainJobs into JobSets. Gated features that are off in RHOAI (`TrainJobStatus` status server, `OptimizationJob` with its Optuna gRPC service) appear as dashed elements.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./trainer-component.mmd) - trainer-operator, operand internals (reconcilers, plugin framework, webhooks, cert-controller, RHAI progression and NetworkPolicy), CRDs and created resources
- [Data Flows](./trainer-dataflow.mmd) - Sequence diagram: platform enables Trainer, user submits a TrainJob, RHAI progression tracking, metrics scraping
- [Dependencies](./trainer-dependencies.mmd) - JobSet Operator gate, platform integrations, optional gang schedulers, Go libraries

### For Architects
- [C4 Context](./trainer-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./trainer-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./trainer-security-network.mmd) - Trust zones, ports, TLS, auth, with plaintext and insecure paths highlighted
- [Security Network Diagram (ASCII)](./trainer-security-network.txt) - Precise text format for SAR submissions: listeners, NetworkPolicies, RBAC, webhooks, secrets, findings
- [RBAC Visualization](./trainer-rbac.mmd) - Operand, operator, monitoring and user-facing roles and bindings

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks and it renders automatically.
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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/trainer.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
