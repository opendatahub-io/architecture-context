# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller
- **Version**: 1.27.0-rhods-153-g9aa422f
- **Branch**: rhoai-2.7
- **Distribution**: RHOAI (used in both ODH and RHOAI)
- **Languages**: Go 1.19
- **Deployment Type**: Kubernetes Operator (Controller)
- **Build System**: Konflux (Containerfile), UBI8-based images

## Purpose
**Short**: Extends KServe model serving capabilities with OpenShift-specific integrations including Routes, network policies, and service mesh configuration.

**Detailed**: The ODH Model Controller is a Kubernetes operator built with Kubebuilder that watches KServe InferenceService resources and automatically provisions OpenShift-specific infrastructure required for model serving. It bridges the gap between KServe's upstream Kubernetes-native deployment model and OpenShift's security and networking requirements. The controller supports both KServe and ModelMesh deployment modes, automatically creating Routes for external access, NetworkPolicies for namespace isolation, Istio PeerAuthentications for mTLS, and Prometheus monitoring resources. It also manages RBAC for monitoring stack integration and handles the lifecycle of namespace-scoped resources when InferenceServices are created or deleted.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Manager | Deployment (3 replicas) | Controller manager with leader election, watches InferenceServices |
| InferenceService Controller | Reconciler | Orchestrates KServe/ModelMesh reconciliation based on deployment mode |
| KServe Reconciler | Sub-reconciler | Manages KServe-specific resources (Routes, NetworkPolicies, mTLS) |
| ModelMesh Reconciler | Sub-reconciler | Manages ModelMesh-specific resources (Routes, ServiceAccounts, RoleBindings) |
| Monitoring Controller | Reconciler | Creates RoleBindings for Prometheus access to namespaces |
| Storage Secret Controller | Reconciler | Manages storage configuration secrets for model artifacts |
| Network Policy Reconciler | Resource Manager | Creates 3 NetworkPolicies per InferenceService namespace |
| Route Reconciler | Resource Manager | Creates OpenShift Routes pointing to Istio ingress |
| PeerAuthentication Reconciler | Resource Manager | Configures Istio mTLS for predictor pods |
| Telemetry Reconciler | Resource Manager | Configures Istio telemetry for monitoring |
| ServiceMonitor Reconciler | Resource Manager | Creates Prometheus ServiceMonitors/PodMonitors |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This controller does not define its own CRDs but watches external CRDs:

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary watched resource for model deployments |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Watched for triggering InferenceService reconciliation |
| route.openshift.io | v1 | Route | Namespaced | Created for external access to models |
| security.istio.io | v1beta1 | PeerAuthentication | Namespaced | Created for mTLS configuration |
| telemetry.istio.io | v1alpha1 | Telemetry | Namespaced | Created for Istio observability |
| networking.istio.io | v1beta1 | VirtualService | Namespaced | Created for Istio routing |
| maistra.io | v1 | ServiceMeshMemberRoll | Namespaced | Created for service mesh membership |
| maistra.io | v1 | ServiceMeshMember | Namespaced | Created for namespace mesh integration |
| monitoring.coreos.com | v1 | ServiceMonitor | Namespaced | Created for Prometheus metrics scraping |
| monitoring.coreos.com | v1 | PodMonitor | Namespaced | Created for Prometheus pod metrics |
| networking.k8s.io | v1 | NetworkPolicy | Namespaced | Created for network isolation |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for controller |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |

### gRPC Services

None - this controller does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.11.0 | Yes | Provides InferenceService and ServingRuntime CRDs |
| Istio | v1.17.4 | Yes (if mesh enabled) | Service mesh for mTLS, routing, telemetry |
| Maistra | v2.x | Yes (OpenShift) | OpenShift Service Mesh distribution |
| Prometheus Operator | v0.64.1 | Yes | ServiceMonitor/PodMonitor CRDs |
| OpenShift Routes | v3.9.0+ | Yes | External ingress via OpenShift router |
| Kubernetes | v1.26.4 | Yes | Core platform |
| controller-runtime | v0.14.6 | Yes | Kubebuilder framework |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe Operator | Watches CRDs | Primary dependency - watches InferenceService resources |
| Istio Ingress Gateway | Routes traffic | Routes point to istio-ingressgateway service |
| OpenShift Monitoring | RBAC/ServiceMonitors | Integrates with cluster monitoring stack |
| ODH Dashboard | NetworkPolicy labels | Network policies allow traffic from dashboard namespaces |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |
| kserve-metrics-service (created) | ClusterIP | 8086/TCP | 8086 | HTTP | None | None | Internal (Caikit metrics) |
| kserve-metrics-service (created) | ClusterIP | 3000/TCP | 3000 | HTTP | None | None | Internal (TGIS metrics) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc}-{ns} Route (KServe) | OpenShift Route | {isvc}.{domain} | 443/TCP | HTTPS | TLS 1.2+ | Passthrough | External |
| {isvc}-{ns} Route (KServe HTTP) | OpenShift Route | {isvc}.{domain} | 80/TCP | HTTP | None | N/A | External |
| {isvc} Route (ModelMesh) | OpenShift Route | {isvc}.{ns}.svc | 8008/TCP | HTTP | None | N/A | Internal |
| {isvc} Route (ModelMesh TLS) | OpenShift Route | {isvc}.{ns}.svc | 8443/TCP | HTTPS | TLS 1.2+ | Reencrypt | Internal |

