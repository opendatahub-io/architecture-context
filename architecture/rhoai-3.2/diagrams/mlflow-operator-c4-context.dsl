workspace {
    model {
        user = person "Data Scientist" "Creates experiments, logs runs, and deploys models using MLflow"
        platformAdmin = person "Platform Administrator" "Deploys and manages MLflow instances"

        mlflowOperator = softwareSystem "MLflow Operator" "Kubernetes operator for declarative MLflow instance lifecycle management" {
            controller = container "MLflow Controller" "Reconciles MLflow CRs and manages instance lifecycle" "Go (controller-runtime)" {
                reconciler = component "MLflow Reconciler" "Watches MLflow CRs and orchestrates resource creation" "Go"
                helmRenderer = component "Helm Chart Renderer" "Renders MLflow Helm charts to Kubernetes manifests" "helm.sh/helm/v3"
                consoleLinkMgr = component "ConsoleLink Manager" "Creates OpenShift console application menu links" "Go"
                httpRouteMgr = component "HTTPRoute Manager" "Creates Gateway API HTTPRoutes for ingress" "Go"
            }
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for operator health" "Go (controller-runtime)" "HTTPS/8443"
        }

        mlflowInstances = softwareSystem "MLflow Instances" "MLflow tracking servers with kubernetes-auth and TLS" {
            mlflowServer = container "MLflow Server" "Experiment tracking, model registry, and artifact management" "Python/uvicorn" {
                api = component "MLflow REST API" "REST API for experiments, runs, models, artifacts" "Python/Flask"
                webUI = component "MLflow Web UI" "Web interface for experiment tracking and model registry" "JavaScript/React"
                k8sAuth = component "Kubernetes Auth Plugin" "Validates requests via self_subject_access_review" "Python"
                artifactProxy = component "Artifact Proxy" "Proxies artifact operations to S3/PVC storage" "Python"
            }
            localStorage = container "SQLite Database" "Local backend/registry store for development" "SQLite (PVC)"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External Platform"
        serviceCA = softwareSystem "service-ca-operator" "Automatic TLS certificate provisioning for Services" "External (OpenShift)"
        gateway = softwareSystem "Gateway" "Gateway API ingress controller for HTTPRoute routing" "External (ODH/OpenShift)"
        openShiftConsole = softwareSystem "OpenShift Console" "Web console for cluster management" "External (OpenShift)"

        postgresql = softwareSystem "PostgreSQL" "Remote backend/registry store for production deployments" "External Database"
        s3Storage = softwareSystem "S3 Storage" "Remote artifact storage (AWS S3, MinIO, Ceph)" "External Storage"

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for ODH/RHOAI platform management" "Internal ODH"
        jupyterNotebooks = softwareSystem "Jupyter Notebooks" "Interactive data science notebooks with mlflow client" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration with MLflow integration" "Internal ODH"

        # User Interactions
        platformAdmin -> mlflowOperator "Creates MLflow CRs via kubectl"
        user -> mlflowInstances "Logs experiments, runs, models via mlflow client" "HTTPS/443"
        user -> mlflowInstances "Views experiments and models via web UI" "HTTPS/443"

        # Operator Interactions
        mlflowOperator -> kubernetes "Manages MLflow CRs, creates Deployments, Services, Secrets, PVCs" "HTTPS/6443"
        mlflowOperator -> serviceCA "Requests TLS certificates via Service annotation" "Service Annotation"
        mlflowOperator -> gateway "Creates HTTPRoutes for MLflow ingress" "Gateway API"
        mlflowOperator -> openShiftConsole "Creates ConsoleLinks for application menu integration" "ConsoleLink CRD"
        mlflowOperator -> mlflowInstances "Deploys and manages lifecycle"
        prometheus -> mlflowOperator "Scrapes operator metrics" "HTTPS/8443"

        # MLflow Instance Interactions
        mlflowInstances -> kubernetes "Authenticates users via self_subject_access_review" "HTTPS/6443"
        mlflowInstances -> kubernetes "Lists namespaces for workspaces feature" "HTTPS/6443"
        mlflowInstances -> postgresql "Stores experiment/model metadata" "PostgreSQL/5432"
        mlflowInstances -> s3Storage "Stores model artifacts and files" "HTTPS/443"
        gateway -> mlflowInstances "Routes HTTPS traffic to MLflow services" "HTTPS/8443"

        # ODH Integration
        odhDashboard -> mlflowInstances "Provides UI links and integration"
        jupyterNotebooks -> mlflowInstances "Logs experiments and models" "HTTPS/443"
        dataSciencePipelines -> mlflowInstances "Auto-logs pipeline runs and models" "HTTPS/443"
    }

    views {
        systemContext mlflowOperator "SystemContext" {
            include *
            autoLayout
            description "System context diagram for MLflow Operator showing external dependencies and integrations"
        }

        container mlflowOperator "OperatorContainers" {
            include *
            autoLayout
            description "Container diagram for MLflow Operator showing internal components"
        }

        container mlflowInstances "MLflowContainers" {
            include *
            autoLayout
            description "Container diagram for MLflow Instances showing server components"
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
            description "Component diagram for MLflow Controller showing internal structure"
        }

        component mlflowServer "MLflowServerComponents" {
            include *
            autoLayout
            description "Component diagram for MLflow Server showing internal components"
        }

        styles {
            element "External Platform" {
                background #326ce5
                color #ffffff
            }
            element "External (OpenShift)" {
                background #ee0000
                color #ffffff
            }
            element "External (ODH/OpenShift)" {
                background #ee0000
                color #ffffff
            }
            element "External Database" {
                background #336791
                color #ffffff
            }
            element "External Storage" {
                background #ff9900
                color #ffffff
            }
            element "External Monitoring" {
                background #e6522c
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
                background #4a90e2
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

        theme default
    }
}
