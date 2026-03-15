# Architecture Diagrams for TrustyAI Service Operator

Generated from: `architecture/rhoai-3.0/trustyai-service-operator.md`
Date: 2026-03-15
Component Version: 1.39.0

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - Mermaid diagram showing operator controller, managed services (TrustyAI Service, LM Evaluation Jobs, Guardrails Orchestrator), custom resources, and integrations with KServe and Istio
- [Data Flows](./trustyai-service-operator-dataflow.png) ([mmd](./trustyai-service-operator-dataflow.mmd)) - Sequence diagrams showing four key flows: TrustyAI data ingestion, guardrails request orchestration, LM evaluation job execution, and InferenceService guardrails injection
- [Dependencies](./trustyai-service-operator-dependencies.png) ([mmd](./trustyai-service-operator-dependencies.mmd)) - Component dependency graph showing relationships with Kubernetes, KServe, Istio, Kueue, Prometheus, databases, and model registries

### For Architects
- [C4 Context](./trustyai-service-operator-c4-context.dsl) - System context in C4 format (Structurizr) showing the operator's role in the broader RHOAI ecosystem with three main containers (TrustyAI Service, LM Evaluation Jobs, Guardrails Orchestrator) and their interactions
- [Component Overview](./trustyai-service-operator-component.png) ([mmd](./trustyai-service-operator-component.mmd)) - High-level component view with operator controller, managed deployments, sidecars, and storage options

### For Security Teams
- [Security Network Diagram (PNG)](./trustyai-service-operator-security-network.png) - High-resolution network topology with trust zones (External, Ingress, Operator Namespace, User Namespace, External Services, Monitoring)
- [Security Network Diagram (Mermaid)](./trustyai-service-operator-security-network.mmd) - Visual network topology (editable) with detailed port, protocol, encryption, and authentication information
- [Security Network Diagram (ASCII)](./trustyai-service-operator-security-network.txt) - Precise text format for SAR submissions with complete RBAC summary, service mesh configuration, secrets management, and network policies
- [RBAC Visualization](./trustyai-service-operator-rbac.png) ([mmd](./trustyai-service-operator-rbac.mmd)) - Comprehensive RBAC permissions showing ClusterRoles (manager-role, leader-election-role, non-admin-lmeval-role), service accounts, and detailed API resource permissions

## Component Overview

The TrustyAI Service Operator manages three key AI governance components:

1. **TrustyAI Service**: ML explainability and bias detection with PVC or database storage
2. **LM Evaluation Jobs**: Language model assessment with Kueue integration for scheduling
3. **Guardrails Orchestrator**: AI safety controls with detector and generator InferenceServices

### Key Features

- **Multi-Service Management**: Single operator managing TrustyAI services, evaluation jobs, and guardrails
- **KServe Integration**: Watches and patches InferenceServices for guardrails injection
- **Flexible Storage**: Supports both PVC-based and database-backed storage (PostgreSQL/MySQL)
- **OAuth Proxy**: Optional kube-rbac-proxy integration for secured access
- **Service Mesh**: Istio VirtualServices and DestinationRules for traffic management
- **Observability**: ServiceMonitors for Prometheus, OpenTelemetry for guardrails telemetry
- **Job Scheduling**: Kueue integration for LMEvalJob resource management

### Network Architecture Highlights

**Ingress (OpenShift Routes)**:
- TrustyAI Service: 443/TCP HTTPS (edge termination)
- Guardrails Orchestrator: 443/TCP HTTPS (reencrypt) with OAuth on port 8432
- Guardrails Gateway: 443/TCP HTTPS (reencrypt) on port 8090

**Internal Services**:
- TrustyAI: 80/TCP (metrics), 443/TCP (HTTPS), 8443/TCP (RBAC-protected)
- Guardrails: 8032/TCP (HTTPS), 8034/TCP (health), 8090/TCP (gateway), 8432/TCP (OAuth)
- Operator: 8443/TCP (metrics via RBAC proxy)

