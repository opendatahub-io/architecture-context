workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML pipelines"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform"

        argoWorkflows = softwareSystem "Argo Workflows" "Container-native workflow engine for orchestrating parallel jobs on Kubernetes, used as execution backbone for Data Science Pipelines" {
            workflowController = container "workflow-controller" "Reconciles Workflow CRDs, creates pods, manages DAG/steps execution, artifact GC, cron scheduling, and workflow archival" "Go Operator" "Controller"
            argoexec = container "argoexec" "Executor sidecar injected into workflow pods for artifact staging, output collection, and container lifecycle management (emissary pattern)" "Go Sidecar" "Executor"
            argoServer = container "Argo Server" "REST/gRPC API server with web UI for workflow management (not shipped as Konflux image in RHOAI)" "Go API Server" "NotShipped"
        }

        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures Argo Workflows as the pipeline execution engine" "Internal RHOAI"
        dspAPIServer = softwareSystem "Data Science Pipelines API Server" "Creates Workflow CRDs that the workflow-controller reconciles" "Internal RHOAI"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing API server, pod scheduling, RBAC" "External"
        artifactStorage = softwareSystem "Artifact Storage" "S3-compatible / GCS / Azure Blob object storage for workflow artifacts" "External"
        sqlDatabase = softwareSystem "SQL Database" "PostgreSQL or MySQL for optional workflow archiving and node status offloading" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        containerRegistry = softwareSystem "Container Image Registry" "Hosts container images for workflow steps and executor sidecar" "External"
        oidcProvider = softwareSystem "OIDC Provider" "SSO authentication provider for Argo Server (optional)" "External"

        # Relationships - Users
        dataScientist -> dspAPIServer "Creates ML pipelines via" "HTTPS/REST"
        platformAdmin -> dspOperator "Configures via" "Kubernetes CRDs"

        # Relationships - Internal
        dspOperator -> argoWorkflows "Deploys and configures" "Kubernetes Deployment"
        dspAPIServer -> argoWorkflows "Creates Workflow CRDs" "HTTPS/443 via K8s API"

        # Relationships - Component level
        workflowController -> kubernetes "CRUD on Pods, CRDs, Leases, ConfigMaps, Secrets" "HTTPS/443 SA Token"
        workflowController -> artifactStorage "Artifact garbage collection" "HTTPS/443"
        workflowController -> sqlDatabase "Archive workflows, offload node status" "TCP/5432 or 3306"
        workflowController -> containerRegistry "Resolve container entrypoints" "HTTPS/443"
        argoexec -> kubernetes "Report WorkflowTaskResults, read pod metadata" "HTTPS/443 SA Token"
        argoexec -> artifactStorage "Upload/download workflow artifacts" "HTTPS/443 Access Key"
        prometheus -> workflowController "Scrapes metrics" "HTTP/9090"

        # Optional
        argoServer -> kubernetes "Workflow management API" "HTTPS/443"
        argoServer -> oidcProvider "SSO authentication" "HTTPS/443"
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
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Executor" {
                background #4a90e2
                color #ffffff
            }
            element "NotShipped" {
                background #cccccc
                color #666666
                border dashed
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
