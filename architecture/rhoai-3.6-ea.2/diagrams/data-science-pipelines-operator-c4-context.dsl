workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML pipelines"
        platformAdmin = person "Platform Admin" "Deploys and configures RHOAI platform"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Kubeflow Pipelines v2 deployments on OpenShift via DSPA custom resources" {
            dspaReconciler = container "DSPAReconciler" "Reconciles DSPA CRs; deploys per-namespace KFP v2 stacks via manifestival templates" "Go Controller"
            aiPipelinesReconciler = container "AIPipelinesReconciler" "Reconciles cluster-scoped AIPipelines CR for modular platform ownership" "Go Controller"
            aiPipelinesArgoReconciler = container "AIPipelinesArgoReconciler" "Manages Argo Workflows CRDs and cluster RBAC" "Go Controller"
            manifestTemplates = container "Manifest Templates" "YAML templates rendered with DSPAParams for sub-components" "Go Templates (manifestival)"
            webhookServer = container "Webhook Server" "Validates and mutates pipeline resources" "Go Service (9443/TCP)"
        }

        apiServer = softwareSystem "Pipeline API Server" "Kubeflow Pipelines v2 REST API server (deployed per DSPA)" "Deployed Component"
        argoController = softwareSystem "Argo Workflow Controller" "Pipeline step orchestration (deployed per DSPA)" "Deployed Component"
        mlmd = softwareSystem "ML Metadata Server" "Pipeline artifact lineage and metadata via gRPC + Envoy" "Deployed Component"
        persistenceAgent = softwareSystem "Persistence Agent" "Syncs pipeline run status from Argo to KFP API" "Deployed Component"

        k8sApi = softwareSystem "Kubernetes API" "Cluster resource management" "External"
        openShiftConfig = softwareSystem "OpenShift Config API" "TLS security profile configuration" "External"
        mariadb = softwareSystem "MariaDB" "Pipeline metadata storage (in-namespace or external)" "External"
        objectStore = softwareSystem "S3-Compatible Object Store" "Pipeline artifact storage (MinIO or external S3)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"

        kserve = softwareSystem "KServe" "Model serving platform for inference from pipeline steps" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking integration" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed pipeline execution (RayClusters, RayJobs)" "Internal RHOAI"
        prometheusOperator = softwareSystem "prometheus-operator" "ServiceMonitor and PrometheusRule management" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "UI for managing pipelines" "Internal RHOAI"

        platformAdmin -> dspo "Creates DSPA / AIPipelines CRs via kubectl"
        dataScientist -> apiServer "Submits and monitors pipeline runs" "HTTPS/443"

        dspaReconciler -> manifestTemplates "Renders templates with DSPAParams"
        dspaReconciler -> k8sApi "CRUD on cluster resources" "HTTPS/6443"
        dspaReconciler -> mariadb "Health checks" "MySQL/3306"
        dspaReconciler -> objectStore "Health checks" "HTTPS/443 or HTTP/9000"
        dspo -> openShiftConfig "Fetches TLS security profile" "HTTPS/6443"

        dspo -> apiServer "Deploys per namespace"
        dspo -> argoController "Deploys per namespace"
        dspo -> mlmd "Deploys per namespace"
        dspo -> persistenceAgent "Deploys per namespace"

        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiServer -> objectStore "Stores/retrieves artifacts" "HTTPS/443"
        argoController -> k8sApi "Creates pipeline step Pods" "HTTPS/6443"
        argoController -> mlmd "Records artifact metadata" "gRPC/8443"

        dspo -> kserve "Creates InferenceService resources" "HTTPS/6443"
        dspo -> mlflow "Reads MLflow instances for tracking" "HTTPS/6443"
        dspo -> ray "Creates RayClusters, RayJobs" "HTTPS/6443"
        dspo -> prometheusOperator "Manages ServiceMonitor, PrometheusRule" "HTTPS/6443"
        prometheus -> dspo "Scrapes metrics" "HTTPS/8443"
        dashboard -> apiServer "UI management of pipelines" "HTTPS/443"
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
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Deployed Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
