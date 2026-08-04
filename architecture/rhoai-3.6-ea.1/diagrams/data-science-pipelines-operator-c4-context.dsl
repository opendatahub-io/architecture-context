workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML pipelines using DataSciencePipelinesApplication CRs"
        platformAdmin = person "Platform Admin" "Configures DSPA instances and manages pipeline infrastructure"

        dspOperator = softwareSystem "Data Science Pipelines Operator" "Kubernetes operator managing the lifecycle of Data Science Pipelines instances on OpenShift via DSPA custom resources" {
            dspaReconciler = container "DSPAReconciler" "Watches DSPA CRs and reconciles the full pipeline stack" "Go controller-runtime"
            webhookServer = container "Webhook Server" "Validates and mutates PipelineVersion resources" "Go HTTPS :9443"
            metricsServer = container "Metrics Server" "Exposes operator metrics for Prometheus" "HTTPS :8080"
            securityProfileWatcher = container "SecurityProfileWatcher" "Monitors OpenShift TLS profile changes and triggers restart" "Go"
            manifestivalEngine = container "Manifestival Engine" "Renders and applies templated Kubernetes manifests" "Go library"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster-level TLS profile configuration" "External"

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow engine for pipeline execution" "Managed Component"
        mariaDB = softwareSystem "MariaDB" "Pipeline metadata database (or external DB)" "Managed Component"
        minIO = softwareSystem "MinIO / S3" "Pipeline artifact object storage (or external S3)" "Managed Component"

        mlflow = softwareSystem "MLflow" "Experiment tracking platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        ray = softwareSystem "Ray / CodeFlare" "Distributed compute for pipeline steps" "Internal RHOAI"
        seldon = softwareSystem "Seldon" "Model serving platform" "Internal RHOAI"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring stack management" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workbenches" "Internal RHOAI"

        # User interactions
        dataScientist -> dspOperator "Creates DSPA CRs, submits pipelines" "kubectl / Dashboard"
        platformAdmin -> dspOperator "Configures pipeline infrastructure" "kubectl / CLI"

        # Operator to K8s API
        dspOperator -> kubernetesAPI "CRUD resources, watch events" "HTTPS/6443 TLS 1.2+ SA token"
        dspOperator -> openshiftAPIServer "Read TLS profile" "HTTPS/6443 TLS 1.2+"

        # Operator manages pipeline stack
        dspOperator -> argoWorkflows "Deploys and manages Argo engine" "Kubernetes API"
        dspOperator -> mariaDB "Deploys or connects to DB" "Kubernetes API / SQL"
        dspOperator -> minIO "Deploys or connects to storage" "Kubernetes API / S3 API"

        # Platform integrations
        dspOperator -> mlflow "Watches MLflow CRs" "Kubernetes API Watch"
        dspOperator -> kserve "Watches InferenceServices" "Kubernetes API Watch"
        dspOperator -> ray "Manages Ray clusters and jobs" "Kubernetes API CRUD"
        dspOperator -> seldon "Manages Seldon deployments" "Kubernetes API CRUD"
        dspOperator -> prometheusOperator "Creates ServiceMonitors" "Kubernetes API CRUD"
        dspOperator -> kubeflowNotebooks "Manages notebook workbenches" "Kubernetes API CRUD"

        # Internal container relationships
        dspaReconciler -> manifestivalEngine "Renders templates" ""
        dspaReconciler -> webhookServer "Registers webhooks" ""
        securityProfileWatcher -> dspaReconciler "Triggers restart on TLS change" ""
    }

    views {
        systemContext dspOperator "SystemContext" {
            include *
            autoLayout
        }

        container dspOperator "Containers" {
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
            element "Managed Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
