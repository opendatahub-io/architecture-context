# Component: odh-model-controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-483-gea70e0a
- **Branch**: rhoai-2.14
- **Distribution**: RHOAI (also supports ODH)
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Extends KServe InferenceService functionality with OpenShift integration, service mesh, authorization, and monitoring capabilities.

**Detailed**: The odh-model-controller is a Kubernetes operator built with Kubebuilder that watches KServe InferenceServices and automatically provisions OpenShift-specific resources to enable model serving in RHOAI/ODH environments. It supports multiple deployment modes including KServe Serverless (Knative), KServe RawDeployment, and ModelMesh serving. The controller creates OpenShift Routes for external access, integrates with Red Hat OpenShift Service Mesh (Istio) for traffic management and mTLS, configures Authorino for authentication and authorization, sets up Prometheus monitoring with ServiceMonitors, manages NetworkPolicies for network isolation, and handles storage configuration secrets for S3-compatible object storage. It also deploys and manages serving runtime templates for various ML frameworks including OpenVINO Model Server (OVMS), Text Generation Inference Server (TGIS), Caikit, and vLLM.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Controller | Controller | Reconciles KServe InferenceServices and creates OpenShift/mesh resources |
| StorageSecret Controller | Controller | Aggregates data connection secrets into storage config for model serving |
| KServeCustomCACert Controller | Controller | Propagates custom CA certificates to KServe deployments |
| Monitoring Controller | Controller | Sets up Prometheus monitoring for inference services |
| ModelRegistry Controller | Controller | Integrates InferenceServices with Model Registry |
| Knative Service Webhook | ValidatingWebhook | Validates Knative Service configurations for KServe |
| Metrics Exporter | Metrics | Exposes controller metrics on /metrics endpoint |
| Health Probes | Health | Provides /healthz and /readyz endpoints |

## APIs Exposed

### Custom Resource Definitions (CRDs)

The controller does not define its own CRDs but watches external CRDs:

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource for model serving deployments |
| serving.kserve.io | v1beta1 | ServingRuntime | Namespaced | Defines model server runtime configurations |
| serving.kserve.io | v1alpha1 | Predictor | Namespaced | Legacy predictor resource for ModelMesh |
| networking.istio.io | v1beta1 | Gateway | Namespaced | Istio ingress gateway configuration |
| networking.istio.io | v1beta1 | VirtualService | Namespaced | Istio traffic routing rules |
| security.istio.io | v1beta1 | PeerAuthentication | Namespaced | Istio mTLS configuration |
| security.istio.io | v1beta1 | AuthorizationPolicy | Namespaced | Istio authorization policies |
| telemetry.istio.io | v1alpha1 | Telemetry | Namespaced | Istio telemetry configuration |
| authorino.kuadrant.io | v1beta2 | AuthConfig | Namespaced | Authorino authentication/authorization rules |
| maistra.io | v1 | ServiceMeshMember | Namespaced | Service mesh membership |
| route.openshift.io | v1 | Route | Namespaced | OpenShift external routes |
| monitoring.coreos.com | v1 | ServiceMonitor | Namespaced | Prometheus service monitoring |
| monitoring.coreos.com | v1 | PodMonitor | Namespaced | Prometheus pod monitoring |
| datasciencecluster.opendatahub.io | v1 | DataScienceCluster | Cluster | ODH/RHOAI cluster configuration |
| dscinitialization.opendatahub.io | v1 | DSCInitialization | Cluster | ODH/RHOAI initialization settings |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /validate-serving-knative-dev-v1-service | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API | ValidatingWebhook for Knative Services |
| /metrics | GET | 8080/TCP | HTTP | None | Bearer Token | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | Controller does not expose gRPC services |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.12.1 | Yes | Model serving platform - provides InferenceService CRDs |
| Knative Serving | v0.39.3 | Conditional | Serverless inference deployment mode |
| Istio/Service Mesh | v1.19.4 | Conditional | Service mesh for mTLS, routing, telemetry |
| Authorino | v0.15.0 | Conditional | Authentication and authorization |
| Prometheus Operator | v0.64.1 | Conditional | Monitoring stack integration |
| OpenShift Routes | 3.9.0+ | Yes | External access on OpenShift |
| cert-manager or OCP Service CA | N/A | Yes | TLS certificate provisioning for webhooks |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| opendatahub-operator | CRD Watch | Reads DataScienceCluster and DSCInitialization for configuration |
| model-registry | API/CRD | Optional integration for model versioning and metadata |
| Service Mesh Control Plane | Service Mesh | Enrolls inference namespaces in mesh |
| Authorino | AuthConfig CRD | Creates authorization policies for inference endpoints |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API | Internal |
| odh-model-controller-metrics-service | ClusterIP | 8443/TCP | 8080 | HTTP | None | Bearer Token | Internal (Prometheus) |

### Ingress

