# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-453-g5a5992d
- **Branch**: rhoai-2.12
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Extends KServe InferenceService functionality with OpenShift and service mesh integration capabilities.

**Detailed**: The ODH Model Controller is a Kubernetes operator that watches KServe InferenceService custom resources and extends their behavior with OpenShift-specific capabilities. It creates OpenShift Routes for external access to inference services, manages Istio service mesh resources (VirtualServices, Gateways, PeerAuthentication, Telemetry), configures authentication through Authorino AuthConfigs, and integrates with Prometheus for monitoring. The controller supports three deployment modes: ModelMesh for multi-model serving, KServe Serverless (using Knative), and KServe RawDeployment. It also manages storage secrets, custom CA certificates, network policies, and provides serving runtime templates for popular inference frameworks (OVMS, Caikit, TGIS, vLLM).

The controller includes a validating webhook for Knative Services to ensure proper configuration when KServe Serverless mode is enabled with service mesh integration. It reconciles resources across namespaces and coordinates with the service mesh control plane to provide secure, monitored, and externally accessible inference endpoints.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Reconciler | Controller | Main reconciler watching KServe InferenceServices, delegates to mode-specific reconcilers (ModelMesh, Serverless, RawDeployment) |
| ModelMesh Reconciler | Sub-reconciler | Handles InferenceServices in ModelMesh deployment mode (multi-model serving) |
| KServe Serverless Reconciler | Sub-reconciler | Handles InferenceServices in Serverless mode using Knative Serving |
| KServe Raw Reconciler | Sub-reconciler | Handles InferenceServices in RawDeployment mode (direct Kubernetes deployments) |
| Storage Secret Reconciler | Controller | Manages storage configuration secrets for InferenceServices |
| Custom CA Cert Reconciler | Controller | Reconciles custom CA certificate bundles for KServe |
| Monitoring Reconciler | Controller | Creates ServiceMonitors and PodMonitors for Prometheus integration |
| Model Registry Reconciler | Controller | Optional reconciler for model registry integration (flag-enabled) |
| Knative Service Validator | Webhook | Validating webhook for Knative Services when service mesh is enabled |
| Route Reconciler | Sub-reconciler | Creates and manages OpenShift Routes for external access |
| VirtualService Reconciler | Sub-reconciler | Creates and manages Istio VirtualServices for mesh routing |
| Gateway Reconciler | Sub-reconciler | Configures Istio Gateways for inference service traffic |
| AuthConfig Reconciler | Sub-reconciler | Manages Authorino AuthConfigs for authentication |
| PeerAuthentication Reconciler | Sub-reconciler | Configures Istio mTLS policies |
| ServiceMeshMember Reconciler | Sub-reconciler | Adds namespaces to service mesh |
| NetworkPolicy Reconciler | Sub-reconciler | Creates network policies for inference services |
| Telemetry Reconciler | Sub-reconciler | Configures Istio telemetry collection |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This controller does not define its own CRDs but watches and reconciles external CRDs:

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource watched - defines ML model serving instances |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines inference runtime configurations (watched and created) |
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Model predictor definitions (external CRD) |
| route.openshift.io | v1 | Route | Namespaced | OpenShift routes for external access (created/managed) |
| networking.istio.io | v1beta1 | VirtualService | Namespaced | Istio routing rules (created/managed) |
| networking.istio.io | v1beta1 | Gateway | Namespaced | Istio gateway configuration (updated) |
| security.istio.io | v1beta1 | PeerAuthentication | Namespaced | Istio mTLS policies (created/managed) |
| security.istio.io | v1beta1 | AuthorizationPolicy | Namespaced | Istio authorization policies (read only) |
| telemetry.istio.io | v1alpha1 | Telemetry | Namespaced | Istio telemetry configuration (created/managed) |
| maistra.io | v1 | ServiceMeshMember | Namespaced | Service mesh membership (created/managed) |
| maistra.io | v1 | ServiceMeshMemberRoll | Namespaced | Service mesh member list (read only) |
| maistra.io | v2 | ServiceMeshControlPlane | Namespaced | Service mesh control plane (read/use) |
| authorino.kuadrant.io | v1beta2 | AuthConfig | Namespaced | Authorino authentication configuration (created/managed) |
| monitoring.coreos.com | v1 | ServiceMonitor | Namespaced | Prometheus service monitoring (created/managed) |
| monitoring.coreos.com | v1 | PodMonitor | Namespaced | Prometheus pod monitoring (created/managed) |
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | ODH platform configuration (read only) |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | ODH initialization config (read only) |
| serving.knative.dev | v1 | Service | Namespaced | Knative serving services (validated via webhook) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | ServiceAccount Token | Prometheus metrics endpoint for controller metrics |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe for controller health |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe for controller readiness |
| /validate-serving-knative-dev-v1-service | POST | 9443/TCP | HTTPS | TLS 1.2+ | Kubernetes API | Validating webhook for Knative Services |

