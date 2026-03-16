# Component: ODH Model Controller

## Metadata
- **Repository**: https://github.com/red-hat-data-services/odh-model-controller
- **Version**: v1.27.0-rhods-216-gf37fe21
- **Branch**: rhoai-2.8
- **Distribution**: RHOAI
- **Languages**: Go 1.21
- **Deployment Type**: Kubernetes Operator
- **Manifests Location**: config/overlays/odh

## Purpose
**Short**: Extends KServe and ModelMesh inference serving with OpenShift-native integrations including Routes, Service Mesh, and monitoring.

**Detailed**: The ODH Model Controller is a Kubernetes operator that watches InferenceService custom resources and automatically provisions OpenShift-specific infrastructure for ML model serving. It bridges KServe/ModelMesh serving capabilities with OpenShift platform features by creating Routes for external access, configuring Istio Service Mesh integration (ServiceMeshMemberRolls, PeerAuthentication, Telemetry), setting up Prometheus monitoring (ServiceMonitors, PodMonitors), managing storage configurations from data connection secrets, and applying NetworkPolicies for secure communications. The controller supports both KServe Serverless and ModelMesh deployment modes, removing the need for users to manually configure platform integration when deploying their models.

The controller runs as a highly available deployment with 3 replicas and leader election, providing reconciliation loops for InferenceService lifecycle management, storage secret aggregation, custom CA certificate injection, and monitoring resource provisioning.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| InferenceService Controller | Reconciler | Watches InferenceService CRDs and provisions OpenShift Routes, Service Mesh resources, monitoring, and network policies |
| StorageSecret Controller | Reconciler | Aggregates data connection secrets into storage-config secrets for KServe/ModelMesh |
| KServeCustomCACert Controller | Reconciler | Injects custom CA certificates into KServe deployments for enterprise trust stores |
| Monitoring Controller | Reconciler | Creates RoleBindings to grant Prometheus access to namespaces with InferenceServices |
| KServe Reconciler | Sub-Reconciler | Handles KServe Serverless/RawDeployment mode: Routes, metrics services, Istio SMMR, Telemetry, PeerAuthentication, NetworkPolicy |
| ModelMesh Reconciler | Sub-Reconciler | Handles ModelMesh mode: Routes, ServiceAccounts, ClusterRoleBindings |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This controller does not define its own CRDs. It watches and acts on external CRDs:

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| serving.kserve.io | v1beta1 | InferenceService | Namespaced | Primary resource watched for model serving deployments |
| serving.kserve.io | v1alpha1 | ServingRuntime | Namespaced | Watched to trigger InferenceService reconciliation |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | ServiceAccount Token | Prometheus metrics endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Liveness probe |
| /readyz | GET | 8081/TCP | HTTP | None | None | Readiness probe |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| KServe | v0.11.0 | Yes | Provides InferenceService and ServingRuntime CRDs for model serving |
| Istio Service Mesh | v1.17.4 | Yes (KServe Serverless) | Provides traffic management, mTLS, telemetry for model endpoints |
| Maistra | v0.0.0-20230417135504-0536f6c22b1c | Yes (OpenShift) | OpenShift Service Mesh operator integration |
| Prometheus Operator | v0.64.1 | Yes | Enables ServiceMonitor and PodMonitor for metrics collection |
| OpenShift API | v3.9.0 | Yes | Provides Route API for external ingress |
| Knative | v0.0.0-20231023151236-29775d7c9e5c | Yes (KServe Serverless) | Serverless runtime for KServe deployments |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| KServe | Watches CRDs | Deploys and manages model inference services |
| ModelMesh Serving | Watches CRDs | Multi-model serving runtime |
| ODH Dashboard | Reads Secrets | Data connection secrets created by dashboard |
| OpenShift Monitoring | Creates RoleBindings | Grants Prometheus access to scrape model metrics |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| odh-model-controller-metrics-service | ClusterIP | 8080/TCP | 8080 | HTTP | None | ServiceAccount Token | Internal |
| {isvc-name}-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | Bearer Token | Internal (per InferenceService in KServe mode) |

### Ingress

