workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML/data workflows"
        admin = person "Platform Admin" "Configures and operates Argo Workflows"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow engine for orchestrating parallel jobs (FIPS 140 compliant)" {
            argoServer = container "argo-server" "REST/gRPC API server and UI, OAuth2/OIDC SSO authentication" "Go, HTTPS/2746, grpc-gateway" "Deployment"
            workflowController = container "workflow-controller" "Workflow lifecycle orchestrator with leader election" "Go, HTTP/6060 health, HTTP/9090 metrics" "Deployment"
            argoexec = container "argoexec" "Workflow step/DAG executor sidecar injected into workflow Pods" "Go" "Sidecar"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        identityProvider = softwareSystem "Identity Provider" "OAuth2/OIDC SSO provider for authentication" "External"
        artifactStorage = softwareSystem "Artifact Storage" "S3/MinIO, GCS, Azure Blob, Alibaba OSS, HDFS for workflow artifacts" "External"
        archiveDatabase = softwareSystem "Archive Database" "MySQL, PostgreSQL, or SQLite for workflow archival" "External"

        # User relationships
        user -> argoServer "Creates/monitors workflows via" "HTTPS/2746, REST/gRPC"
        admin -> argoServer "Configures templates via" "HTTPS/2746, REST/gRPC"

        # Internal relationships
        argoServer -> workflowController "Shares CRD state via" "Kubernetes API watches"
        workflowController -> argoexec "Injects sidecar into" "Pod spec"

        # External relationships
        argoServer -> kubernetesAPI "RBAC enforcement, CR CRUD" "HTTPS/6443, ServiceAccount"
        argoServer -> identityProvider "OAuth2/OIDC SSO" "HTTPS, go-oidc/v3"
        workflowController -> kubernetesAPI "Watches CRs, creates Pods, ConfigMaps, Secrets, PDBs" "HTTPS/6443, ServiceAccount"
        workflowController -> archiveDatabase "Archives completed workflows" "TCP/3306 or 5432"
        argoexec -> kubernetesAPI "Reports WorkflowTaskResult" "HTTPS/6443, ServiceAccount"
        argoexec -> artifactStorage "Uploads/downloads artifacts" "HTTPS/443, provider auth"
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
            element "Deployment" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #7ed321
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
        }
    }
}
