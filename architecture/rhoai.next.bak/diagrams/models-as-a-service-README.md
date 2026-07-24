# Architecture Diagrams for Models as a Service (MaaS)

Generated from: `../models-as-a-service.md`
Date: 2026-05-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./models-as-a-service-component.mmd) - Internal components (maas-controller, maas-api, payload-processing), CRDs, reconciler relationships
- [Data Flows](./models-as-a-service-dataflow.mmd) - Sequence diagrams: API key auth + inference, subscription/policy lifecycle, tenant platform reconcile
- [Dependencies](./models-as-a-service-dependencies.mmd) - Component dependency graph (Kuadrant, KServe, Istio, PostgreSQL, Gateway API, OpenShift)

### For Architects
- [C4 Context](./models-as-a-service-c4-context.dsl) - System context in C4 format (Structurizr) with containers and components
- [Component Overview](./models-as-a-service-component.mmd) - High-level component view with reconciler detail

### For Security Teams
- [Security Network Diagram (Mermaid)](./models-as-a-service-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./models-as-a-service-security-network.txt) - Precise text format for SAR submissions with full RBAC, secrets, FIPS details
- [RBAC Visualization](./models-as-a-service-rbac.mmd) - RBAC permissions and bindings for all 3 service accounts

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks - renders automatically!
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
/generate-architecture-diagrams --architecture=../models-as-a-service.md
```
