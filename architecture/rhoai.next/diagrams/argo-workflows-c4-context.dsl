workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML pipeline workflows"
        dspOperator = person "DSP Operator" "Deploys and configures Argo Workflows components" "Operator"

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for Data Science Pipelines in RHOAI" {
            workflowController = container "workflow-controller" "Reconciles Workflow CRs, manages pod lifecycle, handles artifact GC, cron scheduling, and workflow archival" "Go Controller (Deployment)"
            argoexec = container "argoexec" "Sidecar injected into workflow pods for artifact collection, script execution, and container lifecycle" "Go Sidecar Binary"
            argoServer = container "argo-server" "gRPC/REST API, web UI, artifact browsing, SSO authentication (optional)" "Go API Server (Deployment)"
            argoCli = container "argo CLI" "Command-line client for workflow submission and management" "Go CLI"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "External"
        dspOperatorSystem = softwareSystem "Data Science Pipelines Operator" "Deploys and configures workflow-controller and argoexec" "Internal RHOAI"
        artifactStore = softwareSystem "Artifact Store" "S3/MinIO/GCS/Azure Blob storage for workflow artifacts" "External"
        sqlDatabase = softwareSystem "SQL Database" "MySQL/PostgreSQL for optional workflow archival" "External"
        oidcProvider = softwareSystem "OIDC Provider" "SSO authentication provider for argo-server" "External"
        argoEvents = softwareSystem "Argo Events" "Event-driven workflow triggering" "External"

        # User interactions
        user -> argoWorkflows "Submits and manages workflows"
        user -> argoCli "Uses CLI for workflow operations"
        argoCli -> argoServer "Connects via gRPC/REST" "gRPC/2746"

        # Internal container relationships
        workflowController -> kubernetesAPI "Watches Workflow CRs, creates pods, updates status" "HTTPS/6443"
        argoexec -> kubernetesAPI "Reports WorkflowTaskResult, reads config" "HTTPS/6443"
        argoexec -> artifactStore "Uploads/downloads workflow artifacts" "HTTPS/443"
        argoServer -> kubernetesAPI "Queries workflows and resources" "HTTPS/6443"
        argoServer -> sqlDatabase "Queries archived workflows" "TCP/3306 or 5432"
        argoServer -> oidcProvider "SSO authentication" "HTTPS/443"
        workflowController -> sqlDatabase "Archives completed workflows" "TCP/3306 or 5432"

        # External system interactions
        dspOperatorSystem -> argoWorkflows "Deploys and configures controller and executor images"
        argoServer -> argoEvents "Proxies EventSource and Sensor APIs" "gRPC"
    }

    views {
        systemContext argoWorkflows "SystemContext" {
            include *
            autoLayout
        }

        container argoWorkflows "Containers" {
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
            element "Operator" {
                shape Robot
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
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
