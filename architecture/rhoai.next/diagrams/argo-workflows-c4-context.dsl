workspace {
    model {
        dspOperator = person "DSP Operator" "Data Science Pipelines Operator - deploys and configures Argo Workflows components"
        datascientist = person "Data Scientist" "Creates ML pipelines via DSP API"

        argoWorkflows = softwareSystem "Argo Workflows" "Kubernetes-native workflow engine for orchestrating parallel ML pipeline jobs (RHOAI distribution)" {
            workflowController = container "workflow-controller" "Watches Workflow CRDs, creates and manages step Pods, handles scheduling/retry/artifact GC/archival" "Go Kubernetes Controller" {
                tags "RHOAI Shipped"
            }
            argoexec = container "argoexec" "Executor sidecar injected into workflow pods; manages artifacts, captures outputs, reports results via WorkflowTaskResult CRD" "Go Sidecar (FIPS + non-FIPS binaries)" {
                tags "RHOAI Shipped"
            }
            argoServer = container "argo (CLI/Server)" "API server with gRPC/REST endpoints and web UI — NOT shipped in RHOAI" "Go API Server" {
                tags "Not Shipped"
            }
        }

        dspApiServer = softwareSystem "DSP API Server" "Data Science Pipelines API Server - creates Workflow CRs for pipeline runs" {
            tags "Internal RHOAI"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform - API Server for CRD management, Pod lifecycle" {
            tags "Infrastructure"
        }

        artifactStore = softwareSystem "Artifact Repository" "S3-compatible (MinIO/AWS S3), GCS, or Azure Blob Storage for workflow artifacts" {
            tags "External"
        }

        sqlDatabase = softwareSystem "SQL Database" "MySQL 5.7+ or PostgreSQL 12+ for workflow archival and node status offloading (optional)" {
            tags "External"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "Infrastructure"
        }

        oidcProvider = softwareSystem "OIDC Provider" "SSO token validation for Argo Server (not applicable in RHOAI)" {
            tags "External"
        }

        # Relationships
        dspOperator -> argoWorkflows "Deploys workflow-controller, configures argoexec image reference"
        datascientist -> dspApiServer "Submits ML pipelines via DSP UI/API"
        dspApiServer -> kubernetes "Creates Workflow CRs" "HTTPS/443, SA Token"
        kubernetes -> workflowController "Watch notifications (Workflow, CronWorkflow, WorkflowTemplate CRDs)" "HTTPS, Informer pattern"
        workflowController -> kubernetes "CRUD Pods, PVCs, ConfigMaps, PDBs, Events, Leases" "HTTPS/443, SA Token"
        workflowController -> artifactStore "Artifact garbage collection" "HTTPS/443, IAM/AccessKey"
        workflowController -> sqlDatabase "Workflow archival, node status offloading" "TCP/3306 or 5432, Password"
        argoexec -> kubernetes "Create WorkflowTaskResult CRs, read Secrets/ConfigMaps" "HTTPS/443, SA Token"
        argoexec -> artifactStore "Upload/download workflow artifacts" "HTTPS/443, IAM/AccessKey"
        prometheus -> workflowController "Scrape metrics" "HTTP/9090"
        argoServer -> oidcProvider "SSO token validation (not in RHOAI)" "HTTPS/443, OAuth2"
    }

    views {
        systemContext argoWorkflows "SystemContext" {
            include *
            autoLayout
            description "System context diagram for Argo Workflows in the RHOAI platform"
        }

        container argoWorkflows "Containers" {
            include *
            autoLayout
            description "Container diagram showing Argo Workflows internal components"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "RHOAI Shipped" {
                background #4a90e2
                color #ffffff
            }
            element "Not Shipped" {
                background #cccccc
                color #333333
                border dashed
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #333333
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
        }
    }
}
