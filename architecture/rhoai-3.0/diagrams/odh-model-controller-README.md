# Architecture Diagrams for odh-model-controller

Generated from: `architecture/rhoai-3.0/odh-model-controller.md`
Date: 2026-03-15
Component Version: 1.27.0-rhods-1087-ga27ba4e

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - Mermaid diagram showing internal reconcilers and servers
- [Data Flows](./odh-model-controller-dataflow.png) ([mmd](./odh-model-controller-dataflow.mmd)) - Sequence diagrams of key workflows (InferenceService deployment, NIM account reconciliation, model registry integration, metrics collection)
- [Dependencies](./odh-model-controller-dependencies.png) ([mmd](./odh-model-controller-dependencies.mmd)) - Component dependency graph showing required/optional dependencies and integration points

### For Architects
- [C4 Context](./odh-model-controller-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./odh-model-controller-component.png) ([mmd](./odh-model-controller-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./odh-model-controller-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./odh-model-controller-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./odh-model-controller-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./odh-model-controller-rbac.png) ([mmd](./odh-model-controller-rbac.mmd)) - RBAC permissions and bindings

## Component Summary

The odh-model-controller extends KServe's model serving functionality with OpenShift-specific features:

**Key Capabilities**:
- Provisions OpenShift Routes for external ingress to model serving endpoints
- Creates NetworkPolicies, RBAC roles/bindings for security
- Integrates with Prometheus (ServiceMonitors/PodMonitors) for monitoring
- Manages service mesh components (Istio EnvoyFilters, Kuadrant AuthPolicies)
- Provides Nvidia NIM (Inference Microservices) account management
- Supports Gateway API (HTTPRoutes) for LLM inference services
- Integrates KEDA autoscaling (TriggerAuthentications)
- Optional Model Registry synchronization

**Resources Managed**:
- Custom Resource Definitions: NIM Account (nim.opendatahub.io/v1)
- KServe CRDs: InferenceService, ServingRuntime, LLMInferenceService, InferenceGraph
- OpenShift: Routes, Templates
- Kubernetes: NetworkPolicies, RBAC, Secrets, ConfigMaps
- Monitoring: ServiceMonitors, PodMonitors
- Service Mesh: EnvoyFilters, AuthPolicies, HTTPRoutes
- Autoscaling: KEDA TriggerAuthentications

**Key Dependencies**:
- **Required**: KServe v0.13+, OpenShift Routes 4.x, Kubernetes API
- **Optional**: Prometheus Operator, Istio Service Mesh, Kuadrant, KEDA, Gateway API, Nvidia NGC, Model Registry

**Pre-configured Runtime Templates**:
- vLLM (CUDA, CPU, ROCm, Gaudi, Multinode, Spyre x86/s390x)
- OpenVINO Model Server
- HuggingFace Detector

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i odh-model-controller-diagram.mmd -o odh-model-controller-diagram.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i odh-model-controller-diagram.mmd -o odh-model-controller-diagram.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i odh-model-controller-diagram.mmd -o odh-model-controller-diagram.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**:
  ```bash
  docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
  ```
  Then open http://localhost:8080 and load the .dsl file

- **CLI export**:
  ```bash
  structurizr-cli export -workspace odh-model-controller-c4-context.dsl -format png
  ```

### ASCII Diagrams (.txt files)
- View in any text editor with monospace font
- Include in documentation as-is
- Perfect for security reviews (precise technical details)
- Use for Security Architecture Reviews (SAR) submissions

## Key Architectural Highlights

### Network Security

**Webhook Server**:
- Port: 9443/TCP (HTTPS, TLS 1.2+)
- Certificate: Auto-rotated by OpenShift Service CA
- Auth: TLS client certificate from Kubernetes API Server
- Validates/mutates: Pods, InferenceServices, InferenceGraphs, LLMInferenceServices, NIM Accounts

**Metrics Server**:
- Port: 8080/TCP (HTTP - TODO: migrate to HTTPS/8443)
- Auth: Bearer Token (ServiceAccount)
- Scraped by Prometheus via ServiceMonitor

**External Integrations**:
- Nvidia NGC API: HTTPS/443, TLS 1.2+, API Key authentication
- Model Registry: HTTPS/443, TLS 1.2+, Bearer Token (TLS verification configurable)
- Kubernetes API: HTTPS/443, TLS 1.2+, Bearer Token

### RBAC Scope

The controller requires extensive cluster-level permissions to manage:
- KServe CRDs (InferenceService, ServingRuntime, LLMInferenceService, InferenceGraph)
- NIM Account CRD (nim.opendatahub.io)
- OpenShift Routes and Templates
- NetworkPolicies for security isolation
- RBAC resources (Roles, RoleBindings, ClusterRoleBindings)
- Monitoring resources (ServiceMonitors, PodMonitors)
- Service mesh resources (EnvoyFilters, AuthPolicies, HTTPRoutes, Gateways)
- KEDA TriggerAuthentications
- Secrets and ConfigMaps (with label-based caching: opendatahub.io/managed=true)
- Platform configuration (DataScienceCluster, DSCInitialization)

### Security Posture

- **Non-root**: Runs as user 2000 (non-root)
- **FIPS-compliant**: Built with CGO_ENABLED=1, strict FIPS mode
- **Base image**: Red Hat UBI9 minimal
- **TLS certificates**: Auto-rotated by OpenShift Service CA
- **Leader election**: Enabled for high availability
- **Resource limits**: CPU: 10m-500m, Memory: 64Mi-2Gi
- **Label-based caching**: Reduces memory footprint for Secrets and Pods

### Configuration Flexibility

**Environment Variables**:
- `NIM_STATE`: managed/removed (enable/disable NIM controller)
- `KSERVE_STATE`: replace (KServe integration state)
- `MODELREGISTRY_STATE`: replace (Model registry integration state)
- `ENABLE_WEBHOOKS`: true/false (enable/disable webhook server)
- `MR_SKIP_TLS_VERIFY`: false/true (skip TLS verification for model registry)

## Updating Diagrams

To regenerate diagrams after architecture changes:

```bash
# From repository root
python scripts/generate_diagram_pngs.py architecture/rhoai-3.0/diagrams --width=3000
```

Or regenerate from source architecture markdown:
```bash
# (Assuming you have a diagram generation tool configured)
./generate-architecture-diagrams --architecture=architecture/rhoai-3.0/odh-model-controller.md
```

## Related Documentation

- Architecture Source: [odh-model-controller.md](../odh-model-controller.md)
- Repository: https://github.com/red-hat-data-services/odh-model-controller
- Branch: rhoai-3.0
- Version: 1.27.0-rhods-1087-ga27ba4e

## Notes

- The controller creates Routes, NetworkPolicies, ServiceMonitors, etc. **for** InferenceServices, but does not expose itself externally
- Metrics endpoint migration from HTTP/8080 to HTTPS/8443 is planned
- Model Registry integration is optional and configurable
- NIM functionality can be completely disabled via environment variable
- Controller supports both Istio-based (EnvoyFilter) and Gateway API-based (HTTPRoute) ingress patterns
- All builds are FIPS-compliant with Go strict FIPS runtime mode
