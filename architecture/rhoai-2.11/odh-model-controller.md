# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller.git
- **Version**: v1.27.0-rhods-427-g67f6e03
- **Branch**: rhoai-2.11
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Controller/Operator

## Purpose
**Short**: Extends KServe and ModelMesh serving capabilities with OpenShift-specific integrations for routing, service mesh, authorization, and monitoring.

**Detailed**:

The ODH Model Controller is a Kubernetes operator built with Kubebuilder that watches KServe InferenceService custom resources and extends the behavior of both KServe and ModelMesh model serving frameworks. It bridges the gap between upstream KServe/ModelMesh and OpenShift/Red Hat OpenShift AI by providing integrations with OpenShift Routes, Red Hat Service Mesh (Istio/Maistra), Authorino for authorization, and Prometheus for monitoring.

The controller implements multiple reconciliation loops to manage the complete lifecycle of inference services, including creating OpenShift Routes for external access, configuring Istio VirtualServices and Gateways for service mesh routing, setting up AuthConfigs for API authentication, managing NetworkPolicies for network security, and deploying ServiceMonitors for metrics collection. It supports both KServe Serverless (Knative-based), KServe Raw (direct deployment), and ModelMesh deployment modes.

Additionally, the controller manages serving runtime templates (OVMS, TGIS, Caikit, vLLM) and provides a validating webhook for Knative Services to ensure proper configuration in service mesh environments. It handles storage secrets, custom CA certificates, and integrates with the Model Registry for ML model lifecycle management.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Reconciler | Controller | Main reconciler that delegates to deployment-mode-specific reconcilers (ModelMesh, KServe Serverless, KServe Raw) |
| KServe Serverless Reconciler | Sub-reconciler | Manages Knative-based inference services with Istio integration, routes, auth, and monitoring |
| KServe Raw Reconciler | Sub-reconciler | Manages direct Kubernetes deployment-based inference services |
| ModelMesh Reconciler | Sub-reconciler | Manages ModelMesh-based inference services with routes and RBAC |
| StorageSecret Reconciler | Controller | Reconciles storage configuration secrets for S3/object storage access |
| KServeCustomCACert Reconciler | Controller | Manages custom CA certificate bundles for KServe |
| Monitoring Reconciler | Controller | Creates ServiceMonitors and PodMonitors for Prometheus metrics collection |
| ModelRegistry InferenceService Reconciler | Controller | Integrates InferenceServices with Model Registry for model versioning |
| Knative Service Validator | ValidatingWebhook | Validates Knative Service configurations for service mesh compatibility |
| Webhook Server | HTTPS Server | Serves admission webhooks on port 9443 with TLS |
| Metrics Server | HTTP Server | Exposes Prometheus metrics on port 8080 |
| Health Probe Server | HTTP Server | Provides liveness/readiness probes on port 8081 |

## APIs Exposed

### Custom Resource Definitions (CRDs)

