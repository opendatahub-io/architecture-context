# Component: odh-model-controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller
- **Version**: v1.27.0-rhods-153-ga294986
- **Branch**: rhoai-2.6
- **Distribution**: RHOAI
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Extends KServe InferenceService with OpenShift-specific networking, monitoring, and security capabilities.

**Detailed**: The odh-model-controller is a Kubernetes operator that watches KServe InferenceService resources and automatically provisions OpenShift-native infrastructure to enable external access, monitoring, and secure communication. It bridges the gap between KServe's model serving capabilities and OpenShift's enterprise features by creating OpenShift Routes for external ingress, integrating with OpenShift Service Mesh (Maistra) for service-to-service security, configuring Prometheus monitoring, and establishing network policies. The controller supports both KServe Serverless (Knative) and ModelMesh deployment modes, applying different reconciliation logic based on the deployment mode detected in each InferenceService. It also manages storage configuration secrets by aggregating data connection credentials from the ODH dashboard into a unified storage-config secret that KServe can consume.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| OpenshiftInferenceServiceReconciler | Controller | Main reconciliation loop that watches InferenceService CRDs and delegates to mode-specific reconcilers |
| KserveInferenceServiceReconciler | Reconciler | Manages OpenShift/Istio resources for KServe Serverless InferenceServices |
| ModelMeshInferenceServiceReconciler | Reconciler | Manages OpenShift resources for ModelMesh InferenceServices |
| StorageSecretReconciler | Controller | Aggregates data connection secrets into storage-config secret for S3/object storage access |
| MonitoringReconciler | Controller | Creates RoleBindings to grant Prometheus access to namespaces with InferenceServices |
| Manager Pod | Deployment | Runs controller manager with 3 replicas and leader election |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This controller does not define its own CRDs. It watches external CRDs:

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary watched resource for model serving deployments |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Runtime configuration for serving models (read to find runtime ports) |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics scraping |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

None exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.11.0 | Yes | Provides InferenceService and ServingRuntime CRDs |
| OpenShift Service Mesh (Maistra) | v1+ | No | Service mesh integration for mTLS and traffic management |
| Prometheus Operator | v0.64.1 | No | Monitoring integration via ServiceMonitor/PodMonitor |
| Knative Serving | v0.39.3 | No | Required for KServe Serverless mode (not ModelMesh) |
| Istio | v1.17.4 | No | Service mesh for networking and security |
| OpenShift Routes API | v3.9.0+ | Yes | External ingress for InferenceServices |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Dashboard | Secret Labels | Watches secrets with labels `opendatahub.io/managed: true` and `opendatahub.io/dashboard: true` for storage configuration |
| KServe Controller | CRD Watch | Watches InferenceService CRDs created by KServe |
| OpenShift Monitoring Stack | RoleBinding | Creates RoleBindings to grant prometheus-custom SA access to namespaces |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

Note: The controller creates additional Services for each InferenceService (e.g., `{isvc-name}-metrics` on port 8080/TCP).

### Ingress

The controller creates OpenShift Routes for each InferenceService:

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name} (KServe) | Route | Auto-generated | 443/TCP | HTTPS | TLS Edge | SIMPLE | External |
| {isvc-name} (ModelMesh) | Route | Auto-generated | 443/TCP | HTTPS | TLS Edge | SIMPLE | External |

### Egress

The controller does not make direct egress connections. InferenceServices may require egress to:

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3/Object Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 | Model artifact download |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | "" | configmaps, endpoints, namespaces, pods, secrets, serviceaccounts, services | create, get, list, patch, update, watch |
| odh-model-controller-role | apps | deployments, statefulsets | get, list, delete |
| odh-model-controller-role | project.openshift.io | projects | get |
| odh-model-controller-role | serving.kserve.io | inferenceservices | get, list, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices/finalizers | get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes | create, get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | virtualservices | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.istio.io | virtualservices/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | security.istio.io | peerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | telemetry.istio.io | telemetries | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshmembers, servicemeshmemberrolls, servicemeshcontrolplanes | create, delete, get, list, patch, update, use, watch |
| odh-model-controller-role | maistra.io | servicemeshmembers/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | ingresses | get, list, watch |
| odh-model-controller-role | extensions | ingresses | get, list, watch |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| odh-model-controller-leader-election-role | "" | configmaps | get, list, watch, create, update, patch |
| odh-model-controller-leader-election-role | "" | events | create, patch |
| odh-model-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding | (cluster-scoped) | odh-model-controller-role | odh-model-controller |
| odh-model-controller-leader-election-rolebinding | redhat-ods-applications | odh-model-controller-leader-election-role | odh-model-controller |
| prometheus-ns-access | {each isvc namespace} | prometheus-ns-access (ClusterRole) | prometheus-custom (openshift-monitoring) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| storage-config | Opaque | Aggregated S3 credentials for model storage | odh-model-controller | No |
| {data-connection-name} | Opaque | Individual S3/object storage credentials | ODH Dashboard | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None | None | Internal-only ClusterIP service |
| /healthz, /readyz | GET | None | None | Health probes from kubelet |
| InferenceService Routes | ALL | Bearer Token or mTLS | Istio VirtualService | Configured per namespace via PeerAuthentication |

