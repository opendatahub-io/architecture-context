# Kubeflow (ODH Notebook Controller) - Architecture Diagrams

**Source**: `architecture/rhoai-2.12/kubeflow.md`
**Generated**: 2026-03-15
**Component**: kubeflow (derived from filename)

**Purpose**: Extends Kubeflow Notebooks with OpenShift-specific capabilities including OAuth authentication, route-based ingress, and network isolation.

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Shows controller components, created resources, and notebook pod structure
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Notebook creation and access flows (OAuth and non-OAuth modes)
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - External and internal dependencies

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context showing ODH Notebook Controller in the broader ecosystem
- [Component Overview](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology with trust zones
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions and OAuth authorization flow

## Component Summary

**Repository**: https://github.com/red-hat-data-services/kubeflow
**Version**: v1.27.0-rhods-327-gc9976e28
**Branch**: rhoai-2.12

### Key Features
- **OAuth Proxy Injection**: Automatic injection of OAuth proxy sidecar for authenticated notebook access
- **OpenShift Route Management**: Automatic creation of Routes for external notebook access
- **Network Policy Enforcement**: Pod-level network isolation with ingress policies
- **CA Bundle Management**: Merges trusted CA certificates for notebook containers
- **ImageStream Resolution**: Resolves ImageStream references to container image digests
- **Reconciliation Lock**: Prevents premature notebook pod start until setup is complete

### Architecture Components
- **OpenshiftNotebookReconciler**: Controller that reconciles Notebook CRs and creates supporting resources
- **NotebookWebhook**: Mutating webhook that injects OAuth proxy and CA bundles
- **Manager Deployment**: Hosts the controller and webhook server
- **OAuth Proxy Sidecar**: Provides authentication and authorization for notebook access

### Created Resources (per notebook)
- ServiceAccount: `{notebook-name}-sa`
- Service: `{notebook-name}-tls` (443:8443/TCP HTTPS)
- Secrets: OAuth config and TLS certificate
- Route: `{notebook-name}` (443/TCP HTTPS, Reencrypt or Edge)
- NetworkPolicies: `{notebook-name}-ctrl-np` and `{notebook-name}-oauth-np`
- ConfigMap: `workbench-trusted-ca-bundle` (merged CA certificates)

## Diagram Details

### Component Structure Diagram
Shows the internal architecture of the ODH Notebook Controller:
- **Controller components**: OpenshiftNotebookReconciler, NotebookWebhook, Manager Deployment
- **Watched CRDs**: notebooks.kubeflow.org/v1 (watched, not owned)
- **Created resources**: ServiceAccounts, Services, Secrets, Routes, NetworkPolicies, ConfigMaps
- **Notebook pod structure**: OAuth proxy sidecar and notebook container
- **External dependencies**: Kubernetes API, OpenShift Router, OAuth Server, Service CA, ImageStream API
- **Internal dependencies**: Kubeflow Notebook Controller, ODH Operator

### Data Flow Diagram
Illustrates four key flows:

1. **Notebook Creation (OAuth Enabled)**:
   - User creates Notebook CR → Webhook mutates (inject OAuth proxy) → Controller creates supporting resources → Pod starts

2. **Notebook Access (OAuth Enabled)**:
   - User browser → OpenShift Router → OAuth proxy → OpenShift OAuth login → SubjectAccessReview → Notebook container

3. **Notebook Access (Non-OAuth)**:
   - User browser → OpenShift Router → Notebook container (direct, no auth)

4. **Webhook Admission**:
   - Kubernetes API → Webhook → ImageStream resolution → Mutated Notebook spec

### Security Network Diagram
Detailed network topology with precise security information:
- **Ports and protocols**: Exact port numbers (8443/TCP, 6443/TCP, 443/TCP, 8888/TCP)
- **Encryption**: TLS versions (TLS 1.2+, TLS 1.3), mTLS, or plaintext (localhost only)
- **Authentication**: ServiceAccount tokens, mTLS certificates, OAuth 2.0, Bearer tokens
- **Trust boundaries**: External, Ingress (DMZ), Controller namespace, User namespace
- **RBAC details**: ClusterRoles, Roles, permissions, OAuth SubjectAccessReview
- **Secrets and certificates**: TLS cert provisioning, auto-rotation (~1 year), certificate sources (Service CA)
- **Network policies**: Ingress rules for controller and OAuth proxy access

Available in three formats:
- **ASCII (.txt)**: Precise text format for Security Architecture Reviews
- **Mermaid (.mmd)**: Visual diagram with trust zones (editable)
- **PNG**: High-resolution image for presentations

### C4 Context Diagram
System context view showing:
- **Actors**: Data Scientists
- **ODH Notebook Controller containers**: OpenshiftNotebookReconciler, NotebookWebhook, Manager
- **External OpenShift systems**: Router, OAuth Server, Service CA, ImageStream API
- **Core Kubernetes systems**: Kubernetes API Server
- **Internal ODH systems**: Kubeflow Notebook Controller, ODH Operator, Prometheus
- **Relationships**: API calls, watches, authentication flows, metric exports, CA bundle management

### Dependencies Diagram
Comprehensive dependency graph:
- **External OpenShift dependencies** (required):
  - OpenShift Router API (route.openshift.io/v1)
  - OpenShift Service CA (cert provisioning via annotation)
  - OpenShift OAuth Server (OAuth 2.0 authentication)
  - OpenShift Config API (cluster proxy configuration)
  - ImageStream API (image reference resolution)
- **Core Kubernetes dependencies** (required):
  - Kubernetes API 1.29.0+
  - NetworkPolicy API (networking.k8s.io/v1)
- **Internal ODH dependencies** (required):
  - Kubeflow Notebook Controller (creates StatefulSets, shares Notebook CRD)
  - ODH Operator (provides odh-trusted-ca-bundle ConfigMap)
- **Integration points** (optional):
  - ODH Dashboard (UI for managing notebooks)
  - Data Science Pipelines (auto-deploy models)
- **Observability**: Prometheus (metrics export on HTTP/8080)
- **External services**: Container registries (registry.redhat.io, quay.io)
- **Runtime dependencies**: OAuth Proxy Sidecar (ose-oauth-proxy, injected into notebook pods)

### RBAC Diagram
Visual representation of RBAC configuration:
- **Service Accounts**:
  - `odh-notebook-controller-manager` (controller namespace)
  - `{notebook-name}-sa` (per notebook, user namespace)
- **ClusterRoles**:
  - `manager-role` - Full controller permissions
  - `notebooks-view` - Read-only notebook access (aggregates to view role)
  - `notebooks-edit` - Full notebook CRUD (aggregates to edit role)
- **Roles** (namespaced):
  - `leader-election-role` - Leader election for HA
- **ClusterRole Bindings**:
  - `manager-rolebinding` - Binds odh-notebook-controller-manager SA to manager-role
- **Role Bindings** (namespaced):
  - `leader-election-rolebinding` - Binds to leader-election-role
- **Permissions**:
  - Notebook CRD: get, list, watch, patch, update (controller), get, list, watch (view), full CRUD (edit)
  - Routes: get, list, watch, create, update, patch
  - Services, ServiceAccounts, Secrets, ConfigMaps: get, list, watch, create, update, patch
  - NetworkPolicies: get, list, watch, create, update, patch
  - Proxies (config.openshift.io): get, list, watch
  - Leader election resources: ConfigMaps, Leases, Events
- **OAuth Authorization** (runtime):
  - OAuth proxy performs SubjectAccessReview (SAR)
  - Checks if user can GET notebooks.kubeflow.org/{notebook-name}
  - Enforced via OpenShift RBAC (notebooks-view/edit roles)

## Key Security Features

### Authentication Mechanisms
- **Controller → Kubernetes API**: ServiceAccount token (JWT)
- **Kubernetes API → Webhook**: mTLS (mutual TLS) with API server client certificate
- **User → Notebook (OAuth mode)**: OpenShift OAuth 2.0 + Bearer token + SubjectAccessReview
- **User → Notebook (Non-OAuth)**: None (public access, no authentication)

### Authorization
- **Controller actions**: RBAC via manager-role ClusterRole
- **User notebook access**: OpenShift RBAC enforced via SubjectAccessReview
  - Required permission: `get` on `notebooks.kubeflow.org/{notebook-name}`
  - Typically granted via notebooks-view or notebooks-edit ClusterRoles
  - Example: User must be able to run `oc get notebook {notebook-name} -n {namespace}`

### Network Isolation
- **NetworkPolicy: {notebook-name}-ctrl-np**:
  - Pod Selector: `notebook-name={notebook-name}`
  - Ingress From: Namespace with label `kubernetes.io/metadata.name={controller-namespace}`
  - Ingress Port: 8888/TCP
  - Purpose: Allow controller namespace to access notebook application port
- **NetworkPolicy: {notebook-name}-oauth-np**:
  - Pod Selector: `notebook-name={notebook-name}`
  - Ingress From: All (empty array)
  - Ingress Port: 8443/TCP
  - Purpose: Allow external access to OAuth proxy port
- **Egress**: Unrestricted (no egress policies defined)

### TLS/Encryption
- **External access**: TLS 1.3 (OpenShift Router)
- **Webhook server**: TLS 1.2+ with mTLS (Kubernetes API to webhook)
- **OAuth proxy**: TLS 1.2+ (Router to OAuth proxy sidecar via Reencrypt termination)
- **Notebook backend**: HTTP/8888 (localhost only, no encryption needed)
- **Controller API calls**: TLS 1.2+ (all Kubernetes and OpenShift API calls)

### Certificate Management
- **Webhook server certificate**:
  - Secret: `odh-notebook-controller-webhook-cert`
  - Type: kubernetes.io/tls
  - Provisioned by: OpenShift Service CA (via service.beta.openshift.io/serving-cert-secret-name annotation)
  - Auto-rotation: Yes (~1 year rotation period)
- **OAuth proxy certificate** (per notebook):
  - Secret: `{notebook-name}-tls`
  - Type: kubernetes.io/tls
  - Provisioned by: OpenShift Service CA
  - Auto-rotation: Yes
- **OAuth cookie secret** (per notebook):
  - Secret: `{notebook-name}-oauth-config`
  - Type: Opaque
  - Provisioned by: ODH Notebook Controller (random base64 string)
  - Auto-rotation: No (static per notebook)
- **CA bundles**:
  - Sources: `odh-trusted-ca-bundle` (ODH Operator) + `kube-root-ca.crt` (Kubernetes)
  - Merged into: `workbench-trusted-ca-bundle` ConfigMap
  - Mounted to: `/etc/pki/tls/custom-certs/ca-bundle.crt`
  - Environment variables: PIP_CERT, REQUESTS_CA_BUNDLE, SSL_CERT_FILE, PIPELINES_SSL_SA_CERTS, GIT_SSL_CAINFO

## Special Features

### ImageStream Resolution
The webhook resolves ImageStream references to actual container image digests:
- Checks annotation `notebooks.opendatahub.io/last-image-selection` for `imagestream:tag` format
- Queries OpenShift ImageStream API in `opendatahub` and `redhat-ods-applications` namespaces
- Extracts `status.tags[].items[].dockerImageReference` from matching ImageStream
- Updates notebook container image to use digest reference
- Falls back to internal registry if detected: `image-registry.openshift-image-registry.svc:5000`

### Reconciliation Lock
The webhook injects a reconciliation lock annotation on notebook creation:
- Annotation: `kubeflow.org/last-applied-stop-annotation: odh-notebook-controller-lock`
- Prevents Kubeflow controller from starting the notebook pod prematurely
- Allows ODH controller to complete setup (ServiceAccount with ImagePullSecrets)
- Controller removes lock after verifying ServiceAccount has ImagePullSecrets mounted
- Uses exponential backoff: 3 steps, 1s initial, 5.0x factor

### Leader Election
Controller supports leader election for high availability:
- Uses `coordination.k8s.io/v1` Lease resource
- Lease name: `odh-notebook-controller`
- Configured via `--leader-elect` flag (default: false)
- Ensures only one active controller instance at a time

## Known Limitations

1. **No CRD Ownership**: This controller does not own the Notebook CRD; it's managed by Kubeflow Notebook Controller
2. **OpenShift Specific**: Requires OpenShift APIs (Route, OAuth, Service CA) - not portable to vanilla Kubernetes
3. **Namespace Assumptions**: Falls back to `redhat-ods-applications` namespace for controller namespace detection
4. **ImageStream Namespaces**: Only searches `opendatahub` and `redhat-ods-applications` namespaces for ImageStreams
5. **No Egress NetworkPolicy**: Only ingress policies are created; egress is unrestricted

## Observability

### Metrics
- Exposed on port 8080 at `/metrics`
- Standard controller-runtime metrics (reconciliation, queue depth, etc.)
- Prometheus format
- Service: `odh-notebook-controller-service` (ClusterIP, internal only)

### Health Checks
- **Liveness**: `/healthz` on port 8081 (initial delay: 15s, period: 20s)
- **Readiness**: `/readyz` on port 8081 (initial delay: 5s, period: 10s)

### Logging
- Structured logging via zap logger
- Log levels: info, debug (via `--debug-log` flag)
- Time format: RFC3339
- Context: includes notebook name and namespace

## How to Use These Diagrams

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kubeflow-component.mmd -o kubeflow-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kubeflow-component.mmd -o kubeflow-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kubeflow-component.mmd -o kubeflow-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace kubeflow-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details, no ambiguity)

## Updating Diagrams

To regenerate after architecture changes:

```bash
# Regenerate PNGs from Mermaid diagrams
cd architecture/rhoai-2.12
python ../../scripts/generate_diagram_pngs.py diagrams --width=3000

# Or regenerate all diagrams from architecture markdown
/generate-architecture-diagrams --architecture=kubeflow.md
```

## Related Documentation

- **Architecture File**: [../kubeflow.md](../kubeflow.md)
- **Main Diagrams README**: [README.md](./README.md) (index of all RHOAI 2.12 component diagrams)
- **Repository**: https://github.com/red-hat-data-services/kubeflow
- **Version**: v1.27.0-rhods-327-gc9976e28
- **Branch**: rhoai-2.12