**Note**: This controller does not define its own CRDs but watches external CRDs from other components.

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource watched - represents deployed ML models |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Defines model serving runtime configurations (templates) |
| serving.knative.dev | v1 | Service | Namespaced | Validated via webhook for service mesh compatibility |
| authorino.kuadrant.io | v1beta2 | AuthConfig | Namespaced | Created for API authentication/authorization |
| networking.istio.io | v1beta1 | VirtualService | Namespaced | Created for service mesh routing |
| networking.istio.io | v1beta1 | Gateway | Namespaced | Updated for external access configuration |
| security.istio.io | v1beta1 | PeerAuthentication | Namespaced | Created for mTLS configuration |
| telemetry.istio.io | v1alpha1 | Telemetry | Namespaced | Created for Istio telemetry configuration |
| route.openshift.io | v1 | Route | Namespaced | Created for OpenShift external routing |
| monitoring.coreos.com | v1 | ServiceMonitor | Namespaced | Created for Prometheus metrics scraping |
| monitoring.coreos.com | v1 | PodMonitor | Namespaced | Created for direct pod metrics scraping |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /validate-serving-knative-dev-v1-service | POST | 9443/TCP | HTTPS | TLS 1.2+ | K8s API Server cert | Admission webhook for Knative Service validation |
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe endpoint |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe endpoint |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | This component does not expose gRPC services |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.12.1 | Yes | Core inference serving framework |
| Knative Serving | v0.39.3 | No | Required only for KServe Serverless mode |
| Istio/Maistra Service Mesh | 1.19.x | No | Service mesh for traffic management and mTLS |
| Authorino | v0.15.0 | No | API authorization framework |
| Prometheus Operator | v0.64.1 | No | Metrics collection and monitoring |
| OpenShift Route API | 3.9.0+ | Yes | External access routing (OpenShift-specific) |
| cert-manager or service.beta.openshift.io/serving-cert | Any | Yes | TLS certificate provisioning for webhooks |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | CRD Watch/Update | Primary resource managed by this controller |
| Model Registry | gRPC API + CRD Watch | Optional integration for model versioning and metadata |
| DataScienceCluster | CRD Watch | Reads configuration to determine enabled features |
| DSCInitialization | CRD Watch | Reads platform configuration and feature flags |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-webhook-service | ClusterIP | 443/TCP | 9443 | HTTPS | TLS 1.2+ | K8s API Server mTLS | Internal (API Server only) |
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | N/A | N/A | N/A | N/A | N/A | N/A | Controller itself does not accept external ingress (creates routes for InferenceServices) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch and reconcile Kubernetes resources |
| Model Registry Service | 9090/TCP | gRPC | mTLS | Service Mesh | Optional: Register/query ML model metadata |
| Prometheus | 9090/TCP | HTTP | None | None | Optional: Query metrics for reconciliation decisions |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | serving.kserve.io | inferenceservices, inferenceservices/finalizers | get, list, watch, update |
| odh-model-controller-role | serving.kserve.io | servingruntimes, servingruntimes/finalizers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.istio.io | virtualservices, virtualservices/finalizers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.istio.io | gateways | get, list, watch, update, patch |
| odh-model-controller-role | security.istio.io | peerauthentications | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | security.istio.io | authorizationpolicies | get, list |
| odh-model-controller-role | telemetry.istio.io | telemetries | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmembers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmemberrolls, servicemeshcontrolplanes | get, list, watch, use |
| odh-model-controller-role | route.openshift.io | routes, routes/custom-host | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.k8s.io | networkpolicies, ingresses | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | authorino.kuadrant.io | authconfigs | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" | services, secrets, configmaps, serviceaccounts | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" | namespaces, pods, endpoints | get, list, watch, create, update, patch |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | datasciencecluster.opendatahub.io | datascienceclusters | get, list, watch |
| odh-model-controller-role | dscinitialization.opendatahub.io | dscinitializations | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding | All namespaces (ClusterRoleBinding) | odh-model-controller-role | odh-model-controller |
| odh-model-controller-leader-election-rolebinding | Controller namespace | leader-election-role | odh-model-controller |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| odh-model-controller-webhook-cert | kubernetes.io/tls | TLS certificate for webhook server | service.beta.openshift.io/serving-cert or cert-manager | Yes |
| opendatahub.io/managed=true labeled secrets | Opaque | Storage credentials managed by controller (cached) | User or other controllers | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /validate-serving-knative-dev-v1-service | POST | mTLS (Kubernetes API Server client cert) | Kubernetes API Server | ValidatingWebhookConfiguration |
| /metrics | GET | None (internal only) | NetworkPolicy | Internal cluster access only |
| /healthz, /readyz | GET | None | None | Unauthenticated health checks |

### Network Policies

| Policy Name | Namespace | Pod Selector | Ingress Rules |
|-------------|-----------|--------------|---------------|
| odh-model-controller | Controller namespace | app=odh-model-controller, control-plane=odh-model-controller | Allow TCP/9443 from any (API Server webhook traffic) |

## Data Flows

### Flow 1: InferenceService Creation with KServe Serverless Mode

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token (kubeconfig) |
| 2 | Kubernetes API | odh-model-controller | N/A | Watch Event | N/A | ServiceAccount Token |
| 3 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 4 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 5 | Kubernetes API | odh-model-controller (webhook) | 9443/TCP | HTTPS | TLS 1.2+ | mTLS (API Server cert) |

**Description**: User creates InferenceService → Controller watches event → Creates Istio Gateway/VirtualService, OpenShift Route, AuthConfig, NetworkPolicy, ServiceMonitors → KServe creates Knative Service → Webhook validates configuration → Service deployed.

### Flow 2: InferenceService Creation with ModelMesh Mode

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Client | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token (kubeconfig) |
| 2 | Kubernetes API | odh-model-controller | N/A | Watch Event | N/A | ServiceAccount Token |
| 3 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

**Description**: User creates InferenceService → Controller watches event → Creates OpenShift Route, ServiceAccount, ClusterRoleBinding for ModelMesh → ModelMesh serves model.

### Flow 3: Monitoring and Metrics Collection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |
| 2 | Prometheus | odh-model-controller-metrics-service | 8080/TCP | HTTP | None | Bearer Token (ServiceAccount) |

**Description**: Controller creates ServiceMonitor for InferenceService → Prometheus discovers and scrapes inference service metrics + controller metrics.

### Flow 4: Storage Secret Management

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Admin | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token |
| 2 | Kubernetes API | odh-model-controller | N/A | Watch Event | N/A | ServiceAccount Token |
| 3 | odh-model-controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token |