### Webhook Services

| Webhook Type | Service | Port | Protocol | Encryption | Resources Validated |
|--------------|---------|------|----------|------------|---------------------|
| ValidatingWebhook | odh-model-controller-webhook-service | 443/TCP | HTTPS | TLS (service-ca) | serving.knative.dev/v1/Service (CREATE) |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Kubernetes | v1.28+ | Yes | Kubernetes API and controller runtime |
| KServe | v0.12.1 | Yes | Provides InferenceService and ServingRuntime CRDs |
| OpenShift | v4.x | Yes | Route API for external access |
| Istio/Maistra | v1.19+ | Conditional | Service mesh integration (if mesh enabled) |
| Knative Serving | v0.39.3 | Conditional | Serverless inference mode |
| Authorino | v0.15.0 | Conditional | Authentication/authorization (if mesh enabled) |
| Prometheus Operator | v0.64.1+ | Conditional | Monitoring integration (if monitoring namespace provided) |
| cert-manager / service-ca | - | Yes | TLS certificates for webhook |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD | Reads DataScienceCluster and DSCInitialization to determine enabled components |
| kserve-controller | CRD | Works alongside KServe controller, watches same InferenceService resources |
| model-registry | CRD/API | Optional integration with model registry (flag-enabled) |
| Service Mesh Control Plane | API | Interacts with Maistra/Istio control plane for mesh configuration |
| Authorino | CRD | Creates AuthConfigs for inference service authentication |
| Prometheus | ServiceMonitor | Exposes metrics and creates monitoring resources |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | ServiceAccount Token | Internal |
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 (webhook-server) | HTTPS | TLS (service-ca) | Kubernetes API | Internal |

### Ingress

This controller does not consume ingress but creates ingress resources for InferenceServices:

| Resource Type | Created For | Port | Protocol | Encryption | Purpose |
|---------------|-------------|------|----------|------------|---------|
| OpenShift Route | InferenceService | 443/TCP | HTTPS | TLS passthrough/edge | External access to inference endpoints |
| Istio VirtualService | InferenceService | 8080,8443/TCP | HTTP/HTTPS | TLS (mesh mTLS) | Service mesh routing |
| Istio Gateway | InferenceService (shared) | 8080,8443/TCP | HTTP/HTTPS | TLS | Ingress gateway configuration |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and reconcile CRDs |
| Istio Control Plane | 15012/TCP | gRPC | mTLS | ServiceAccount | Service mesh configuration |
| Prometheus | 9090/TCP | HTTP | None | ServiceAccount Token | Metrics scraping (via ServiceMonitor) |
| Model Registry | 8080/TCP | HTTP | None | ServiceAccount Token | Optional model registry integration |

### Network Policies

