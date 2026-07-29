workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines using DataSciencePipelinesApplication CRs"
        clusterAdmin = person "Cluster Admin" "Manages DSPO deployment and configuration"

        dspo = softwareSystem "Data Science Pipelines Operator" "Kubernetes operator that manages the lifecycle of DataSciencePipelinesApplication instances, provisioning Argo Workflow infrastructure and pipeline resources" {
            controllerManager = container "DSPO Controller Manager" "Watches DSPA CRs and reconciles pipeline infrastructure. Provisions Argo CRDs, RBAC, and services via manifestival." "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and mutates PipelineVersion resources" "Admission Webhook (port 9443)"
            metricsEndpoint = container "Metrics Endpoint" "Exposes operator metrics for Prometheus scraping" "HTTP (port 8080)"
        }

        argoWorkflows = softwareSystem "Argo Workflow Engine" "Executes ML pipeline workflows as Kubernetes-native workflow orchestration" "Provisioned"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal ODH"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model registry" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workbench management" "Internal ODH"
        prometheusOperator = softwareSystem "prometheus-operator" "Kubernetes monitoring stack operator" "Internal ODH"
        openShift = softwareSystem "OpenShift Platform" "Container platform providing Routes, Image Streams, and security profiles" "External"

        # User interactions
        dataScientist -> dspo "Creates DataSciencePipelinesApplication CR and Pipeline CRs" "kubectl / Dashboard"
        clusterAdmin -> dspo "Deploys and configures operator" "OLM / kubectl"

        # DSPO internal
        controllerManager -> webhookServer "Registers admission webhooks" "Internal"

        # DSPO to external systems
        dspo -> kubernetesAPI "CRUD on managed resources (ConfigMaps, Secrets, Deployments, Services, RBAC, NetworkPolicies)" "HTTPS/6443, TLS 1.2+, ServiceAccount"
        dspo -> argoWorkflows "Provisions CRDs, RBAC, ServiceAccounts via manifestival; creates Workflow CRs" "Kubernetes API"
        dspo -> kserve "Watches InferenceService CRs (read-only)" "Kubernetes API, TLS 1.2+"
        dspo -> mlflow "Watches MLflow CRs (read-only)" "Kubernetes API, TLS 1.2+"
        dspo -> kubeflowNotebooks "Creates and manages notebook workbenches" "Kubernetes API, TLS 1.2+"
        dspo -> prometheusOperator "Creates ServiceMonitor resources" "Kubernetes API, TLS 1.2+"
        dspo -> openShift "Reads Image Streams; creates/manages Routes" "HTTPS/6443, TLS 1.2+"

        # Argo to K8s
        argoWorkflows -> kubernetesAPI "Manages workflow pods, PVCs, secrets" "HTTPS/6443, ServiceAccount: argo"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Provisioned" {
                background #e96d3f
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
