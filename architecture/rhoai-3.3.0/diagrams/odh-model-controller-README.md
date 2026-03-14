# Architecture Diagrams for odh-model-controller

Generated from: `architecture/rhoai-3.3.0/odh-model-controller.md`
Date: 2026-03-14
Component: odh-model-controller (OpenShift AI Model Controller)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components, controllers, and integrations
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of InferenceService reconciliation, NIM validation, webhook admission, and metrics collection flows
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing KServe, OpenShift, ODH, and external service dependencies

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr) showing odh-model-controller in the broader OpenShift AI ecosystem
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with reconcilers and webhook server

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology with ports, protocols, encryption, and authentication
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with complete RBAC, secrets, network policies, and service mesh configuration
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings for ClusterRoles and ServiceAccounts

## Component Overview

The **odh-model-controller** is a Kubernetes operator that extends the KServe controller to provide seamless integration with OpenShift and Red Hat OpenShift AI. It watches KServe custom resources (InferenceServices, InferenceGraphs, ServingRuntimes) and performs additional reconciliation tasks that are specific to OpenShift environments.

### Key Responsibilities
- Creates and manages **OpenShift Routes** for model endpoints
- Configures **NetworkPolicies** for inference workloads
- Sets up **RBAC resources** for inference workloads
- Integrates with **Prometheus** for metrics collection via ServiceMonitors
- Manages **KEDA autoscaling** configurations (TriggerAuthentications)
- Handles **NVIDIA NIM** (NVIDIA Inference Microservices) account integrations and NGC API validation
- Manages serving runtime templates for various inference frameworks (vLLM, OpenVINO, MLServer, Caikit, TGIS) across multiple hardware architectures (x86, ppc64le, s390x)

### Key Components
- **InferenceService Controller**: Creates Routes, NetworkPolicies, RBAC, ServiceMonitors, TriggerAuthentications
- **NIM Account Controller**: Validates NGC API keys and creates NIM serving runtime templates
- **Webhook Server**: Validates and mutates KServe resources, NIM Accounts, and Pods (9443/TCP HTTPS)
- **Metrics Server**: Exposes Prometheus metrics (8080/TCP HTTP, TODO: migrate to HTTPS/8443)

### External Dependencies
- **KServe v0.15.1** (required) - Core model serving platform
- **Kubernetes v1.11.3+** (required) - Container orchestration
- **OpenShift v4.11+** (required) - Routes, Templates, service-ca
- **Prometheus Operator** (optional) - Metrics collection
- **KEDA v2.x** (optional) - Event-driven autoscaling
- **Istio** (optional) - Service mesh via EnvoyFilters
- **Kuadrant** (optional) - AuthPolicy for API authentication
- **NVIDIA NGC API** - NIM account validation and model configurations

### Internal ODH Dependencies
- **opendatahub-operator** - Reads DataScienceCluster and DSCInitialization CRDs
- **Model Registry** (optional) - Model metadata integration

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

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Details

### Component Structure Diagram
Shows the internal architecture of odh-model-controller:
- Controller Manager with 8 reconcilers (InferenceService, InferenceGraph, ServingRuntime, LLM, NIM, ConfigMap, Secret, Pod)
- Webhook Server (9443/TCP HTTPS) with validating and mutating webhooks
- Metrics Server (8080/TCP HTTP, TODO: migrate to HTTPS/8443)
- Health Server (8081/TCP HTTP)
- CRDs managed and watched (Account, InferenceService, InferenceGraph, ServingRuntime, etc.)
- Resources created (Routes, NetworkPolicies, RBAC, ServiceMonitors, TriggerAuthentications, EnvoyFilters, AuthPolicies, Templates)
- External dependencies (KServe, Kubernetes, OpenShift, Prometheus, KEDA, Istio, Kuadrant, NVIDIA NGC API)
- Internal ODH dependencies (opendatahub-operator, Model Registry)

### Data Flow Diagram
Shows four key flows:
1. **InferenceService Reconciliation**: User creates InferenceService → K8s API notifies controller → Controller creates Route, ServiceMonitor, NetworkPolicy, RBAC, TriggerAuthentication
2. **NIM Account Validation**: User creates Account CR → Webhook validates → Controller reads NGC Secret → Validates with NGC API → Creates NIM Template
3. **Webhook Admission Control**: User creates/updates resource → K8s API calls webhook → Webhook validates/mutates → Response to API server
4. **Metrics Collection**: Prometheus scrapes /metrics endpoint (8080/TCP HTTP) with Bearer Token authentication