Inference services created by the controller expose ingress:

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name} Route | OpenShift Route | Auto-generated | 443/TCP | HTTPS | TLS 1.2+ | Edge/Reencrypt | External |
| Istio Gateway | Istio Gateway | {isvc}.{namespace}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | SIMPLE | External (if mesh enabled) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature | Model artifact storage access |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Resource management |
| Model Registry | 8080/TCP | HTTP | None | None | Model metadata access (optional) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | serving.kserve.io | inferenceservices, servingruntimes | get, list, watch, update |
| odh-model-controller-role | networking.istio.io | gateways, virtualservices | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | security.istio.io | peerauthentications, authorizationpolicies | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | telemetry.istio.io | telemetries | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmembers, servicemeshmemberrolls | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.k8s.io | networkpolicies, ingresses | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" (core) | services, secrets, configmaps, serviceaccounts | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" (core) | namespaces, pods, endpoints | get, list, watch, create, update, patch |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |
| kserve-prometheus-k8s | "" (core) | services, endpoints, pods | get, list, watch |
| odh-model-controller-leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-role-binding | Varies | odh-model-controller-role | odh-model-controller |
| odh-model-controller-leader-election-role-binding | Controller NS | odh-model-controller-leader-election-role | odh-model-controller |
| kserve-prometheus-k8s-rolebinding | Inference NS | kserve-prometheus-k8s | prometheus-k8s (monitoring NS) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | Webhook server TLS certificate | OpenShift Service CA | Yes |
| storage-config | Opaque | Aggregated S3 storage credentials for model loading | StorageSecret Controller | On data connection change |
| kserve-custom-ca-cert | Opaque | Custom CA certificates for external services | KServeCustomCACert Controller | On source ConfigMap change |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-serving-knative-dev-v1-service | POST | K8s API Bearer Token | K8s API Server | ValidatingWebhookConfiguration RBAC |
| /metrics | GET | ServiceAccount Bearer Token | kube-rbac-proxy | Prometheus ServiceAccount authorization |
| Inference Service HTTP | GET, POST | Bearer Token (JWT) | Authorino | AuthConfig per InferenceService |
| Inference Service gRPC | * | mTLS client certificates | Istio | PeerAuthentication + AuthorizationPolicy |

## Data Flows

### Flow 1: InferenceService Creation and Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Controller | K8s API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | odh-model-controller | K8s API (watch) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | odh-model-controller | K8s API (create resources) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Model Inference Request (KServe Serverless with Mesh)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (edge termination) |
| 2 | OpenShift Router | Istio Gateway | 8080/TCP | HTTP | None | None (internal) |
| 3 | Istio Gateway | Authorino | 5001/TCP | HTTP | None | None (sidecar) |
| 4 | Istio Gateway | Inference Service Pod | 8080/TCP | HTTP | mTLS | Client Certificate |
| 5 | Inference Service | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature |

### Flow 3: Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus | odh-model-controller | 8080/TCP | HTTP | None | ServiceAccount Token |
| 2 | Prometheus | Inference Service Pods | 8080/TCP | HTTP | mTLS | Client Certificate |

### Flow 4: Storage Configuration Propagation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | K8s API (create Secret) | 6443/TCP | HTTPS | TLS 1.2+ | User credentials |
| 2 | odh-model-controller | K8s API (watch/read Secrets) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | odh-model-controller | K8s API (create storage-config) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | KServe Controller | Inference Pod (mount secret) | N/A | N/A | N/A | K8s Secret Mount |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Watches InferenceService status updates |
| OpenShift Router | Route Creation | 6443/TCP | HTTPS | TLS 1.2+ | Creates Routes for external access |
| Istio Control Plane | CRD Management | 6443/TCP | HTTPS | TLS 1.2+ | Creates VirtualServices, Gateways, PeerAuthentications |
| Authorino | AuthConfig CRD | 6443/TCP | HTTPS | TLS 1.2+ | Creates authentication/authorization policies |
| Prometheus Operator | ServiceMonitor CRD | 6443/TCP | HTTPS | TLS 1.2+ | Configures metrics scraping |
| Service Mesh Operator | ServiceMeshMember CRD | 6443/TCP | HTTPS | TLS 1.2+ | Enrolls namespaces in service mesh |
| Model Registry | gRPC API | 8080/TCP | HTTP | None | Retrieves model metadata (optional) |

## ConfigMaps

| ConfigMap Name | Namespace | Purpose | Provisioned By |
|----------------|-----------|---------|----------------|
| auth-refs | Controller NS | Stores AUTH_AUDIENCE and AUTHORINO_LABEL configuration | opendatahub-operator |
| service-mesh-refs | Controller NS | Stores CONTROL_PLANE_NAME and MESH_NAMESPACE configuration | opendatahub-operator |
| kserve-custom-ca-bundle | Inference NS | Custom CA certificates for external S3/services | KServeCustomCACert Controller |
| odh-trusted-ca-bundle | Inference NS | Global ODH CA bundle | opendatahub-operator |

## Serving Runtime Templates

