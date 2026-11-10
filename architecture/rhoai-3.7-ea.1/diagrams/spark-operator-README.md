# Architecture Diagrams for Spark Operator

Generated from: `architecture/rhoai-3.7-ea.1/spark-operator.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: The component has two tiers. A platform module controller (`spark-operator-module-controller-manager`) reconciles the singleton `SparkOperator` CR. The workload operator image runs as two Deployments: `spark-operator-controller` (runs `spark-submit` in-process) and `spark-operator-webhook`. Opt-in or disabled features (UI Ingress, driver PDBs, cert-manager, RestSubmitter, batch schedulers) are drawn dashed.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./spark-operator-component.mmd) - Module controller, controller sub-reconcilers (SparkApplication, ScheduledSparkApplication, SparkConnect, operand NetworkPolicy), webhook handlers and cert management, CRs and operand resources
- [Data Flows](./spark-operator-dataflow.mmd) - Sequence diagram: platform enablement, SparkApplication submission with admission, SparkConnect session, metrics scraping
- [Dependencies](./spark-operator-dependencies.mmd) - Platform integrations, OpenShift services, Spark runtime (JDK 17, PySpark 4.0.4), key Go libraries, optional integrations

### For Architects
- [C4 Context](./spark-operator-c4-context.dsl) - System context and container views in C4 format (Structurizr)
- [Component Overview](./spark-operator-component.mmd) - Two-tier module pattern

### For Security Teams
- [Security Network Diagram (Mermaid)](./spark-operator-security-network.mmd) - Trust zones: admission path 443→9443, unauthenticated metrics and probes, plaintext Spark RPC and SparkConnect gRPC, allow-all egress
- [Security Network Diagram (ASCII)](./spark-operator-security-network.txt) - Precise text format for SAR submissions: ports, TLS profile handling, admission scope, RBAC summary, secrets, FIPS, key observations
- [RBAC Visualization](./spark-operator-rbac.mmd) - All four ServiceAccounts and their bindings. The module manager role is highlighted as cluster-admin-equivalent (unscoped RBAC create, bind/escalate, CRDs)

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown inside a ` ```mermaid ` code block and it renders automatically
- **Live editor**: https://mermaid.live (paste, edit, export)

**Manual PNG generation** (if needed):
```bash
npm install -g @mermaid-js/mermaid-cli
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
```

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor and include in documentation as-is
- Intended for security reviews

## Updating Diagrams

```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/spark-operator.md
```
