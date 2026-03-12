# Component: Kubeflow Spark Operator

## Metadata
- **Repository**: https://github.com/opendatahub-io/spark-operator.git
- **Version**: $(shell)
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Go, YAML
- **Deployment Type**: Kubernetes Operator

## Purpose
**Short**: Kubernetes operator for running Apache Spark applications declaratively using custom resources on Kubernetes and OpenShift.

**Detailed**: The Kubeflow Spark Operator makes running Apache Spark applications on Kubernetes as easy and idiomatic as running other workloads. It provides a Kubernetes-native way to define, submit, and manage Spark jobs through custom resources (SparkApplication, ScheduledSparkApplication, SparkConnect). The operator automatically runs `spark-submit` on behalf of users, handles driver and executor pod lifecycle, supports cron-based scheduled jobs, provides automatic application restart and retry with configurable policies, exports application and executor metrics to Prometheus, enables pod customization through mutating webhooks (volume mounts, affinity, tolerations), integrates with Volcano scheduler for gang scheduling, supports Spark 2.3+ with native Kubernetes scheduler backend, and manages Spark UI services and ingress for job monitoring. It simplifies big data processing workloads in Kubernetes by abstracting Spark cluster management complexity.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Spark Operator Controller | Go Controller | Reconciles Spark CRs and manages application lifecycle |
| SparkApplication Controller | Reconciler | Submits Spark jobs and monitors driver/executor pods |
| ScheduledSparkApplication Controller | Reconciler | Manages cron-based scheduled Spark jobs |
| SparkConnect Controller | Reconciler | Manages Spark Connect server deployments |
| Mutating Webhook | Admission Controller | Customizes Spark driver and executor pods before creation |
| Metrics Exporter | Prometheus Integration | Exports Spark application and executor metrics |
| Spark Submit Runner | Job Submitter | Executes `spark-submit` for eligible applications |

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| sparkoperator.k8s.io | v1beta2 | SparkApplication | Namespaced | Define and run Spark applications with auto-submit |
| sparkoperator.k8s.io | v1beta2 | ScheduledSparkApplication | Namespaced | Define cron-scheduled Spark applications |
| sparkoperator.k8s.io | v1beta2 | SparkConnect | Namespaced | Deploy Spark Connect servers for remote Spark sessions |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /metrics | GET | 8080/TCP | HTTP | None | None | Prometheus metrics for operator and Spark jobs |
| /readyz | GET | 8081/TCP | HTTP | None | None | Operator readiness probe endpoint |
| /healthz | GET | 8081/TCP | HTTP | None | None | Operator health check endpoint |
| /mutate | POST | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert | Mutating webhook for Spark pods |

### gRPC Services
No gRPC services are exposed by the operator. Spark applications use their own communication protocols (RPC, shuffle service).

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Apache Spark | 2.3+ | Yes | Distributed data processing engine |
| Spark Docker Images | 2.3+ | Yes | Container images with Spark runtime |
| Volcano | 1.x+ | No | Gang scheduling for Spark driver and executors |
| Prometheus | 2.x | No | Metrics collection and monitoring |
| Ingress Controller | Any | No | Expose Spark UI for job monitoring |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Notebooks | Job Submission | Submit Spark jobs from workbench environments |
| Data Science Pipelines | Pipeline Steps | Execute Spark data processing as pipeline components |
| S3 Storage | Data Access | Read input data and write output from/to S3 |
| Model Registry | Integration | Process training data for model development |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| <sparkapp>-ui-svc | ClusterIP | 4040/TCP | 4040 | HTTP | None | None | Internal |
| <sparkapp>-driver-svc | ClusterIP | 7078/TCP | 7078 | TCP | None | None | Internal |
| spark-operator-webhook | ClusterIP | 9443/TCP | 9443 | HTTPS | TLS 1.2+ | Webhook cert | Internal |
| spark-operator-metrics | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| <sparkapp>-ui-ingress | Kubernetes Ingress | *.apps.cluster | 80/TCP | HTTP | None | None | External |
| <sparkapp>-ui-ingress | Kubernetes Ingress | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Read input data and write output |
| HDFS | 8020/TCP, 9000/TCP | HDFS | SASL (optional) | Kerberos (optional) | Access HDFS filesystems |
| Hive Metastore | 9083/TCP | Thrift | SASL (optional) | Kerberos (optional) | Query Hive table metadata |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Token | Pull Spark runtime images |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| spark-operator-controller | "" | pods, services, configmaps | create, delete, get, list, update, watch |
| spark-operator-controller | "" | persistentvolumeclaims | list, watch |
| spark-operator-controller | "" | events | create, patch, update |
| spark-operator-controller | sparkoperator.k8s.io | sparkapplications, scheduledsparkapplications, sparkconnects | create, delete, get, list, watch |
| spark-operator-controller | sparkoperator.k8s.io | sparkapplications/status, scheduledsparkapplications/status, sparkconnects/status | update |
| spark-operator-controller | sparkoperator.k8s.io | sparkapplications/finalizers | update |
| spark-operator-controller | networking.k8s.io | ingresses | create, delete, get, update |
| spark-operator-controller | apiextensions.k8s.io | customresourcedefinitions | get |
| spark (driver/executor pods) | "" | pods, configmaps, services | get, list, watch, create, delete |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| spark-operator-controller-binding | spark-operator | spark-operator-controller | spark-operator |
| spark-driver-binding | <application-namespace> | spark (Role) | spark |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| spark-operator-webhook-cert | kubernetes.io/tls | TLS certificate for mutating webhook | cert-manager / Operator | Yes |
| aws-s3-credentials | Opaque | S3 access credentials for data access | User-provided | No |
| spark-driver-secret | Opaque | Credentials for Spark driver pod | User-provided | No |
| hdfs-credentials | Opaque | HDFS/Kerberos credentials (optional) | User-provided | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| Mutating Webhook | POST | mTLS | Kubernetes API Server | Webhook certificate validation |
| Operator Metrics | GET | None | None | Internal access only |
| Spark UI | GET | None | Spark UI Server | Open access (job monitoring) |
| Spark Driver/Executor | RPC | None (internal) | Spark | Internal pod communication |

