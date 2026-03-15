# Architecture Diagrams for ODH Model Controller

Generated from: `architecture/rhoai-3.2/odh-model-controller.md`
Date: 2026-03-15
Component: odh-model-controller

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal components, reconcilers, webhooks, and watched resources
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagram of InferenceService creation, NIM account validation, and metrics collection flows
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing KServe, Istio, Kuadrant, and platform integrations

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr) showing ODH Model Controller in RHOAI ecosystem
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view with reconcilers and webhooks

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions with RBAC, secrets, and security posture details
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings for service account

## Component Overview

The ODH Model Controller extends KServe functionality with OpenShift-specific integrations:

- **Purpose**: Automatically provisions supporting infrastructure for KServe model serving workloads
- **Key Features**:
  - Creates OpenShift Routes for external ingress
  - Provisions NetworkPolicies for security
  - Sets up RBAC (ServiceAccounts, Roles, RoleBindings)
  - Creates monitoring resources (ServiceMonitors, PodMonitors)
  - Integrates with Kuadrant for authentication/authorization
  - Manages NVIDIA NIM account integration and pull secrets
  - Optional Model Registry integration

## Architecture Highlights

### Reconcilers
- **InferenceService Controller**: Creates Routes, NetworkPolicies, RBAC, ServiceMonitors, and registers with Model Registry
- **ServingRuntime Controller**: Manages ServingRuntime resources
- **LLMInferenceService Controller**: Creates AuthPolicies and EnvoyFilters for LLM API routing
- **NIM Account Controller**: Validates NGC accounts, fetches model lists, and provisions pull secrets
- **InferenceGraph Controller**: Manages multi-model inference pipelines

### Webhooks
- Pod mutating webhook (for predictor pods)
- InferenceService mutating/validating webhooks
- InferenceGraph mutating/validating webhooks
- NIM Account validating webhook

### Security Features
- Runs as non-root user (UID 2000)
- Drops ALL capabilities
- FIPS 140-2 compliant builds (strictfipsruntime)
- TLS encryption for webhook endpoints (service-ca auto-rotation)
- Label-based secret/pod watching for limited scope

### Network Architecture
- **Control Plane**: Webhook server (9443/TCP HTTPS), Metrics (8080/TCP HTTP), Health (8081/TCP HTTP)
- **Egress**: Kubernetes API (6443/TCP), Model Registry (443/TCP, optional), NVIDIA NGC (443/TCP, optional)
- **Managed Resources**: Routes, NetworkPolicies, RBAC, ServiceMonitors, PodMonitors, AuthPolicies, EnvoyFilters

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

## Key Dependencies

### Required External Dependencies
- **KServe v0.15.0**: Core model serving platform (InferenceService, ServingRuntime CRDs)
- **Istio v1.26.4**: Service mesh for EnvoyFilter-based routing and mTLS
- **Kuadrant Operator v1.2.0**: AuthPolicy CRD for authentication/authorization
- **Authorino Operator v0.11.1**: Executes authorization policies
- **Prometheus Operator v0.76.2**: ServiceMonitor/PodMonitor for monitoring
- **OpenShift API 4.x**: Route CRD for external ingress
- **Gateway API v1.2.1**: HTTPRoute and Gateway resources
- **Knative Serving**: Serverless mode autoscaling

### Optional Dependencies
- **KEDA v2.16.1**: TriggerAuthentication for autoscaling
- **Model Registry v0.2.19**: Model tracking (enabled via MODELREGISTRY_STATE=managed)

### Internal ODH Dependencies
- **DSC/DSCI Operator**: Platform configuration and feature flags

### External Services
- **NVIDIA NGC API**: NIM account validation, model lists, pull secrets (enabled via NIM_STATE=managed)

## Integration Points

- **KServe Controller**: Watches InferenceService/ServingRuntime/InferenceGraph CRDs
- **OpenShift Router**: Creates Routes for external HTTPS ingress
- **Istio Pilot**: Creates EnvoyFilters for LLM routing and request transformation
- **Kuadrant Authorino**: Creates AuthPolicies for InferenceService authentication
- **Prometheus**: Creates ServiceMonitors/PodMonitors for metrics collection
- **Model Registry**: Registers deployed InferenceServices (optional)
- **NVIDIA NGC**: Validates accounts, fetches models and pull secrets (optional)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# Regenerate all diagrams (from project root)
python scripts/generate_diagrams.py --architecture=architecture/rhoai-3.2/odh-model-controller.md

# Regenerate only PNGs (if you manually edited .mmd files)
python scripts/generate_diagram_pngs.py architecture/rhoai-3.2/diagrams --width=3000
```

## Related Documentation

- **Architecture Source**: [odh-model-controller.md](../odh-model-controller.md)
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-1125-gd4a76a6
- **Branch**: rhoai-3.2