### Service Mesh Security

The controller creates these Istio security resources for KServe InferenceServices:

| Resource | Type | Scope | Purpose |
|----------|------|-------|---------|
| {namespace}-peer-authn | PeerAuthentication | Namespace | Enforces PERMISSIVE or STRICT mTLS mode |
| {namespace}-metrics-telemetry | Telemetry | Namespace | Enables Prometheus metrics collection from Envoy sidecars |

### Network Policies

The controller creates NetworkPolicies for KServe InferenceServices:

| Policy Name | Namespace | Purpose |
|-------------|-----------|---------|
| allow-from-openshift-monitoring-ns | {isvc namespace} | Allow Prometheus scraping from openshift-monitoring namespace |
| allow-from-openshift-ingress | {isvc namespace} | Allow ingress from OpenShift router pods |
| allow-from-application-namespaces | {isvc namespace} | Allow traffic from namespaces with label `modelmesh-enabled=true` or `opendatahub.io/dashboard=true` |

## Data Flows

### Flow 1: External Client Request to InferenceService (KServe Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (Route-level) |
| 2 | OpenShift Router | Istio Ingress Gateway | 8080/TCP | HTTP | None | None |
| 3 | Istio Ingress Gateway | InferenceService Pod (Knative) | 8080/TCP | HTTP | mTLS (optional) | Bearer Token (optional) |
| 4 | InferenceService Pod | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 |

### Flow 2: Prometheus Metrics Scraping

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus (openshift-monitoring) | InferenceService Pods | 8080/TCP | HTTP | None | Bearer Token (SA) |
| 2 | Prometheus | Istio Envoy Sidecars | 15020/TCP | HTTP | None | Bearer Token (SA) |