Note: All Routes created by this controller point to istio-ingressgateway service in istio-system namespace.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Controller operations |
| Istio API | 15017/TCP | HTTPS | mTLS | ServiceAccount Token | Service mesh integration |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | serving.kserve.io | inferenceservices | get, list, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices/finalizers | get, list, watch, update |
| odh-model-controller-role | serving.kserve.io | servingruntimes | get, list, watch, create, update |
| odh-model-controller-role | serving.kserve.io | servingruntimes/finalizers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | route.openshift.io | routes | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | security.istio.io | peerauthentications | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | telemetry.istio.io | telemetries | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | networking.istio.io | virtualservices | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmembers | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshmemberrolls | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | maistra.io | servicemeshcontrolplanes | get, list, watch, create, update, patch, use |
| odh-model-controller-role | networking.k8s.io | networkpolicies | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | get, list, watch, create, update, patch, delete |
| odh-model-controller-role | "" (core) | configmaps, namespaces, pods, services, serviceaccounts, secrets, endpoints | get, list, watch, create, update, patch |
| odh-model-controller-role | apps | deployments, statefulsets | get, list, delete |
| odh-model-controller-role | networking.k8s.io, extensions | ingresses | get, list, watch |
| odh-model-controller-role | project.openshift.io | projects | get |
| odh-model-controller-leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch, delete |
| odh-model-controller-leader-election-role | "" (core) | events | create, patch |
| prometheus-ns-access | "" (core) | endpoints, pods, services | get, list, watch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding | {controller-namespace} | odh-model-controller-role | odh-model-controller |
| odh-model-controller-leader-election-rolebinding | {controller-namespace} | odh-model-controller-leader-election-role | odh-model-controller |
| prometheus-ns-access (created) | {isvc-namespace} | prometheus-ns-access | prometheus-custom@{monitoring-namespace} |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| Storage secrets | Opaque | S3/Azure/GCS credentials for model artifacts | User/External | No |

Note: Controller does not manage TLS certificates - relies on OpenShift router and Istio for TLS termination.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | None (internal) | NetworkPolicy | Allow from monitoring namespace only |
| /healthz, /readyz | GET | None (internal) | NetworkPolicy | Allow from Kubernetes probes |
| Created Routes | ALL | Varies by ISVC config | Istio/OpenShift Router | Per-InferenceService auth policy |

### Network Policies

Created by controller for each InferenceService namespace:

| Policy Name | Selector | Ingress From | Ports | Purpose |
|-------------|----------|--------------|-------|---------|
| allow-from-openshift-monitoring-ns | All pods | openshift-user-workload-monitoring | All | Allow Prometheus scraping |
| allow-openshift-ingress | All pods | network.openshift.io/policy-group=ingress | All | Allow OpenShift router traffic |
| allow-from-opendatahub-ns | All pods | opendatahub.io/dashboard=true, kubernetes.io/metadata.name=kserve, opendatahub.io/generated-namespace=true | All | Allow traffic from ODH components and data science projects |

### Service Mesh Configuration

| Resource | Type | Configuration | Purpose |
|----------|------|---------------|---------|
| PeerAuthentication "default" | Istio mTLS | Mode: STRICT for predictor pods; PERMISSIVE for ports 8086, 3000 | Enforce mTLS for model serving, allow plaintext for metrics |
| Telemetry | Istio Observability | Default tracing/metrics config | Enable service mesh telemetry |
| ServiceMeshMemberRoll | Maistra | Adds ISVC namespace to mesh | Integrate namespace with service mesh |

## Data Flows

