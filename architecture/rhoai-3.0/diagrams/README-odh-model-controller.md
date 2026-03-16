# Architecture Diagrams for odh-model-controller

Generated from: `architecture/rhoai-3.0/odh-model-controller.md`
Date: 2026-03-16
Component Version: 1.27.0-rhods-1087-ga27ba4e (rhoai-3.0 branch)

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components, controllers, CRDs, and dependencies
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of InferenceService deployment, NIM account reconciliation, and metrics collection
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing required and optional external/internal dependencies

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr) showing component in broader ODH ecosystem
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with controllers and integrations

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable) with color-coded zones
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with complete RBAC and secrets details
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings visualization

## Component Overview

**odh-model-controller** extends KServe's model serving functionality with OpenShift-specific features:

- **Purpose**: Provides OpenShift-native model serving capabilities including ingress (Routes), security (NetworkPolicies, RBAC), monitoring (ServiceMonitors), and Nvidia NIM integration
- **Type**: Kubernetes Controller/Operator
- **Deployment**: Runs in opendatahub namespace (typical), watches cluster-wide KServe resources

**Key Controllers**:
- InferenceService Controller - Provisions Routes, NetworkPolicies, RBAC, monitoring
- ServingRuntime Controller - Manages ServingRuntime lifecycle
- LLMInferenceService Controller - Handles LLM services with Gateway API/Istio integration
- NIM Account Controller - Manages Nvidia NIM accounts, pull secrets, runtime templates
- Webhook Server - Validates/mutates Pods, InferenceServices, NIM Accounts

**Key Integrations**:
- **Required**: KServe v0.13+, OpenShift Routes 4.x
- **Optional**: Istio, Kuadrant, KEDA, Gateway API, Model Registry, Nvidia NGC
- **Internal ODH**: DSC Initialization (config), Model Registry (optional), Service CA (webhook certs)

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks - renders automatically!
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

## Updating Diagrams

To regenerate after architecture changes:
```bash
# Navigate to repository root
cd /path/to/kahowell.rhoai-architecture-diagrams

# Regenerate diagrams
/generate-architecture-diagrams --architecture=architecture/rhoai-3.0/odh-model-controller.md
```

## Diagram Details

### Component Structure Diagram (odh-model-controller-component.mmd)
Shows the internal architecture of odh-model-controller with:
- **8 reconciliation controllers**: InferenceService, ServingRuntime, LLMInferenceService, InferenceGraph, NIM Account, Pod, Secret, ConfigMap
- **Servers**: Webhook server (9443/TCP HTTPS), Metrics server (8080/TCP HTTP)
- **Custom resources watched**: InferenceService, ServingRuntime, LLMInferenceService, InferenceGraph, NIM Account (serving.kserve.io, nim.opendatahub.io)
- **Resources created**: Routes, NetworkPolicies, ServiceMonitors, PodMonitors, EnvoyFilters (Istio), AuthPolicies (Kuadrant), HTTPRoutes (Gateway API), TriggerAuthentications (KEDA), Image Pull Secrets, Runtime Templates
- **External dependencies**: KServe v0.13+, OpenShift Routes 4.x, Istio, Kuadrant, KEDA, Gateway API, Prometheus Operator, Nvidia NGC
- **Internal ODH dependencies**: Model Registry (optional), DSC Initialization, OpenShift Service CA

### Data Flow Diagram (odh-model-controller-dataflow.mmd)
Illustrates four key operational flows:

1. **InferenceService Deployment** - Complete lifecycle of deploying a model serving endpoint:
   - User creates InferenceService CR via Kubernetes API
   - Webhook validates/mutates the InferenceService
   - Controller provisions OpenShift Route for external access
   - Controller creates NetworkPolicy for network isolation
   - Controller creates ServiceMonitor/PodMonitor for Prometheus scraping
   - Controller creates RBAC resources (ServiceAccount, Roles, RoleBindings)
   - Controller optionally registers model with Model Registry

