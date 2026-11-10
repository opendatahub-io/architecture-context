workspace {
    model {
        dataScientist = person "Data Scientist" "Creates DSPAs and submits pipeline runs via KFP SDK or Dashboard"

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages a separate Kubeflow Pipelines v2 stack per DataSciencePipelinesApplication namespace" {
            manager = container "DSPO controller-manager" "DSPAReconciler, AIPipelinesReconciler, AIPipelinesArgoReconciler (feature-gated); renders config/internal templates via manifestival" "Go controller-runtime"
            webhook = container "ds-pipeline-webhook" "Shared mutating/validating admission webhook for PipelineVersion (kubernetes pipeline store)" "Go (KFP API-server image), HTTPS 8443"
            apiServer = container "KFP API server (per DSPA)" "KFP v2 REST 8888 / gRPC 8887; kube-rbac-proxy 8443 (SAR on DSPA api) and 8445 (metrics)" "Go + kube-rbac-proxy"
            persistenceAgent = container "Persistence agent (per DSPA)" "Syncs Argo Workflow state to API server/DB" "Go"
            scheduledWorkflow = container "Scheduled-workflow controller (per DSPA)" "Reconciles ScheduledWorkflow recurring runs" "Go"
            workflowController = container "Argo workflow controller (per DSPA)" "Namespaced Argo controller running pipeline Workflows" "Argo Workflows 3.6.12"
            mlmd = container "ML Metadata (optional)" "MLMD gRPC 8080 + Envoy gRPC-Web 9090 + kube-rbac-proxy 8443" "MLMD / Envoy proxyv2"
            mariadb = container "MariaDB (optional)" "Built-in pipeline metadata DB, service-ca TLS" "MariaDB 10.5" "Database"
            minio = container "MinIO (optional, dev only)" "Built-in S3-compatible artifact store, 9000 HTTP" "MinIO" "Database"
        }

        rhods = softwareSystem "rhods-operator" "Installs DSPO manifests; legacy DataSciencePipelines owner" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Pipelines UI; consumes DSPA API and MLMD Envoy" "Internal ODH"
        mlflow = softwareSystem "MLflow (mlflow-operator)" "Experiment tracking; endpoint auto-detected" "Internal ODH"
        kserve = softwareSystem "KServe" "InferenceServices created by pipelines (RBAC pass-through)" "Internal ODH"
        ray = softwareSystem "Ray / CodeFlare" "Distributed jobs launched by pipelines (RBAC pass-through)" "Internal ODH"
        monitoring = softwareSystem "Prometheus / monitoring stack" "Scrapes operator and API server metrics" "Internal ODH"
        k8s = softwareSystem "Kubernetes / OpenShift API" "Control plane, Routes, service-ca, APIServer TLS profile" "External"
        extDb = softwareSystem "External MySQL" "User-supplied pipeline DB" "External"
        s3 = softwareSystem "S3 Object Storage" "Pipeline artifact storage" "External"
        registry = softwareSystem "Container Registries" "Managed-pipeline OCI images" "External"

        dataScientist -> dspo "Creates DSPA; submits runs via Route" "HTTPS/443, Bearer token"
        dataScientist -> dashboard "Uses Pipelines UI"
        dashboard -> apiServer "Calls KFP API" "HTTPS/8443, Bearer + SAR"
        dashboard -> mlmd "Queries lineage" "HTTPS/8443 gRPC-Web"
        rhods -> manager "Deploys operator" "config/overlays/rhoai"
        manager -> k8s "Watches DSPAs, applies operand manifests" "HTTPS/6443, SA token"
        manager -> mariadb "Health check" "MySQL/3306"
        manager -> extDb "Health check" "MySQL/3306, optional TLS"
        manager -> s3 "Bucket health check" "HTTPS/443"
        manager -> registry "Fetches managed pipelines" "HTTPS/443"
        manager -> mlflow "Resolves tracking endpoint" "K8s API CR read"
        manager -> apiServer "Deploys"
        manager -> webhook "Deploys when pipelineStore=kubernetes"
        k8s -> webhook "Admission for PipelineVersion" "HTTPS/8443, service-ca"
        apiServer -> mariadb "Persists metadata" "MySQL/3306"
        apiServer -> extDb "Persists metadata" "MySQL/3306"
        apiServer -> k8s "Creates Argo Workflows" "HTTPS/6443"
        apiServer -> mlflow "Experiment tracking" "HTTPS"
        persistenceAgent -> apiServer "Syncs run state" "HTTP/gRPC 8888/8887"
        scheduledWorkflow -> apiServer "Triggers recurring runs" "gRPC/8887"
        workflowController -> k8s "Creates workflow pods" "HTTPS/6443"
        apiServer -> minio "Artifacts" "HTTP/9000"
        apiServer -> s3 "Artifacts" "HTTPS/443"
        dspo -> kserve "Pipelines deploy models"
        dspo -> ray "Pipelines launch Ray/AppWrapper jobs"
        monitoring -> manager "Scrapes /metrics" "HTTPS/8443, Bearer + SAR"
        monitoring -> apiServer "Scrapes /metrics" "HTTPS/8445, Bearer + SAR"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
        }

        container dspo "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal ODH" {
                background #7ed321
            }
            element "Database" {
                shape Cylinder
            }
        }
    }
}