### Flow 1: External Model Inference Request (KServe Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | External Client | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token (optional) |
| 2 | OpenShift Router | istio-ingressgateway@istio-system | 443/TCP | HTTPS | TLS 1.2+ (passthrough) | N/A |
| 3 | istio-ingressgateway | Predictor Pod@{isvc-namespace} | 8080/TCP | HTTP | mTLS (Istio sidecar) | mTLS client cert |
| 4 | Predictor Pod | Model Container | 8080/TCP | HTTP | None (localhost) | None |

### Flow 2: Prometheus Metrics Scraping

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Prometheus@{monitoring-namespace} | odh-model-controller-metrics-service | 8080/TCP | HTTP | None | ServiceAccount Token |
| 2 | Prometheus@{monitoring-namespace} | Predictor Pod metrics | 8086/TCP | HTTP | None | ServiceAccount Token (via NetworkPolicy) |
| 3 | Prometheus@{monitoring-namespace} | Predictor Pod metrics | 3000/TCP | HTTP | None | ServiceAccount Token (via NetworkPolicy) |

### Flow 3: Controller Reconciliation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Controller Pod | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Controller Pod | Istio API (if mesh enabled) | 15017/TCP | HTTPS | mTLS | ServiceAccount Token |

### Flow 4: ModelMesh Inference Request

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Internal Client | ModelMesh Service | 8008/TCP | HTTP | None | None |
| 1 (TLS) | Internal Client | ModelMesh Service | 8443/TCP | HTTPS | TLS 1.2+ | mTLS (optional) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe Controller | CRD Watch | 6443/TCP | HTTPS | TLS 1.2+ | Watch InferenceService/ServingRuntime resources |
| Istio Control Plane | gRPC/API | 15017/TCP | HTTPS | mTLS | Create VirtualServices, PeerAuthentications, Telemetries |
| OpenShift Router | Route Creation | 6443/TCP | HTTPS | TLS 1.2+ | Create Routes pointing to istio-ingressgateway |
| Prometheus Operator | CRD Creation | 6443/TCP | HTTPS | TLS 1.2+ | Create ServiceMonitor/PodMonitor resources |
| Maistra Control Plane | CRD Creation | 6443/TCP | HTTPS | TLS 1.2+ | Create ServiceMeshMember/ServiceMeshMemberRoll |

## Deployment Configuration

### Manager Deployment

- **Replicas**: 3 (high availability)
- **Leader Election**: Enabled (only one active reconciler)
- **Resource Limits**: CPU 500m, Memory 2Gi
- **Resource Requests**: CPU 10m, Memory 64Mi
- **Security Context**: runAsNonRoot=true, allowPrivilegeEscalation=false
- **Anti-Affinity**: Prefer spreading across nodes (podAntiAffinity)
- **Service Account**: odh-model-controller
- **Health Checks**: Liveness (8081/healthz, 15s initial, 20s period), Readiness (8081/readyz, 5s initial, 10s period)

### Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| POD_NAMESPACE | Field ref | Namespace where controller is running |
| MESH_DISABLED | Flag/ConfigMap | Disable service mesh integration if true |
| --monitoring-namespace | Command arg | Namespace where Prometheus is deployed |
| --leader-elect | Command arg | Enable leader election |

### Kustomize Overlays

| Overlay | Purpose |
|---------|---------|
| config/base | Base manifests (manager, RBAC, service) |
| config/overlays/odh | ODH-specific configuration |
| config/overlays/dev | Development configuration |

## Recent Changes

Based on git log (last 20 commits):