2. **NIM Account Reconciliation** - Nvidia NIM account setup and validation:
   - User creates NIM Account CR
   - Webhook validates API key secret exists
   - Controller validates account with Nvidia NGC API
   - NGC API returns account validation + model catalog
   - Controller creates image pull secret for NIM model images
   - Controller processes runtime templates for NIM-based ServingRuntimes
   - Controller updates Account status with available model list

3. **Metrics Collection** - Prometheus integration:
   - Prometheus scrapes /metrics endpoint (8080/TCP HTTP)
   - Bearer Token authentication via ServiceAccount
   - Controller exposes metrics in Prometheus format

4. **Predictor Pod Mutation** - Webhook-based pod modification:
   - User creates InferenceService (triggers Pod creation)
   - Kubernetes API calls webhook to mutate Pod
   - Webhook injects labels and annotations for KServe predictor integration
   - Kubernetes API creates Pod with mutations applied

### Security Network Diagram
Provides detailed security architecture in two formats:

**ASCII version (.txt)**: Precise text format for Security Architecture Reviews (SAR)
- Complete port/protocol/encryption/auth details for all network flows
- Trust zones: External (Untrusted) → Kubernetes API (Trust Boundary) → Controller Pod (Internal) → Egress Targets
- Detailed RBAC summary with all ClusterRole permissions by API group/resource
- Secrets management: Service CA webhook cert (auto-rotate), NIM API keys (user-managed), image pull secrets (controller-created)
- Network isolation and security controls

**Mermaid version (.mmd + .png)**: Visual representation for presentations
- Color-coded trust zones for easy understanding
- Visual network flow with ports, protocols, encryption, authentication
- External (gray), Kubernetes API boundary (orange), Controller Pod (green), Egress Targets (yellow), Created Resources (purple)

**Key security details**:
- **Webhook server**: 9443/TCP HTTPS TLS 1.2+ (TLS client cert auth from Kubernetes API)
- **Metrics server**: 8080/TCP HTTP (TODO: migrate to HTTPS/8443) - Bearer Token auth via kube-rbac-proxy
- **Health probes**: 8081/TCP HTTP (internal pod only, no auth) - /healthz, /readyz
- **Egress connections**:
  - Kubernetes API: 443/TCP HTTPS TLS 1.2+ Bearer Token (watch CRDs, create resources)
  - Nvidia NGC API: 443/TCP HTTPS TLS 1.2+ API Key (validate NIM accounts, fetch model catalogs)
  - Model Registry: 443/TCP HTTPS TLS 1.2+ Bearer Token (register models, optional)
  - OpenShift Template API: 443/TCP HTTPS TLS 1.2+ Bearer Token (process NIM runtime templates)
- **Pod security**: Non-root user (UID 2000), FIPS-compliant ubi9/ubi-minimal base image, resource limits (CPU 500m, Memory 2Gi)
- **Secrets**: Service CA for webhook certificates (auto-rotation), NIM API keys (user-managed), image pull secrets (controller-created), managed secrets (labeled opendatahub.io/managed=true)

### Dependencies Diagram (odh-model-controller-dependencies.mmd)
Shows the dependency graph with clear categorization:

**Required External Dependencies**:
- KServe v0.13+ - Provides core InferenceService, ServingRuntime, LLMInferenceService CRDs
- OpenShift Routes 4.x - External ingress for model serving endpoints
- Kubernetes API Server - Resource management and admission webhooks

**Optional External Dependencies**:
- Prometheus Operator - ServiceMonitor/PodMonitor creation for metrics collection
- Istio Service Mesh 1.x - EnvoyFilter for SSL/TLS passthrough (LLM services)
- Kuadrant - AuthPolicy for authentication/authorization (LLM services)
- KEDA 2.x - TriggerAuthentication for custom metrics-based autoscaling
- Gateway API v1 - HTTPRoute for LLM inference services (alternative to Istio)
- Nvidia NGC - NIM account validation and model catalog access

**Internal ODH Dependencies**:
- Model Registry - HTTP API for registering deployed InferenceServices (optional, controlled via MODELREGISTRY_STATE)
- DSC Initialization - Reads DataScienceCluster and DSCInitialization CRDs for platform configuration
- OpenShift Service CA - Provides webhook TLS certificates via service annotation (auto-rotation)