## Data Flows

### Flow 1: SparkApplication Submission and Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User/Notebook | Kubernetes API (create SparkApplication) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Spark Operator | Kubernetes API (create driver pod) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Spark Operator | Mutating Webhook | 9443/TCP | HTTPS | TLS 1.2+ | Webhook cert |
| 4 | Driver Pod | Kubernetes API (create executor pods) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 5 | Driver Pod | Executor Pods | 7078/TCP | TCP | None | None |
| 6 | Executor Pods | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |
| 7 | Driver Pod | Kubernetes API (update status) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Spark UI Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | Ingress | 80/443 | HTTP/HTTPS | TLS 1.2+ (optional) | None |
| 2 | Ingress Controller | Spark UI Service | 4040/TCP | HTTP | None | None |
| 3 | Spark UI Service | Driver Pod | 4040/TCP | HTTP | None | None |

### Flow 3: Scheduled Spark Job Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | Kubernetes API (create ScheduledSparkApplication) | 6443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | Spark Operator (cron schedule) | SparkApplication (create) | N/A | N/A | N/A | N/A |
| 3 | Spark Operator | Driver Pod (create) | N/A | N/A | N/A | N/A |
| 4 | Driver Pod | Executor Pods | 7078/TCP | TCP | None | None |
| 5 | Executor Pods | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Kubernetes API | REST API | 6443/TCP | HTTPS | TLS 1.2+ | Manage Spark applications, driver/executor pods, and services |
| S3-compatible Storage | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Read input data and write Spark job output |
| HDFS | HDFS Protocol | 8020/9000 | HDFS | SASL (optional) | Access Hadoop Distributed File System |
| Hive Metastore | Thrift | 9083/TCP | Thrift | SASL (optional) | Query Hive table metadata for Spark SQL |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | Collect operator and Spark application metrics |
| Volcano Scheduler | CRD Integration | 6443/TCP | HTTPS | TLS 1.2+ | Gang scheduling for Spark driver and executors |
| Ingress Controller | Ingress CRD | 80/443 | HTTP/HTTPS | TLS 1.2+ (optional) | Expose Spark UI for job monitoring |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 1b9fca9 | 2025-01 | - Remove auto-generated role.yaml<br>- Change RELATED_IMAGE_SPARK_OPERATOR_IMAGE to RELATED_IMAGE_ODH_SPARK_OPERATOR_IMAGE<br>- Audit RBAC for Spark Operator controller<br>- Set HOME and cache env vars for containerd compatibility |
| 21fccc1 | 2024-12 | - Tighten webhook RBAC: remove cluster-wide events, add missing pods permission<br>- Replace Go e2e tests with shell script and remove Helm dependency<br>- Sync security config files (.gitleaks.toml, .gitleaksignore, semgrep.yaml) |
| deeb76c | 2024-12 | - Update Spark Operator image references in params.env for RHOAI overlay<br>- Change labels and metadata from 4.0.0 to 4.0.1<br>- Run OpenShift tests on any changes to config/**<br>- Consolidate KSO on OpenShift docs<br>- Change image name in manifests to follow standard nomenclature |
| 2bf485a | 2024-11 | - Add pipelineruns for ODH CI builds<br>- Add Kustomize manifests and documentation for Spark Operator on OpenShift<br>- Add 'v' in front of image tag for ODH/RHOAI operator images |