| Commit | Summary |
|--------|---------|
| 9aa422f | Merge remote-tracking branch 'upstream/release-0.11.1' |
| 974b7f8 | Merge pull request #152 from terrytangyuan/cp-np-change |
| 9ef6e53 | Merge remote-tracking branch 'upstream/release-0.11.1' |
| 316e8f4 | Merge pull request #151 from VedantMahabaleshwarkar/monitoring_delete_cherrypick |
| e4df8a3 | fix: adds network policies to unblock traffic between components (#145) |
| 096df04 | add temp Job to delete old monitoring stack |
| 06d0153 | Merge pull request #149 from VedantMahabaleshwarkar/rbac_cherrypick |
| 8b2c7b0 | add back rbac removed by linter |
| d089935 | Merge remote-tracking branch 'upstream/release-0.11.1' |
| 8ffeccb | Merge pull request #144 from opendatahub-io/revert-138-cp-np |
| 8576c99 | Revert "[Cherry-pick] fix: Remove NetworkPolicies created to relax SMCP policies" |
| 8ed99e5 | Merge remote-tracking branch 'upstream/release-0.11.1' |
| 40917f1 | Merge pull request #138 from terrytangyuan/cp-np |
| cfc1d40 | Merge pull request #142 from Jooho/RHOAIENG-1835 |
| 42330d7 | Fix Stack-based Buffer Overflow on protobuf |
| 3b8a30b | Merge pull request #141 from Jooho/RHOAIENG-1834 |
| b046dfe | Update knative-serving |
| 8ad82d7 | Merge pull request #140 from Jooho/RHOAIENG-1833 |
| 42ac0aa | Merge pull request #139 from Jooho/RHOAIENG-1832 |
| ef22694 | Fixes vulnerabilities on the otelhttp dependency |

**Recent Themes**:
- Network policy updates to unblock traffic between components (RHOAIENG-1003)
- Monitoring stack cleanup and RBAC fixes
- Security vulnerability fixes (protobuf CVE, otelhttp CVE)
- Syncing with upstream KServe release-0.11.1
- Service mesh policy refinements

## Key Design Decisions

### 1. Dual-Mode Support
The controller supports both KServe (serverless, Knative-based) and ModelMesh (stateful, multi-model serving) deployment modes with separate reconciliation logic for each.

### 2. Namespace-Scoped Resources
Most resources (NetworkPolicies, PeerAuthentications, ServiceMonitors) are created in the InferenceService's namespace, not in the controller's namespace, to enable proper isolation.

### 3. Routes in Istio Namespace
Routes are created in the `istio-system` namespace and point to the `istio-ingressgateway` service, following OpenShift Service Mesh patterns.

### 4. Permissive Metrics Ports
PeerAuthentication configures PERMISSIVE mTLS mode for ports 8086 and 3000 to allow Prometheus to scrape metrics without client certificates.

### 5. NetworkPolicy Layering
Three separate NetworkPolicies are created to allow: (1) monitoring traffic, (2) OpenShift ingress, (3) ODH component traffic. This provides defense-in-depth.

### 6. Leader Election for HA
With 3 replicas and leader election, the controller can tolerate 2 pod failures while maintaining availability.

### 7. Delta Processing
The controller uses comparator pattern to compute resource deltas, only updating resources when actual changes are detected (not on every reconciliation).

## Known Limitations

1. **OpenShift-Specific**: Controller relies on OpenShift Route API and cannot be used on vanilla Kubernetes without modification.
2. **Istio Dependency**: Service mesh features require Istio/Maistra to be installed and configured.
3. **Single Istio Namespace**: Assumes Istio ingress gateway is in `istio-system` namespace (hardcoded).
4. **No CRD Validation**: Controller watches external CRDs but does not validate their schemas.
5. **Cleanup on ISVC Deletion**: Some cluster-scoped resources may not be cleaned up if controller is not running during ISVC deletion.

## Troubleshooting

### Common Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Route not created | InferenceService accessible via VirtualService but not externally | Check controller logs for Route creation errors; verify Routes are in istio-system namespace |
| NetworkPolicy blocks traffic | Pods cannot communicate | Verify namespace labels (opendatahub.io/dashboard, opendatahub.io/generated-namespace) |
| Metrics not scraped | Prometheus missing ISVC metrics | Check RoleBinding "prometheus-ns-access" exists in ISVC namespace; verify ServiceMonitor created |
| mTLS errors | Connection refused on inference requests | Check PeerAuthentication applied; verify Istio sidecar injection enabled |
| Controller crashloop | Controller pod restarting | Check if external CRDs are installed (KServe, Istio, Prometheus Operator) |

### Debug Commands

```bash
# Check controller logs
kubectl logs -n {controller-namespace} deployment/odh-model-controller -c manager

# Verify NetworkPolicies created
kubectl get networkpolicies -n {isvc-namespace}

# Check Routes in istio-system
kubectl get routes -n istio-system

# Verify PeerAuthentication
kubectl get peerauthentication -n {isvc-namespace}

# Check ServiceMonitors
kubectl get servicemonitor -n {isvc-namespace}

# View controller metrics
kubectl port-forward -n {controller-namespace} svc/odh-model-controller-metrics-service 8080:8080
curl localhost:8080/metrics
```

## Future Enhancements

Based on upstream KServe roadmap and RHOAI requirements:

1. **Multi-cluster Support**: Extend to manage InferenceServices across multiple clusters
2. **Custom Ingress Controllers**: Support for alternative ingress beyond OpenShift Routes
3. **Advanced Autoscaling**: Integration with KEDA for custom scaling metrics
4. **Storage Provisioner Integration**: Automatic PVC creation for model caching
5. **Observability Improvements**: Enhanced metrics and distributed tracing integration
6. **Policy-as-Code**: Integration with OPA/Gatekeeper for model deployment policies