**Integration Points**:
- ODH Dashboard - UI integration for model management
- Data Science Pipelines - Auto-deploy models from pipeline runs

**Creates Resources For**:
- Model serving workloads - InferenceService predictor pods with supporting infrastructure

### RBAC Visualization Diagram (odh-model-controller-rbac.mmd)
Visualizes the complete RBAC structure with detailed permissions:

**Service Account**: `odh-model-controller` (in opendatahub or controller namespace)

**ClusterRole Bindings**:
1. `odh-model-controller-rolebinding` - Binds SA to `odh-model-controller-role` (main permissions)
2. `leader-election-rolebinding` - Binds SA to `leader-election-role` (HA support)
3. `metrics-auth-rolebinding` - Binds SA to `metrics-auth-role` (metrics access)

**Permissions by Resource Category**:

*Core Resources*:
- `configmaps, secrets, serviceaccounts, services`: create, delete, get, list, patch, update, watch
- `endpoints, namespaces, pods`: create, get, list, patch, update, watch
- `events`: create, patch

*KServe Resources (serving.kserve.io)*:
- `inferenceservices, inferenceservices/finalizers`: get, list, patch, update, watch, create, delete
- `servingruntimes, servingruntimes/finalizers`: create, get, list, update, watch
- `llminferenceservices, llminferenceservices/status, llminferenceservices/finalizers`: get, list, patch, post, update, watch
- `inferencegraphs, inferencegraphs/finalizers, llminferenceserviceconfigs`: get, list, watch, update

*OpenShift Resources*:
- `routes (route.openshift.io), routes/custom-host`: create, delete, get, list, patch, update, watch
- `templates (template.openshift.io)`: create, delete, get, list, patch, update, watch
- `authentications (config.openshift.io)`: get, list, watch

*Networking Resources*:
- `networkpolicies, ingresses (networking.k8s.io)`: create, delete, get, list, patch, update, watch
- `envoyfilters (networking.istio.io)`: create, delete, get, list, patch, update, watch
- `gateways, gateways/finalizers, httproutes (gateway.networking.k8s.io)`: get, list, patch, update, watch

*Monitoring Resources*:
- `servicemonitors, podmonitors (monitoring.coreos.com)`: create, delete, get, list, patch, update, watch

*Security & Auth Resources*:
- `clusterrolebindings, roles, rolebindings (rbac.authorization.k8s.io)`: create, delete, get, list, patch, update, watch
- `authpolicies, authpolicies/status (kuadrant.io)`: create, delete, get, list, patch, update, watch

*Autoscaling Resources*:
- `triggerauthentications (keda.sh)`: create, delete, get, list, patch, update, watch

*NIM Resources*:
- `accounts, accounts/status, accounts/finalizers (nim.opendatahub.io)`: get, list, patch, update, watch

*ODH Platform Resources*:
- `datascienceclusters (datasciencecluster.opendatahub.io)`: get, list, watch
- `dscinitializations (dscinitialization.opendatahub.io)`: get, list, watch

*Metrics Resources*:
- `nodes, pods (metrics.k8s.io)`: get, list, watch

*Leader Election Resources*:
- `configmaps, leases (coordination.k8s.io), events`: get, list, watch, create, update, patch, delete

### C4 Context Diagram (odh-model-controller-c4-context.dsl)
Provides architectural context in Structurizr C4 format:

**Actors**:
- Data Scientist / ML Engineer - Deploys and manages ML models on OpenShift
- Platform Administrator - Manages NIM accounts and platform configuration

**System: odh-model-controller**:
- **Controller Manager Container**: Reconciles KServe resources and provisions supporting infrastructure
  - Components: InferenceService Controller, ServingRuntime Controller, LLMInferenceService Controller, InferenceGraph Controller, NIM Account Controller, Pod Controller, Secret Controller, ConfigMap Controller
- **Webhook Server Container**: Validates and mutates Pods, InferenceServices, InferenceGraphs, LLMInferenceServices, NIM Accounts
- **Metrics Server Container**: Exposes Prometheus metrics on /metrics endpoint