### Flow 3: Storage Secret Aggregation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ODH Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | odh-model-controller | Kubernetes API (watch Secrets) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 3 | odh-model-controller | Kubernetes API (create/update storage-config) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | InferenceService Pod | Kubernetes API (mount storage-config Secret) | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.3 | Watch/reconcile resources |
| OpenShift Service Mesh Control Plane | API (maistra.io) | 6443/TCP | HTTPS | TLS 1.3 | Register namespaces in ServiceMeshMemberRoll |
| Prometheus Operator | CRD (ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.3 | Configure metrics scraping |
| KServe Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.3 | Watch InferenceService resources created by KServe |
| ODH Dashboard | Secret Labels | 6443/TCP | HTTPS | TLS 1.3 | Discover data connection secrets |

## Resources Created by Controller

### Per Namespace (KServe Mode)

| Resource Type | Name Pattern | Purpose |
|---------------|--------------|---------|
| ServiceMeshMemberRoll Entry | default (in istio-system) | Add namespace to service mesh |
| RoleBinding | prometheus-ns-access | Grant Prometheus access to namespace |
| Telemetry | {namespace}-metrics-telemetry | Enable Istio metrics collection |
| ServiceMonitor | {namespace}-istio | Scrape Istio Envoy sidecar metrics |
| PodMonitor | {namespace}-istio-pods | Scrape pod-level Istio metrics |
| PeerAuthentication | {namespace}-peer-authn | Configure mTLS mode |
| NetworkPolicy | allow-from-openshift-monitoring-ns | Allow Prometheus traffic |
| NetworkPolicy | allow-from-openshift-ingress | Allow router traffic |
| NetworkPolicy | allow-from-application-namespaces | Allow application traffic |

### Per InferenceService (KServe Mode)

| Resource Type | Name Pattern | Purpose |
|---------------|--------------|---------|
| Route | {isvc-name} | External HTTPS access |
| Service | {isvc-name}-metrics | Metrics aggregation endpoint |
| ServiceMonitor | {isvc-name} | Scrape InferenceService metrics |

### Per Namespace (ModelMesh Mode)

| Resource Type | Name Pattern | Purpose |
|---------------|--------------|---------|
| ServiceAccount | {namespace}-sa | Service account for ModelMesh pods |
| ClusterRoleBinding | {namespace}-prometheus-crb | Bind prometheus-reader role |

### Per InferenceService (ModelMesh Mode)

| Resource Type | Name Pattern | Purpose |
|---------------|--------------|---------|
| Route | {isvc-name} | External HTTPS access to ModelMesh |

### Per Namespace (All Modes)

| Resource Type | Name Pattern | Purpose |
|---------------|--------------|---------|
| Secret | storage-config | Aggregated S3 credentials from data connections |

## Deployment Configuration

### Manager Deployment

| Attribute | Value |
|-----------|-------|
| Replicas | 3 |
| Leader Election | Enabled |
| Image | controller:latest (overridden in production) |
| Resources (Requests) | CPU: 10m, Memory: 64Mi |
| Resources (Limits) | CPU: 500m, Memory: 2Gi |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false |
| Pod Anti-Affinity | Preferred (spread across nodes) |
| Health Probes | Liveness: /healthz:8081, Readiness: /readyz:8081 |

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| POD_NAMESPACE | Field Reference | Namespace where controller is deployed |
| MESH_DISABLED | Flag (default: false) | Disable service mesh integration |
| --monitoring-namespace | CLI Flag | Namespace where Prometheus is deployed (optional) |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| a294986 | 2024 | - Merge pull request for cherry-picks |
| 7c19ca9 | 2024 | - Add temporary Job to delete old monitoring stack |
| 8c98848 | 2024 | - Add back RBAC removed by linter |
| 49f5b5a | 2024 | - Fix: Add network policies to unblock traffic between components (#145) |
| 2ba1d96 | 2024 | - Revert network policy changes |
| 40917f1 | 2024 | - Cherry-pick network policy changes |
| 42330d7 | 2024 | - Fix: Stack-based Buffer Overflow on protobuf (CVE) |
| b046dfe | 2024 | - Update knative-serving dependency |
| ef22694 | 2024 | - Fix: Vulnerabilities on otelhttp dependency (CVE-2022-21698, CVE-2023-45142) |
| 45fe354 | 2024 | - Fix: CVE-2023-48795 (golang.org/x/crypto) |

### Security Fixes

- CVE-2022-21698 and CVE-2023-45142: Fixed via otelhttp dependency update
- CVE-2023-48795: Fixed golang.org/x/crypto authentication bypass
- Stack-based buffer overflow in protobuf: Updated dependency

### Functional Changes

- Network policies refined to properly allow traffic between components
- Monitoring stack cleanup job added for migration scenarios
- RBAC permissions restored after automated linter modifications

## Notes

### Deployment Modes

The controller detects the deployment mode from the InferenceService annotation:
- **KServe Serverless**: Uses Knative Serving, requires Istio for networking
- **ModelMesh**: Uses ModelMesh Serving, simpler resource model

Different reconciliation logic applies based on the detected mode.

### Monitoring Integration

The controller requires the `--monitoring-namespace` flag to be set for enabling monitoring features. If not provided, monitoring-related reconciliation is skipped.

### Service Mesh Dependency

Service mesh integration is optional and can be disabled via the `MESH_DISABLED` environment variable. When enabled, the controller:
- Adds namespaces to ServiceMeshMemberRoll
- Creates PeerAuthentication for mTLS
- Creates Telemetry for metrics collection
- Creates NetworkPolicies compatible with mesh policies

### Storage Secret Management

The controller watches for secrets labeled with:
- `opendatahub.io/managed: "true"`
- `opendatahub.io/dashboard: "true"`

It aggregates these into a single `storage-config` secret that follows the KServe/ModelMesh storage configuration format, supporting:
- AWS S3 (access key, secret key, endpoint, bucket, region)
- Custom CA bundles for TLS verification
- Both KServe and ModelMesh key formats (dual keys for compatibility)