| Policy Name | Selectors | Ingress Rules | Egress Rules |
|-------------|-----------|---------------|--------------|
| odh-model-controller | app=odh-model-controller, control-plane=odh-model-controller | Allow 9443/TCP from any | Not restricted |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | "" | configmaps, secrets, serviceaccounts | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | "" | endpoints, namespaces, pods | create, get, list, patch, update, watch |
| odh-model-controller-role | "" | services | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices | get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices/finalizers | get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes | create, get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | virtualservices | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | virtualservices/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | gateways | get, list, patch, update, watch |
| odh-model-controller-role | security.istio.io | peerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | security.istio.io | authorizationpolicies | get, list |
| odh-model-controller-role | telemetry.istio.io | telemetries | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshmembers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshmemberrolls | get, list, watch |
| odh-model-controller-role | maistra.io | servicemeshcontrolplanes | get, list, use, watch |
| odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | ingresses | get, list, watch |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | extensions | ingresses | get, list, watch |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| kserve-prometheus-clusterrole | "" | namespaces | get |
| auth-proxy-role | authentication.k8s.io | tokenreviews | create |
| auth-proxy-role | authorization.k8s.io | subjectaccessreviews | create |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding | - (Cluster) | odh-model-controller-role (ClusterRole) | odh-model-controller |
| odh-model-controller-auth-proxy-rolebinding | - (Cluster) | auth-proxy-role (ClusterRole) | odh-model-controller |
| odh-model-controller-leader-election-rolebinding | controller namespace | leader-election-role (Role) | odh-model-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for validating webhook | service-ca-operator | Yes |
| auth-refs | Opaque (ConfigMap) | Authorino authentication references (optional) | ODH Operator | No |
| service-mesh-refs | Opaque (ConfigMap) | Service mesh configuration references (optional) | ODH Operator | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | ServiceMonitor | Prometheus scraper identity |
| /healthz, /readyz | GET | None | None | Public health endpoints |
| /validate-serving-knative-dev-v1-service | POST | Kubernetes API authentication | API Server | Webhook called by API server |

### Pod Security

| Setting | Value | Purpose |
|---------|-------|---------|
| runAsNonRoot | true | Prevents running as root user |
| allowPrivilegeEscalation | false | Prevents privilege escalation |
| User | 65532:65532 | Non-root user in container |
| securityContext | restricted | Follows restricted pod security standards |

## Data Flows