Resources created by the controller for InferenceServices:

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {isvc-name} | OpenShift Route | Generated by cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Watch CRDs, manage resources |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Model artifact storage (configured via secrets) |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| odh-model-controller-role | serving.kserve.io | inferenceservices | get, list, watch |
| odh-model-controller-role | serving.kserve.io | inferenceservices/finalizers | get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes | create, get, list, update, watch |
| odh-model-controller-role | serving.kserve.io | servingruntimes/finalizers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | route.openshift.io | routes/custom-host | create |
| odh-model-controller-role | networking.istio.io | virtualservices | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | security.istio.io | peerauthentications | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | telemetry.istio.io | telemetries | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshmemberrolls | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshmembers | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | maistra.io | servicemeshcontrolplanes | create, get, list, patch, update, use, watch |
| odh-model-controller-role | monitoring.coreos.com | servicemonitors, podmonitors | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | networking.k8s.io | networkpolicies | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | rbac.authorization.k8s.io | clusterrolebindings, rolebindings | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | "" (core) | configmaps, secrets, serviceaccounts | create, delete, get, list, patch, update, watch |
| odh-model-controller-role | "" (core) | namespaces, pods, services, endpoints | create, get, list, patch, update, watch |
| odh-model-controller-role | apps | deployments, statefulsets | delete, get, list |
| odh-model-controller-role | networking.k8s.io, extensions | ingresses | get, list, watch |
| kserve-prometheus-k8s | "" (core) | services, endpoints, pods | get, list, watch |
| leader-election-role | "" (core) | configmaps | get, list, watch, create, update, patch |
| leader-election-role | coordination.k8s.io | leases | get, list, watch, create, update, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| odh-model-controller-rolebinding-$(mesh-namespace) | Cluster-wide | ClusterRole/odh-model-controller-role | odh-model-controller |
| leader-election-rolebinding | Controller namespace | Role/leader-election-role | odh-model-controller |
| prometheus-ns-access | Per InferenceService namespace | ClusterRole/prometheus-ns-access | prometheus-custom (openshift-monitoring) |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| storage-config | Opaque | Aggregated S3 credentials for KServe/ModelMesh | StorageSecret Controller | Yes (on data connection changes) |
| {data-connection-name} | Opaque | S3 bucket credentials (watched, not created) | ODH Dashboard | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /metrics | GET | Bearer Token (ServiceAccount) | Prometheus ServiceMonitor | Kubernetes RBAC |
| /healthz, /readyz | GET | None | Kubernetes probes | Open for health checks |

### Service Mesh Security

Resources created by controller for InferenceServices in KServe Serverless mode:

| Resource Type | Name Pattern | mTLS Mode | Purpose |
|---------------|--------------|-----------|---------|
| PeerAuthentication | {namespace}-peer-authn | PERMISSIVE | Enables mTLS for inference endpoints while allowing plaintext during migration |
| Telemetry | {namespace}-telemetry | N/A | Configures metrics collection from Istio sidecar proxies |

## Data Flows

### Flow 1: InferenceService Creation (KServe Serverless Mode)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Dashboard | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | ODH Model Controller | Kubernetes API (watch) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | ODH Model Controller | Kubernetes API (create Route) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | ODH Model Controller | Kubernetes API (create SMMR) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | ODH Model Controller | Kubernetes API (create PeerAuthentication) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 6 | ODH Model Controller | Kubernetes API (create ServiceMonitor) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 7 | ODH Model Controller | Kubernetes API (create NetworkPolicy) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Storage Secret Aggregation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ODH Dashboard | Kubernetes API (create data connection secret) | 6443/TCP | HTTPS | TLS 1.2+ | User Bearer Token |
| 2 | ODH Model Controller | Kubernetes API (watch secrets) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | ODH Model Controller | Kubernetes API (create storage-config secret) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | KServe/ModelMesh | Kubernetes API (read storage-config) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | KServe/ModelMesh | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials from secret |