**External Systems**:
- KServe - Provides core CRDs (InferenceService, ServingRuntime, LLMInferenceService)
- OpenShift - Routes for ingress, Service CA for webhook certs, Template API for NIM runtimes
- Kubernetes API Server - Manages cluster resources, serves admission webhooks
- Prometheus Operator - Collects metrics via ServiceMonitor/PodMonitor
- Istio Service Mesh - EnvoyFilter for SSL/TLS passthrough (optional)
- Kuadrant - AuthPolicy for authentication/authorization (optional)
- KEDA - Autoscaling based on custom metrics (optional)
- Gateway API - HTTPRoute for LLM services (optional)
- Nvidia NGC - Validates NIM accounts, provides model catalog access (optional)

**Internal ODH Systems**:
- Model Registry - Stores model metadata and deployment information (optional)
- DSC Initialization - Provides platform configuration via DataScienceCluster and DSCInitialization CRDs

**Relationships**:
- User creates InferenceService, ServingRuntime, LLMInferenceService CRs via kubectl/UI
- Admin creates NIM Account CRs, configures platform settings
- Controller watches and reconciles KServe CRDs
- Controller creates Routes (OpenShift), NetworkPolicies, ServiceMonitors, EnvoyFilters, AuthPolicies, HTTPRoutes, TriggerAuthentications
- Controller validates NIM accounts with Nvidia NGC API
- Controller optionally registers deployed models with Model Registry
- Prometheus scrapes /metrics endpoint
- Kubernetes API calls webhook endpoints for validation/mutation

## Additional Resources

- **Architecture Documentation**: [../odh-model-controller.md](../odh-model-controller.md)
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller
- **Version**: 1.27.0-rhods-1087-ga27ba4e (rhoai-3.0 branch)
- **KServe Integration**: Extends KServe v0.13+ with OpenShift-native capabilities
- **NIM Integration**: Manages Nvidia NIM accounts for deploying NVIDIA Inference Microservices models

## Configuration

**Environment Variables** (Security-Relevant):
- `NIM_STATE`: managed|removed - Controls NIM controller functionality
- `KSERVE_STATE`: replace|managed|removed - Controls KServe integration
- `MODELREGISTRY_STATE`: replace|managed|removed - Controls Model Registry integration
- `ENABLE_WEBHOOKS`: true|false - Enable/disable admission webhooks
- `MR_SKIP_TLS_VERIFY`: false|true - Model Registry TLS verification (default: secure)
- `POD_NAMESPACE`: (from fieldRef) - Controller namespace

**Resource Requirements**:
- Requests: CPU 10m, Memory 64Mi
- Limits: CPU 500m, Memory 2Gi

**Runtime Templates** (Deployed by Controller):
- vllm-cuda-template (NVIDIA GPU CUDA)
- vllm-cpu-template (CPU)
- vllm-rocm-template (AMD GPU ROCm)
- vllm-gaudi-template (Intel Gaudi)
- vllm-multinode-template (Multi-node NVIDIA GPU)
- vllm-spyre-x86-template (x86_64 with Spyre acceleration)
- vllm-spyre-s390x-template (IBM s390x with Spyre acceleration)
- ovms-kserve-template (OpenVINO Model Server)
- hf-detector-template (HuggingFace model detector)

## Notes

- Controller creates resources in user namespaces (Routes, NetworkPolicies, RBAC, monitoring) for each InferenceService
- NIM functionality can be disabled via environment variable: `NIM_STATE=removed`
- Model Registry integration is optional: `MODELREGISTRY_STATE=managed|replace|removed`
- All builds are FIPS-compliant using Go strict FIPS runtime mode with CGO_ENABLED=1
- Leader election enabled for high-availability deployments
- Metrics endpoint migration from HTTP/8080 to HTTPS/8443 is planned (TODO)
- Webhook endpoints secured with TLS certificates from OpenShift Service CA (auto-rotation)
- Controller uses label-based caching for Secrets (`opendatahub.io/managed=true`) and Pods (`component=predictor`) to reduce memory footprint
- Supports both Istio-based (EnvoyFilter) and Gateway API-based (HTTPRoute) ingress patterns for LLM services