**Description**: User creates storage secret with label opendatahub.io/managed=true → Controller watches and caches secret → Applies to InferenceServices for S3/storage access.

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API Server | REST API | 6443/TCP | HTTPS | TLS 1.3 | Watch/manage all Kubernetes resources |
| KServe Controller | CRD | N/A | N/A | N/A | Primary workload - watches InferenceService CRDs |
| Istio Control Plane | CRD | N/A | N/A | N/A | Creates VirtualServices, Gateways, PeerAuthentications |
| OpenShift Router | CRD | N/A | N/A | N/A | Creates Route resources for external access |
| Authorino | CRD | N/A | N/A | N/A | Creates AuthConfig for API authorization |
| Prometheus Operator | CRD | N/A | N/A | N/A | Creates ServiceMonitors for metrics |
| Model Registry | gRPC API | 9090/TCP | gRPC | mTLS | Optional: Register inference service metadata |
| Knative Serving | Admission Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Validates Knative Service configurations |

## Deployment Configuration

### Container Images

| Image Purpose | Base Image | Build Method |
|---------------|------------|--------------|
| Manager | registry.access.redhat.com/ubi8/ubi-minimal:8.10 | Multi-stage build with go-toolset:1.21.11-9 |

### Resource Requirements

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| manager | 10m | 500m | 64Mi | 2Gi |

### Replicas and High Availability

- **Replicas**: 3 (for high availability)
- **Leader Election**: Enabled (only one active reconciler at a time)
- **Anti-Affinity**: Preferred pod anti-affinity to spread across nodes

### Environment Variables

| Variable | Source | Required | Purpose |
|----------|--------|----------|---------|
| POD_NAMESPACE | Field reference | Yes | Current pod namespace |
| AUTH_AUDIENCE | ConfigMap auth-refs | No | Authorino audience configuration |
| AUTHORINO_LABEL | ConfigMap auth-refs | No | Label for Authorino instance selection |
| CONTROL_PLANE_NAME | ConfigMap service-mesh-refs | No | Service mesh control plane name |
| MESH_NAMESPACE | ConfigMap service-mesh-refs | No | Service mesh namespace |
| MESH_DISABLED | Environment | No | Disable service mesh integration (default: false) |

## Serving Runtime Templates

The controller deploys the following default ServingRuntime templates:

| Runtime | Purpose | Model Formats |
|---------|---------|---------------|
| OVMS (OpenVINO Model Server) | Intel-optimized inference for computer vision and NLP | OpenVINO IR, ONNX, TensorFlow |
| TGIS (Text Generation Inference Server) | High-performance text generation | HuggingFace models |
| Caikit-TGIS | Caikit framework with TGIS backend | Caikit format, HuggingFace |
| Caikit Standalone | Standalone Caikit runtime | Caikit format |
| vLLM | High-throughput LLM serving | HuggingFace, various LLM formats |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-427-g67f6e03 | 2024-11 | - Added instant-merge.yaml for CI/CD<br>- Updated UBI minimal base image to 8.10<br>- Updated Go toolset to 1.21.11-9<br>- Reverted KServe dashboard metrics reconciler<br>- Updated vLLM image reference<br>- Fixed vLLM image SHA references |
| v1.27.0-rhods | 2024-11 | - Synced with upstream release 0.12.0<br>- Added watch for Serving Cert Secret<br>- Fixed internal hostname gateway configuration<br>- Updated Caikit NLP runtime to 0cde6c2<br>- Multiple test case improvements |
| Earlier | 2024-10 | - Model Registry integration support<br>- Enhanced service mesh integration<br>- Improved authorization with Authorino<br>- Network policy reconciliation |

## Known Limitations

1. **OpenShift-Specific**: This controller is designed for OpenShift and uses OpenShift Route API which is not available in vanilla Kubernetes
2. **Service Mesh Dependency**: Full feature set requires Red Hat Service Mesh (Istio/Maistra) installation
3. **No Custom CRDs**: Controller does not define its own CRDs, relying entirely on external resources
4. **Leader Election**: Only one replica actively reconciles at a time (others are standby)
5. **Secret Caching**: Only secrets with label `opendatahub.io/managed=true` are cached (performance optimization)

## Troubleshooting

### Common Issues

1. **Webhook Certificate Errors**: Ensure cert-manager or OpenShift service CA operator is properly configured
2. **InferenceService Not Accessible**: Check Route/VirtualService creation and service mesh configuration
3. **Storage Access Failures**: Verify storage secrets have correct label and credentials
4. **Service Mesh Integration**: Confirm ServiceMeshMember is created and namespace is part of mesh

### Debug Commands

```bash
# Check controller logs
oc logs -n opendatahub deploy/odh-model-controller -c manager

# Verify webhook configuration
oc get validatingwebhookconfiguration | grep odh-model-controller

# Check created resources for an InferenceService
oc get route,virtualservice,gateway,authconfig,servicemonitor -n <namespace>

# Verify RBAC permissions
oc auth can-i --as=system:serviceaccount:opendatahub:odh-model-controller create routes
```

## References

- **Upstream Project**: https://github.com/opendatahub-io/odh-model-controller
- **KServe Documentation**: https://kserve.github.io/website/
- **Kubebuilder**: https://book.kubebuilder.io/
- **Red Hat OpenShift AI**: https://access.redhat.com/products/red-hat-openshift-ai/
