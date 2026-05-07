# Architecture Diagrams for Spark Operator

Generated from: `architecture/rhoai-3.4/spark-operator.md`
Date: 2026-05-07

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./spark-operator-component.mmd) - Internal components (controller, webhook, cert provider, scheduler registry)
- [Data Flows](./spark-operator-dataflow.mmd) - Sequence diagrams for SparkApplication submission, ScheduledSparkApplication cron, and SparkConnect lifecycle
- [Dependencies](./spark-operator-dependencies.mmd) - Component dependency graph (required + optional)

### For Architects
- [C4 Context](./spark-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./spark-operator-component.mmd) - High-level component view with CRDs and managed resources

### For Security Teams
- [Security Network Diagram (Mermaid)](./spark-operator-security-network.mmd) - Visual network topology with trust zones (editable)
- [Security Network Diagram (ASCII)](./spark-operator-security-network.txt) - Precise text format for SAR submissions (includes RBAC, secrets, FIPS compliance)
- [RBAC Visualization](./spark-operator-rbac.mmd) - 3 service accounts, 2 cluster roles, 2 namespace roles, 4 aggregated user-facing roles

## Key Architecture Highlights

- **Dual-process architecture**: Separate controller and webhook pods for failure isolation
- **3 CRDs**: SparkApplication (v1beta2), ScheduledSparkApplication (v1beta2), SparkConnect (v1alpha1)
- **26-step webhook mutation pipeline**: Injects env, volumes, GPU resources, scheduling, Prometheus monitoring
- **Pluggable batch schedulers**: Volcano, YuniKorn, Kube-Scheduler Plugins
- **FIPS warning**: CGO_ENABLED=0 means pure-Go crypto (not FIPS-compliant, will fail check-payload)
- **Self-signed TLS**: 2048-bit RSA, 10-year validity, 180-day auto-renewal for webhook certs

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
/generate-architecture-diagrams --architecture=../spark-operator.md
```