### Flow 3: Monitoring Access Provisioning

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ODH Model Controller | Kubernetes API (create RoleBinding) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Prometheus | InferenceService Pod | 8080/TCP | HTTP | None | ServiceAccount Token |
| 3 | Prometheus | Istio Proxy (envoy) | 15020/TCP | HTTP | None | ServiceAccount Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| KServe Controller | Watches CRDs | 6443/TCP | HTTPS | TLS 1.2+ | Coordinates InferenceService reconciliation |
| ModelMesh Controller | Watches CRDs | 6443/TCP | HTTPS | TLS 1.2+ | Coordinates multi-model serving |
| Istio Service Mesh | Creates Custom Resources | 6443/TCP | HTTPS | TLS 1.2+ | Configures traffic management and mTLS |
| OpenShift Router | Creates Routes | 6443/TCP | HTTPS | TLS 1.2+ | Exposes inference endpoints externally |
| Prometheus Operator | Creates ServiceMonitors | 6443/TCP | HTTPS | TLS 1.2+ | Enables metrics collection |
| ODH Dashboard | Reads Secrets | 6443/TCP | HTTPS | TLS 1.2+ | Provides data connection UI |

## Deployment Architecture

### Controller Deployment

| Attribute | Value | Purpose |
|-----------|-------|---------|
| Replicas | 3 | High availability |
| Anti-Affinity | Preferred | Spread across nodes |
| Leader Election | Enabled | Only one active reconciler |
| Leader Election ID | odh-model-controller | Lock identifier |
| Security Context | runAsNonRoot: true, allowPrivilegeEscalation: false | Restricted pod security |
| Resource Requests | CPU: 10m, Memory: 64Mi | Minimal baseline |
| Resource Limits | CPU: 500m, Memory: 2Gi | Prevent resource exhaustion |

### Reconciliation Modes

The controller detects InferenceService deployment mode and applies different reconciliation logic:

| Mode | Detection | Resources Created |
|------|-----------|-------------------|
| KServe Serverless | Knative service exists | Route, SMMR, PeerAuthentication, Telemetry, NetworkPolicy, ServiceMonitor, PodMonitor, metrics Service, RoleBinding |
| KServe RawDeployment | Deployment/StatefulSet exists without Knative | Route only (minimal reconciliation) |
| ModelMesh | ServingRuntime annotation | Route, ServiceAccount, ClusterRoleBinding |

## Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| MESH_DISABLED | false | Disable Service Mesh integration (skip SMMR, PeerAuthentication, Telemetry) |
| POD_NAMESPACE | (from fieldRef) | Namespace where controller is running |

### Command-Line Flags

| Flag | Default | Purpose |
|------|---------|---------|
| --metrics-bind-address | :8080 | Prometheus metrics endpoint |
| --health-probe-bind-address | :8081 | Health and readiness probes |
| --leader-elect | false (true in prod) | Enable leader election |
| --monitoring-namespace | "" (set to redhat-ods-monitoring) | Namespace where Prometheus runs |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.27.0-rhods-216-gf37fe21 | 2025-09-01 | - Update Konflux build references<br>- Update UBI8 minimal base image digest<br>- Dependency updates for security patches |
| (prior commits) | 2025-08-26 | - Update registry.redhat.io/ubi8/ubi-minimal digest to 43dde01 |
| (prior commits) | 2025-08-20 | - Update registry.redhat.io/ubi8/ubi-minimal digest to 89f2c97 |
| (prior commits) | 2025-08-15 | - Update registry.redhat.io/ubi8/ubi-minimal digest to 395dec1 |
| (prior commits) | 2025-08-08 | - Merge Dockerfile digest updates for rhoai-2.8 branch |
| (prior commits) | 2025-08-01 | - Update Konflux build references |
| (prior commits) | 2025-07-31 | - Update UBI8 minimal base image digest to af9b4a2 |
| (prior commits) | 2025-07-29 | - Update UBI8 minimal base image digest to 7957d61 |
| (prior commits) | 2025-07-28 | - Update UBI8 minimal base image digest to 8075621 |
| (prior commits) | 2025-07-15 | - Update UBI8 minimal base image digest to 5b195cf |

## Key Features

### OpenShift Route Management
- Automatically creates Routes for InferenceServices to expose them via OpenShift's ingress
- Supports custom hostnames via routes/custom-host permissions
- Manages Route lifecycle (creation, update, deletion) based on InferenceService status

