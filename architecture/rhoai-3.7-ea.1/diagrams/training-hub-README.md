# Architecture Diagrams for Training Hub

Generated from: `architecture/rhoai-3.7-ea.1/training-hub.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: Training Hub (v0.11.2) is an in-process Python library and CLI (`thub`). It has no Kubernetes Services, Ingress, CRDs or RBAC. RHOAI ships it pre-installed in the `distributed-workloads` universal training images, which run as workbenches and as Kubeflow Trainer v2 / KFTO runtimes. The diagrams show its algorithm/backend registry, the torchrun and checkpoint runtime behavior, and its outbound integrations.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./training-hub-component.mmd) - thub CLI, Python API, AlgorithmRegistry, algorithm→backend matrix, callbacks, JIT checkpointing, outbound integrations
- [Data Flows](./training-hub-dataflow.mmd) - Sequence diagram: distributed SFT/OSFT in a TrainJob, preemption JIT checkpoint, GEPA prompt optimization
- [Dependencies](./training-hub-dependencies.mmd) - Required libraries, optional extras (backends), RHOAI integrations, external services

### For Architects
- [C4 Context](./training-hub-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./training-hub-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./training-hub-security-network.mmd) - Trust zones, plaintext inter-rank traffic, code-execution inputs, egress (editable)
- [Security Network Diagram (ASCII)](./training-hub-security-network.txt) - Precise text format for SAR submissions: ports, TLS, auth, secrets, trust boundaries
- [RBAC Visualization](./training-hub-rbac.mmd) - No RBAC of its own; inherits hosting pod identity and consumes env-var credentials

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks. They render automatically.
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
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/training-hub.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
