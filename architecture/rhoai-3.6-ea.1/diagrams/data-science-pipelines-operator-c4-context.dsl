workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML pipelines via DSPA custom resources"
        clusterAdmin = person "Cluster Admin" "Manages operator deployment and platform configuration"

        dspo = softwareSystem "Data Science Pipelines Operator" "Kubernetes operator managing the lifecycle of Data Science Pipelines infrastructure" {
            dspaReconciler = container "DSPAReconciler" "Watches DSPA CRs and reconciles pipeline infrastructure" "Go controller-runtime"
            webhookServer = container "Webhook Server" "Validates and mutates DSPA resources" "Admission Webhooks"
            tlsWatcher = container "SecurityProfileWatcher" "Monitors OpenShift TLS profile changes and triggers restarts" "Go goroutine"
            manifestEngine = container "Manifestival Engine" "Renders and applies resource templates from config/internal/" "manifestival library"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for ML pipelines" "Managed by DSPO"
        pipelineAPIServer = softwareSystem "Pipeline API Server" "Kubeflow Pipelines API server for pipeline management" "Managed by DSPO"

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" "External"

        mlflow = softwareSystem "MLflow" "Experiment tracking and model registry" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workbench management" "Internal RHOAI"
        prometheusOperator = softwareSystem "prometheus-operator" "Kubernetes monitoring stack operator" "Internal RHOAI"
        seldon = softwareSystem "Seldon" "ML model deployment platform" "External"
        ray = softwareSystem "Ray" "Distributed computing framework for ML workloads" "External"
        codeflare = softwareSystem "CodeFlare" "Multi-cluster application management for ML" "Internal RHOAI"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships
        dataScientist -> dspo "Creates DataSciencePipelinesApplication CRs" "kubectl / RHOAI Dashboard"
        clusterAdmin -> dspo "Deploys and configures operator" "OLM / OperatorHub"

        dspaReconciler -> manifestEngine "Renders resource templates"
        dspaReconciler -> webhookServer "Validates/mutates CRs"
        tlsWatcher -> dspaReconciler "Triggers restart on TLS profile change"

        dspo -> kubernetesAPI "Watches/manages cluster resources" "HTTPS/6443, ServiceAccount Auth"
        dspo -> openshiftAPIServer "Reads TLS security profile" "HTTPS/6443"
        dspo -> argoWorkflows "Deploys and manages Argo CRDs" "Kubernetes API"
        dspo -> pipelineAPIServer "Deploys and manages pipeline server" "Kubernetes API"

        dspo -> mlflow "Reads MLflow instance state" "CRD Watch, HTTPS"
        dspo -> kserve "Reads model serving state, creates InferenceServices" "CRD CRUD, HTTPS"
        dspo -> kubeflowNotebooks "Creates and manages notebook workbenches" "CRD CRUD, HTTPS"
        dspo -> prometheusOperator "Creates ServiceMonitors for monitoring" "CRD CRUD, HTTPS"
        dspo -> seldon "Manages Seldon deployments" "CRD CRUD, HTTPS"
        dspo -> ray "Manages Ray clusters and jobs" "CRD CRUD, HTTPS"
        dspo -> codeflare "Manages CodeFlare AppWrappers" "CRD CRUD, HTTPS"

        prometheus -> dspo "Scrapes metrics" "HTTP/8080"
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
            element "Managed by DSPO" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
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