### Service Mesh Integration
- Adds namespaces to ServiceMeshMemberRoll for automatic sidecar injection
- Creates PeerAuthentication resources to enable mTLS for inference traffic
- Configures Telemetry resources for metrics collection from Istio proxies
- Supports mesh-disabled mode via MESH_DISABLED environment variable

### Storage Configuration
- Aggregates multiple data connection secrets (S3 credentials) into unified storage-config secret
- Supports multiple storage backends per namespace
- Automatically injects custom CA certificates for enterprise S3 endpoints
- Compatible with both KServe and ModelMesh storage expectations

### Monitoring Integration
- Creates ServiceMonitors for application metrics (port 8080)
- Creates PodMonitors for Istio proxy metrics (port 15020)
- Provisions RoleBindings to grant Prometheus ServiceAccount access to user namespaces
- Supports configurable monitoring namespace via --monitoring-namespace flag

### Network Security
- Creates NetworkPolicies to control traffic flow to/from inference pods
- Integrates with OpenShift SDN/OVN for policy enforcement
- Supports both ingress and egress policy configuration

### High Availability
- Runs with 3 replicas and leader election
- Leader election prevents concurrent reconciliation
- Pod anti-affinity spreads replicas across nodes
- Graceful degradation on controller failure (resources remain intact)

## Operational Considerations

### Resource Cleanup
- Automatically removes namespace from SMMR when last InferenceService is deleted
- Cleans up RoleBindings, ServiceMonitors, PodMonitors when namespace has no InferenceServices
- Preserves Routes during InferenceService updates (stable URLs)

### Compatibility Matrix
- KServe v0.11.0
- Istio v1.17.4
- OpenShift 4.x (Route API v1)
- Kubernetes v1.27.6
- Prometheus Operator v0.64.1

### Logging
- Structured logging with zap
- Log levels: Info (default), Debug (V(1))
- Key events logged: reconciliation start/end, resource creation/update/deletion, errors

### Metrics
- Controller runtime metrics exposed on /metrics
- Standard Kubernetes client metrics (API latency, errors)
- Custom metrics: reconciliation duration, errors per controller

## Troubleshooting

### Common Issues

**InferenceService created but no Route**:
- Check controller logs for reconciliation errors
- Verify odh-model-controller has permission to create Routes
- Ensure InferenceService status shows Ready condition

**Prometheus not scraping metrics**:
- Verify RoleBinding "prometheus-ns-access" exists in InferenceService namespace
- Check ServiceMonitor selector matches InferenceService labels
- Ensure monitoring-namespace flag is set correctly

**Service Mesh integration not working**:
- Verify MESH_DISABLED is not set to true
- Check ServiceMeshMemberRoll includes target namespace
- Ensure Maistra/Istio operator is installed

**Storage config not found**:
- Verify data connection secrets have labels: opendatahub.io/managed=true, opendatahub.io/dashboard=true
- Check controller logs for storage-config reconciliation
- Ensure StorageSecretReconciler is running

## Build and Deployment

### Container Image
- **Build Method**: Konflux (RHOAI), Docker/Podman (ODH)
- **Konflux File**: Dockerfile.konflux
- **Base Image**: registry.redhat.io/ubi8/ubi-minimal (runtime), registry.redhat.io/ubi8/go-toolset:1.21 (build)
- **Build Args**: SOURCE_CODE=., USER=2000
- **Image Labels**: com.redhat.component=odh-model-controller-container
- **Entrypoint**: /manager

### Kustomize Deployment
- **Base**: config/base
- **Overlays**: config/overlays/odh (ODH), config/overlays/dev (development)
- **CRDs**: config/crd/external (external CRDs for reference)
- **RBAC**: config/rbac (ClusterRole, RoleBindings, ServiceAccount)
- **Manager**: config/manager (Deployment, namespace)
- **Monitoring**: config/prometheus (ServiceMonitor)

### Development Workflow
```bash
# Run tests
make test

# Build and push image
make docker-build docker-push IMG=quay.io/${USER}/odh-model-controller:latest

# Deploy to cluster
make deploy K8S_NAMESPACE=opendatahub IMG=quay.io/${USER}/odh-model-controller:latest
```