### Security Network Diagram
Detailed network topology showing:
- **External**: User/Admin access via Kubernetes API (HTTPS/443 TLS1.2+)
- **Controller Plane**: odh-model-controller Pod with ServiceAccount, UID 2000, FIPS-enabled
  - Webhook Server (9443/TCP HTTPS TLS1.2+, mTLS from K8s API)
  - Metrics Server (8080/TCP HTTP, Bearer Token via kube-rbac-proxy, TODO: migrate to HTTPS/8443)
  - Health Server (8081/TCP HTTP, public endpoints)
- **Egress**: Kubernetes API (443/TCP HTTPS), NVIDIA NGC API (443/TCP HTTPS with NGC API Key), Model Registry (443/TCP HTTPS, optional)
- **RBAC Summary**: ClusterRoles, ClusterRoleBindings, ServiceAccount permissions
- **Secrets**: webhook-cert (auto-rotated by service-ca-operator), NGC API keys, Model Pull Secrets
- **NetworkPolicies**: Ingress/egress rules for InferenceService workloads
- **Service Mesh**: EnvoyFilter, AuthPolicy configurations

### C4 Context Diagram
System context showing odh-model-controller in the broader ecosystem:
- **Users**: Data Scientists, Platform Administrators
- **Core System**: odh-model-controller with containers (Controller Manager, Webhook Server, Metrics Server, Health Server)
- **External Dependencies**: KServe, Kubernetes, OpenShift, Istio, Knative, Prometheus Operator, KEDA, Kuadrant, cert-manager
- **Internal ODH**: opendatahub-operator, Model Registry
- **External Services**: NVIDIA NGC API, S3 Storage
- **Deployment**: OpenShift Cluster → redhat-ods-applications namespace → odh-model-controller Pod → User Namespace (managed resources)

### Component Dependency Graph
Visual dependency graph showing:
- **Required External**: KServe v0.15.1, Kubernetes v1.11.3+, OpenShift v4.11+
- **Optional External**: Prometheus Operator, KEDA v2.x, cert-manager, Kuadrant, Authorino, Istio
- **Internal ODH**: opendatahub-operator (DataScienceCluster, DSCInitialization), Model Registry
- **External Services**: NVIDIA NGC API (HTTPS/443)
- **Serving Runtimes**: vLLM v0.11.2, OpenVINO v2025.4, MLServer 1.7.1, Caikit v0.27.7, TGIS
- **Resources Created**: Routes, NetworkPolicies, RBAC, ServiceMonitors, TriggerAuthentications, EnvoyFilters, AuthPolicies, NIM Templates

### RBAC Visualization
RBAC matrix showing:
- **ServiceAccount**: odh-model-controller (redhat-ods-applications namespace)
- **ClusterRoles**:
  - `odh-model-controller-role` (main controller permissions)
  - `odh-model-controller-leader-election-role` (leader election)
  - `odh-model-controller-proxy-role` (token/auth validation)
  - `odh-model-controller-metrics-reader` (metrics proxy access)
- **API Groups & Resources**: KServe CRDs, NIM CRDs, Core resources, Network resources, Monitoring resources, Autoscaling resources, RBAC resources, Kuadrant resources, OpenShift resources, ODH resources
- **Verbs**: get, list, watch, create, update, patch, delete (varies by resource)

## Security Considerations

1. **Metrics Endpoint Security**: Currently uses HTTP (8080/TCP) instead of HTTPS. TODO: Migrate to HTTPS on port 8443 with proper TLS encryption.
2. **Webhook TLS**: Uses TLS 1.2+ with certificates from OpenShift service-ca-operator (auto-rotated).
3. **mTLS Authentication**: Kubernetes API server authenticates to webhook server using mTLS.
4. **OpenShift-Specific**: Requires OpenShift Routes, Templates, and service-ca-operator (may not function fully on vanilla Kubernetes).
5. **External Dependencies**: NVIDIA NGC API for NIM validation (outbound HTTPS/443), Model Registry API (optional, outbound HTTPS/443).
6. **FIPS Compliance**: Built with strictfipsruntime build tags, UBI9 minimal base image, non-root user (UID 2000).
7. **HTTP/2 Disabled**: Mitigates HTTP/2 Stream Cancellation vulnerability (CVE-2023-44487).

## Updating Diagrams

To regenerate after architecture changes:
```bash
# From the architecture/rhoai-3.3.0 directory
cd /path/to/architecture/rhoai-3.3.0

# Generate diagrams (auto-detects output directory)
/generate-architecture-diagrams architecture/rhoai-3.3.0/odh-model-controller.md

# Or specify custom output directory
/generate-architecture-diagrams architecture/rhoai-3.3.0/odh-model-controller.md --output-dir=./custom-diagrams
```

## Additional Resources

- **Architecture Documentation**: [odh-model-controller.md](../odh-model-controller.md)
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-1157-gfbaeb50
- **Branch**: rhoai-3.3
- **Distribution**: RHOAI (Red Hat OpenShift AI)