| Template | Framework | Protocol | Port | Purpose |
|----------|-----------|----------|------|---------|
| ovms-kserve-template | OpenVINO Model Server | gRPC, HTTP | 8080/TCP, 8081/TCP | Intel-optimized inference for CV models |
| ovms-mm-template | OpenVINO Model Server | gRPC | 8085/TCP | ModelMesh variant for OVMS |
| tgis-template | Text Generation Inference Server | gRPC | 8033/TCP | Large language model serving |
| caikit-tgis-template | Caikit + TGIS | gRPC | 8085/TCP | IBM Caikit with TGIS backend |
| caikit-standalone-template | Caikit Standalone | gRPC | 8085/TCP | IBM Caikit standalone runtime |
| vllm-template | vLLM | HTTP | 8080/TCP | High-throughput LLM inference |

## NetworkPolicies Created

| Policy Name | Namespace | Purpose | Ingress Rules |
|-------------|-----------|---------|---------------|
| allow-from-openshift-monitoring-ns | Inference NS | Allow Prometheus scraping | From monitoring namespace on all ports |
| allow-openshift-ingress | Inference NS | Allow OpenShift Router traffic | From openshift-ingress namespace on all ports |
| allow-from-opendatahub-ns | Inference NS | Allow ODH component traffic | From namespaces with opendatahub.io/generated-namespace label |
| odh-model-controller | Controller NS | Protect controller webhook | Ingress on 9443/TCP only |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| ea70e0a | Recent | - Reverted vLLM reference to RC3 |
| eb68db6 | Recent | - Merged vLLM CUDA 2.14 component updates |
| 0708eb3 | Recent | - Updated vLLM CUDA to version 9b5ce1d |
| 2274e82 | Recent | - Updated vLLM CUDA to version 97b91f9 |
| 1dfc5e1 | Recent | - Updated vLLM CUDA to version 018c2a6 |
| 785c02a | Recent | - Updated vLLM image reference |
| 246872a | Recent | - Updated vLLM 2.14 image |
| 96d6aad | Recent | - Merged upstream main branch into rhoai-2.14 |
| e974419 | Recent | - Merged upstream release-0.12.0 |
| 08928f5 | Recent | - Updated OVMS for 2.14 in params.env |
| ed0fe09 | Recent | - Synchronized with main branch |
| 971ee10 | Recent | - Merged OVMS update for 2.14 |
| f2b911b | Recent | - Added 2.14 (2024.3) stable image of OVMS |
| c3e8c92 | Recent | - Added 2.14 stable images of caikit-tgis and TGIS |

## Deployment Architecture

### Deployment Modes Supported

1. **KServe Serverless (Knative)**
   - Uses Knative Serving for auto-scaling
   - Istio integration for traffic splitting
   - Scales to zero capability
   - Resources: KNative Service, Route, Gateway, VirtualService

2. **KServe RawDeployment**
   - Direct Kubernetes Deployment
   - No Knative dependency
   - Always-on pods
   - Resources: Deployment, Service, Route, Gateway, VirtualService

3. **ModelMesh**
   - Multi-model serving
   - Model routing and caching
   - Resources: Deployment, Service, Route, ClusterRoleBinding

### Controller Deployment

- **Namespace**: Typically `redhat-ods-applications` or `opendatahub`
- **Replicas**: 1 (leader election enabled)
- **Resources**: CPU 10m-500m, Memory 64Mi-2Gi
- **Anti-Affinity**: Pod anti-affinity for HA on multi-node clusters
- **Security Context**: Non-root user (65532)

### High Availability

- Leader election enabled via lease-based mechanism
- Single active controller, standby replicas possible
- Reconciliation continues automatically on leader failover
- Webhook service maintains availability during failover

## Observability

### Metrics Exposed

- Controller reconciliation metrics (duration, errors, queue depth)
- InferenceService count by deployment mode
- Resource creation/update/delete counters
- Webhook invocation metrics

### Logging

- Structured logging via zap
- Configurable log levels (default: info)
- Request-scoped logging with InferenceService name/namespace

### Tracing

- Not currently implemented
- Istio provides distributed tracing for inference requests

## Limitations and Considerations

1. **OpenShift Specific**: Requires OpenShift Routes, may need adaptation for vanilla Kubernetes
2. **Service Mesh Dependency**: Full features require Red Hat OpenShift Service Mesh (Istio)
3. **Single Controller**: One controller per cluster, watches all namespaces
4. **NetworkPolicy Management**: Automatic NetworkPolicy creation may conflict with custom policies
5. **Route Hostname Conflicts**: Multiple InferenceServices with same name in different namespaces may conflict
6. **Certificate Rotation**: Webhook certificates must be valid, rotation handled by OpenShift Service CA
7. **Storage Secret Format**: Specific format required for S3-compatible storage credentials
8. **Authorino Requirement**: Token-based auth requires Authorino to be installed

## Future Enhancements

Based on code comments and TODOs:
- Remove deprecated PeerAuthentication reconciliation logic
- Enhanced model registry integration
- Improved certificate management
- Additional serving runtime templates
- Better multi-tenancy support
