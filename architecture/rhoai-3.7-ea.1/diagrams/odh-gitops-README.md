# Architecture Diagrams for odh-gitops

Generated from: `architecture/rhoai-3.7-ea.1/odh-gitops.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: odh-gitops is a configuration repository. It builds no images. The diagrams cover the Kustomize tree, the `rhai-on-openshift-chart` (OLM-based, including the AI Grid / Praxis subcharts) and the `rhai-on-xks-chart` (non-OLM install for AKS/EKS/CoreWeave), plus the workloads and network paths those charts render directly.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./odh-gitops-component.mmd) - Kustomize components/dependencies/configurations, OpenShift chart templates and AI Grid subcharts, XKS chart operators, hook Jobs and vendored charts
- [Data Flows](./odh-gitops-dataflow.mmd) - Sequence diagram: OpenShift Helm/Argo CD install with CRD gating, AI Grid cross-site inference, AI Grid spoke-to-hub observability, XKS install
- [Dependencies](./odh-gitops-dependencies.mmd) - OLM dependency operators (tri-state `auto`), transitive requirements, internal RHOAI components, ACM/Praxis/NooBaa, XKS dependencies

### For Architects
- [C4 Context](./odh-gitops-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./odh-gitops-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./odh-gitops-security-network.mmd) - Trust zones for OpenShift ingress, AI Grid mTLS trust domain, spoke/hub observability and XKS gateways; plaintext and risk paths highlighted
- [Security Network Diagram (ASCII)](./odh-gitops-security-network.txt) - Precise text format for SAR submissions: ports, TLS, auth, RBAC, secrets and rotation, flagged risks
- [RBAC Visualization](./odh-gitops-rbac.mmd) - XKS operator, cloud manager, hook Job, AI Grid usage-log and bootstrap RBAC

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
- Perfect for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/odh-gitops.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
