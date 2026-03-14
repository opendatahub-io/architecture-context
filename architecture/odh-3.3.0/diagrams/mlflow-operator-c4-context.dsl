workspace {
    model {
        datascientist = person "Data Scientist" "Creates and tracks ML experiments, logs metrics and artifacts"
        developer = person "Developer" "Deploys and manages MLflow instances via Custom Resources"

        mlflowOp = softwareSystem "MLflow Operator" "Kubernetes operator for deploying and managing MLflow experiment tracking and model registry servers" {
            controller = container "MLflow Controller" "Reconciles MLflow CRs to deploy MLflow servers" "Go Operator" {
                reconciler = component "MLflow Reconciler" "Watches MLflow CRs and manages lifecycle"
                helmRenderer = component "Helm Renderer" "Renders Helm charts into Kubernetes manifests"
                networkPolicy = component "NetworkPolicy Manager" "Creates egress/ingress policies"
                tlsManager = component "TLS Certificate Manager" "Manages TLS certificates via service-ca"
            }

            configController = container "MLflowConfig Controller" "Manages namespace-scoped artifact storage overrides" "Go Watcher"

            mlflowServer = container "MLflow Server" "Experiment tracking and model registry server" "Python/MLflow 2.x" {
                api = component "REST API" "MLflow REST API for experiments and models" "Python/Flask"
                webui = component "Web UI" "Interactive experiment tracking dashboard" "HTML/JS"
                authPlugin = component "Kubernetes Auth Plugin" "SubjectAccessReview-based authentication" "Python"
            }
        }

        k8s = softwareSystem "Kubernetes API" "Cluster control plane" "External"
        postgresql = softwareSystem "PostgreSQL Database" "Production database for experiment/model metadata" "External"
        mysql = softwareSystem "MySQL Database" "Alternative database backend" "External"
        sqlite = softwareSystem "SQLite" "Development file-based database" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for model artifacts and experiment files" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning" "External"
        gateway = softwareSystem "Gateway API" "Ingress gateway for external access" "External"

        notebooks = softwareSystem "Notebooks" "Jupyter notebooks and workbenches for ML development" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration and execution" "Internal ODH"
        trainingOp = softwareSystem "Training Operator" "Distributed ML training jobs" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Alternative model registry service" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "OpenShift console integration and management UI" "Internal ODH"

        # Relationships - User interactions
        datascientist -> mlflowServer "Logs experiments, metrics, and artifacts via Python SDK" "HTTPS/8443, Bearer Token"
        datascientist -> mlflowServer "Views experiments and models via Web UI" "HTTPS/443 (via Gateway)"
        developer -> mlflowOp "Creates and manages MLflow CRs via kubectl" "HTTPS/6443"

        # Relationships - Operator to K8s
        controller -> k8s "Creates Deployments, Services, PVCs, HTTPRoutes, ConsoleLinks" "HTTPS/6443, ServiceAccount Token"
        configController -> k8s "Watches MLflowConfig CRs for storage overrides" "HTTPS/6443, ServiceAccount Token"

        # Relationships - MLflow Server to dependencies
        mlflowServer -> k8s "Authenticates requests via SubjectAccessReview" "HTTPS/6443, ServiceAccount Token"
        mlflowServer -> postgresql "Stores experiment and model metadata (production)" "PostgreSQL/5432, TLS 1.2+, Password"
        mlflowServer -> mysql "Stores experiment and model metadata (alternative)" "MySQL/3306, TLS 1.2+, Password"
        mlflowServer -> sqlite "Stores experiment and model metadata (dev mode)" "File I/O"
        mlflowServer -> s3 "Stores model artifacts and experiment files" "HTTPS/443, AWS credentials"

        # Relationships - Service integrations
        serviceCa -> mlflowServer "Provisions TLS certificates automatically (90d rotation)" "Secret injection"
        gateway -> mlflowServer "Routes external traffic to MLflow Web UI/API" "HTTPS/8443, Bearer Token"

        # Relationships - ODH component integrations
        notebooks -> mlflowServer "Tracks experiments and logs metrics from notebooks" "HTTPS/8443, Bearer Token"
        dsPipelines -> mlflowServer "Logs pipeline run metrics and artifacts" "HTTPS/8443, Bearer Token"
        trainingOp -> mlflowServer "Tracks distributed training experiments" "HTTPS/8443, Bearer Token"
        mlflowServer -> modelRegistry "Alternative to Model Registry for model storage" "Functional overlap"
        dashboard -> mlflowOp "Manages MLflow deployments via OpenShift Console" "ConsoleLink integration"
    }

    views {
        systemContext mlflowOp "SystemContext" {
            include *
            autoLayout
        }

        container mlflowOp "Containers" {
            include *
            autoLayout
        }

        component controller "OperatorComponents" {
            include *
            autoLayout
        }

        component mlflowServer "MLflowServerComponents" {
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
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