**Security**:
- mTLS via Istio service mesh for InferenceService communication
- TLS 1.2+ for all HTTPS endpoints
- Bearer token authentication via kube-rbac-proxy
- SubjectAccessReview for authorization
- Auto-rotating TLS certificates via OpenShift service-ca

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ` ```mermaid ` code blocks - renders automatically!
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG regeneration** (if you edit .mmd files):

1. **Ensure Mermaid CLI is installed**:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. **Regenerate PNG** (3000px width):
   ```bash
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`
- **Online**: https://structurizr.com/dsl

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Details

### Component Diagram
Shows the operator controller reconciling TrustyAIService, LMEvalJob, and GuardrailsOrchestrator custom resources. Illustrates managed deployments with sidecars (kube-rbac-proxy, LMES driver, built-in detector, gateway), storage options (PVC/database), and integrations with KServe InferenceServices, Prometheus ServiceMonitors, OpenShift Routes, and Istio VirtualServices.

### Data Flow Diagram
Four key flows:
1. **TrustyAI Service Data Ingestion**: External client → OpenShift Router → TrustyAI Service → PVC/Database → Prometheus
2. **Guardrails Request Orchestration**: Client → Router → kube-rbac-proxy (OAuth) → Guardrails Orchestrator → Detector/Generator InferenceServices → OTLP Collector
3. **LM Evaluation Job Execution**: User → Kubernetes API → Operator creates Job → LMES Driver downloads model → LMES Job evaluates InferenceService → Results stored in Secret
4. **InferenceService Guardrails Injection**: Operator watches InferenceServices → Patches with finalizers and gateway config → InferenceService routes via Gateway → Guardrails Orchestrator

### Security Network Diagram
Detailed network topology with five trust zones:
- **External (Untrusted)**: External clients and data scientists
- **Ingress (DMZ)**: OpenShift Routes with TLS termination (edge/reencrypt)
- **Operator Namespace (System Components)**: TrustyAI operator controller, metrics service
- **User Namespace (Application Components)**: TrustyAI Service, Guardrails Orchestrator, LMEvalJobs with sidecars, PVC/database storage, KServe InferenceServices
- **External Services**: Model registries, dataset repositories, OTLP collectors, external databases
- **Monitoring (Trusted)**: Prometheus scraping metrics

Includes complete RBAC summary, service mesh configuration (Istio mTLS), secrets management (TLS certificates, database credentials, job outputs), and network policies.

### C4 Context Diagram
System context showing:
- **Users**: Data scientists creating TrustyAI CRs, ML engineers querying services
- **Containers**: Operator Controller, TrustyAI Service, LM Evaluation Job, Guardrails Orchestrator, Kube-RBAC-Proxy
- **External Systems**: Kubernetes API, KServe, Istio, Prometheus, OpenShift Router, Model Registry, PostgreSQL/MySQL, OTLP Collector, Kueue, Dataset Repositories
- **Components**: Reconciler, Service/Job/Guardrails Managers, REST API, Metrics Exporter, Storage Adapter, LMES Driver/Executor, Orchestrator API, Detector Client, Telemetry Exporter

### Dependencies Diagram
Shows dependencies on:
- **External Platforms**: Kubernetes 1.19+, OpenShift 4.6+ (optional), Prometheus Operator, Istio, cert-manager, Kueue
- **Internal RHOAI**: KServe InferenceService (watch/patch), Model Mesh (label detection), DSC ConfigMap (platform config)
- **External Services**: PostgreSQL/MySQL (optional storage), OTLP Collector (telemetry), Model Registry (LMES), Dataset Repositories (LMES)
- **Integration Points**: ODH Dashboard (UI management), Data Science Pipelines (auto evaluation)

### RBAC Visualization
Detailed RBAC matrix showing:
- **ClusterRoles**:
  - `manager-role`: Comprehensive operator permissions (core, apps, KServe, TrustyAI, monitoring, routes, Istio, Kueue, RBAC, coordination, API extensions, scheduling)
  - `leader-election-role`: ConfigMaps, leases, events for leader election
  - `non-admin-lmeval-role`: LMEvalJob user permissions (create, delete, get, list, patch, update, watch jobs; get status)
- **Service Accounts**: controller-manager, default (per namespace), trustyai-name-sa, gorch-name-sa, lmevaljob-name-sa
- **Bindings**: ClusterRoleBindings (manager, default-lmeval-user), RoleBindings (leader-election, auth-proxy)
- **API Resources**: Core, apps, KServe, TrustyAI, monitoring, routes, Istio, Kueue, RBAC, coordination, API extensions, scheduling with specific verbs per resource

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-3.0/diagrams --width=3000
```

## Related Documentation

- Architecture file: [../trustyai-service-operator.md](../trustyai-service-operator.md)
- Repository: https://github.com/red-hat-data-services/trustyai-service-operator.git
- Version: 1.39.0
- RHOAI Platform: [../PLATFORM.md](../PLATFORM.md)