### Flow 1: InferenceService Creation (ModelMesh Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/KServe | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | OIDC/ServiceAccount |
| 2 | Kubernetes API | odh-model-controller | - | Event | N/A | Controller Cache |
| 3 | odh-model-controller | Kubernetes API (Route) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-model-controller | Kubernetes API (Service) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | odh-model-controller | Kubernetes API (ServiceAccount) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | odh-model-controller | Kubernetes API (ClusterRoleBinding) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: InferenceService Creation (KServe Serverless Mode with Service Mesh)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/KServe | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | OIDC/ServiceAccount |
| 2 | Kubernetes API | odh-model-controller | - | Event | N/A | Controller Cache |
| 3 | odh-model-controller | Kubernetes API (Route) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-model-controller | Kubernetes API (VirtualService) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | odh-model-controller | Kubernetes API (Gateway update) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | odh-model-controller | Kubernetes API (ServiceMeshMember) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | odh-model-controller | Kubernetes API (PeerAuthentication) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 8 | odh-model-controller | Kubernetes API (Telemetry) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 9 | odh-model-controller | Kubernetes API (AuthConfig) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 10 | odh-model-controller | Kubernetes API (NetworkPolicy) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Monitoring Integration

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | odh-model-controller | Kubernetes API (ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | odh-model-controller | Kubernetes API (PodMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Prometheus | odh-model-controller | 8080/TCP | HTTPS | TLS (internal CA) | Bearer Token |

### Flow 4: Knative Service Validation (Webhook)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | OIDC/ServiceAccount |
| 2 | Kubernetes API | odh-model-controller-webhook-service | 443/TCP | HTTPS | TLS (service-ca) | Kubernetes API |
| 3 | odh-model-controller | Kubernetes API (validation response) | - | Response | TLS (service-ca) | Webhook Response |

### Flow 5: Storage Secret Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (Secret with storage config) | 6443/TCP | HTTPS | TLS 1.2+ | OIDC/ServiceAccount |
| 2 | Kubernetes API | odh-model-controller | - | Event | N/A | Controller Cache |
| 3 | odh-model-controller | Kubernetes API (ServiceAccount) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | odh-model-controller | Kubernetes API (Secret mount) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Watch and update InferenceService resources |
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.2+ | CRUD operations on all managed resources |
| Istio Control Plane | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Create/manage VirtualServices, Gateways, PeerAuthentication |
| Maistra Service Mesh | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Create ServiceMeshMembers, read ServiceMeshMemberRolls |
| OpenShift Router | Route CRD | 6443/TCP | HTTPS | TLS 1.2+ | Create/manage Routes for external access |
| Authorino | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Create/manage AuthConfigs for authentication |
| Prometheus Operator | ServiceMonitor CRD | 6443/TCP | HTTPS | TLS 1.2+ | Create ServiceMonitors and PodMonitors |
| Knative Serving | Webhook Validation | 9443/TCP | HTTPS | TLS (service-ca) | Validate Knative Service resources |
| Model Registry | API/CRD | 8080/TCP | HTTP | None | Optional integration when flag enabled |
| ODH Operator | CRD Read | 6443/TCP | HTTPS | TLS 1.2+ | Read DataScienceCluster/DSCInitialization config |

## Deployment Configuration

### Container Image
- **Build**: Multi-stage build using UBI9 Go 1.21 toolset
- **Base**: UBI8 minimal (ubi8/ubi-minimal:8.6)
- **User**: 65532:65532 (non-root)

### Deployment Settings
- **Replicas**: 3 (with pod anti-affinity for high availability)
- **Leader Election**: Enabled (--leader-elect flag)
- **Anti-Affinity**: Preferred scheduling on different nodes

### Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 10m | 500m |
| Memory | 64Mi | 2Gi |

### Environment Variables

| Variable | Source | Required | Purpose |
|----------|--------|----------|---------|
| POD_NAMESPACE | fieldRef | Yes | Current pod namespace |
| AUTH_AUDIENCE | ConfigMap (auth-refs) | No | Authorino audience configuration |
| AUTHORINO_LABEL | ConfigMap (auth-refs) | No | Authorino label selector |
| CONTROL_PLANE_NAME | ConfigMap (service-mesh-refs) | No | Service mesh control plane name |
| MESH_NAMESPACE | ConfigMap (service-mesh-refs) | No | Service mesh namespace |
| MESH_DISABLED | Environment | No | Disable mesh integration (default: false) |

### Command Line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Metrics endpoint address |
| --health-probe-bind-address | :8081 | Health probe endpoint address |
| --leader-elect | false | Enable leader election |
| --monitoring-namespace | "" | Namespace where Prometheus resides |
| --model-registry-inference-reconcile | false | Enable model registry integration |

## Serving Runtime Templates

The controller deploys the following serving runtime templates:

| Runtime | Template File | Purpose |
|---------|--------------|---------|
| OpenVINO Model Server (KServe) | ovms-kserve-template.yaml | Intel OpenVINO inference runtime for KServe |
| OpenVINO Model Server (ModelMesh) | ovms-mm-template.yaml | Intel OpenVINO inference runtime for ModelMesh |
| Caikit-TGIS | caikit-tgis-template.yaml | Caikit NLP with Text Generation Inference Server |
| Caikit Standalone | caikit-standalone-template.yaml | Standalone Caikit runtime |
| TGIS | tgis-template.yaml | Text Generation Inference Server |
| vLLM | vllm-template.yaml | vLLM (very Large Language Model) inference |

## Recent Changes

Based on git commit history (branch: rhoai-2.12):

| Commit | Date | Changes |
|--------|------|---------|
| 5a5992d | 1 year, 7 months ago | Update latest SHA |
| adea3cb | 1 year, 7 months ago | Merge pull request #105: Konflux component updates for caikit-nlp-212 |
| 0cc76d0 | 1 year, 7 months ago | Update caikit-nlp-212 to bbcc072 |
| 0911093 | 1 year, 7 months ago | Merge pull request #104: Konflux component updates for caikit-nlp-212 |
| e3d3190 | 1 year, 7 months ago | Update caikit-nlp-212 to c9c241a |
| 1d1f5aa | 1 year, 7 months ago | Merge pull request #103: Update OVMS runtime |
| d395f7b | 1 year, 7 months ago | Merge changes of PR 101 |
| ef82c49 | 1 year, 7 months ago | Reset OVMS image reference to 2.11 build |
| 2919a63 | 1 year, 7 months ago | Merge pull request #100: vLLM image update for 2.12 |
| 5d5d474 | 1 year, 7 months ago | Modify vLLM image |
| f379400 | 1 year, 7 months ago | Merge pull request #96: Update OVMS SHA |
| 8d79b2b | 1 year, 7 months ago | Upgrade OVMS image SHA |
| cd10628 | 1 year, 7 months ago | Update caikit-nlp-212 to aa02f33 |
| 7593a61 | 1 year, 7 months ago | Update caikit-tgis image SHA to rhoai-2.12-7c416ec |
| e01edbc | 1 year, 7 months ago | Merge remote-tracking branch 'upstream/main' into rhoai-2.12 |
| eabc133 | 1 year, 7 months ago | Merge remote-tracking branch 'upstream/release-0.12.0' |
| ed6b135 | 1 year, 7 months ago | Merge pull request #246: KServe metrics checkpoint |

**Note**: This branch appears to be a stable RHOAI 2.12 release branch with minimal recent activity, primarily focused on serving runtime image updates (Caikit, OVMS, vLLM, TGIS).

## Key Design Patterns

### Multi-Mode Reconciliation
The controller implements a strategy pattern with three reconciliation modes:
- **ModelMesh**: Traditional multi-model serving with shared model servers
- **Serverless**: Knative-based auto-scaling inference services
- **RawDeployment**: Direct Kubernetes deployment without Knative

### Resource Ownership
The controller uses Kubernetes owner references to manage lifecycle:
- InferenceService owns: Routes, VirtualServices, Secrets, ConfigMaps, Services, NetworkPolicies, ServiceMonitors, PodMonitors
- Automatic garbage collection when InferenceService is deleted

### Conditional Feature Activation
Features are conditionally enabled based on:
- Service mesh detection (checks DataScienceCluster/DSCInitialization)
- AuthConfig CRD availability
- Command-line flags (monitoring namespace, model registry)
- Environment variables (MESH_DISABLED)

### Cross-Namespace Resource Management
The controller manages resources across multiple namespaces:
- InferenceService namespace (primary resources)
- Monitoring namespace (ServiceMonitors when configured)
- Service mesh namespace (mesh membership)

## Operational Considerations

### High Availability
- 3 replicas with leader election
- Pod anti-affinity for distribution across nodes
- Only one replica actively reconciles (leader) at a time

### Monitoring
- Exposes Prometheus metrics on :8080/metrics
- Creates ServiceMonitor for self-monitoring
- Creates PodMonitor and ServiceMonitor for InferenceServices

### Security Hardening
- Runs as non-root user (65532)
- No privilege escalation
- Restrictive pod security context
- TLS for all webhook communication
- Service-CA managed certificates

### Troubleshooting
- Health probes: /healthz (liveness), /readyz (readiness) on port 8081
- Structured logging with contextual information
- Finalizers for cleanup on resource deletion
