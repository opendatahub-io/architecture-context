workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and executes ML pipeline workflows for data preparation, model training, and experimentation"

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages lifecycle of Data Science Pipeline applications based on Kubeflow Pipelines" {
            controller = container "DSPO Controller" "Manages DSPA resources and reconciles DSP components" "Go Operator" {
                tags "Operator"
            }
            webhook = container "Webhook Server" "Validates and mutates PipelineVersion resources" "Go Service" {
                tags "Operator"
            }
            apiServer = container "API Server" "Main DSP API for pipeline management, execution, and artifacts" "Go Service" {
                tags "Application"
            }
            persistenceAgent = container "Persistence Agent" "Syncs workflow execution status to database" "Go Service" {
                tags "Application"
            }
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled/recurring pipeline executions" "Go Service" {
                tags "Application"
            }
            workflowController = container "Workflow Controller" "Namespace-scoped Argo Workflows controller for pipeline orchestration" "Argo Workflows 3.5.14" {
                tags "Application"
            }
            mariadb = container "MariaDB" "Metadata database for pipeline definitions and execution history" "MariaDB 10.3+" {
                tags "Storage"
            }
            minio = container "Minio" "S3-compatible object storage for pipeline artifacts (dev/test only)" "Minio" {
                tags "Storage"
            }
            mlmdGrpc = container "ML Metadata gRPC" "ML Metadata service for artifact lineage tracking" "gRPC Service" {
                tags "Optional"
            }
            mlmdEnvoy = container "MLMD Envoy" "Envoy proxy for ML Metadata with OAuth authentication" "Envoy Proxy" {
                tags "Optional"
            }
            ui = container "ML Pipelines UI" "Upstream KFP UI for pipeline visualization (unsupported)" "Web App" {
                tags "Optional"
            }
        }

        k8s = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External" {
            tags "Infrastructure"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow orchestration engine for DSP v2" "External" {
            tags "Infrastructure"
        }

        externalS3 = softwareSystem "External S3 Storage" "S3-compatible object storage for production pipeline artifacts" "External" {
            tags "External Service"
        }

        externalDB = softwareSystem "External MySQL/MariaDB" "External database for production metadata storage" "External" {
            tags "External Service"
        }

        oauthProxy = softwareSystem "OpenShift OAuth" "Authentication service for external access" "External" {
            tags "Infrastructure"
        }

        kserve = softwareSystem "KServe" "Model serving platform for ML inference" "Internal ODH" {
            tags "ODH Component"
        }

        ray = softwareSystem "Ray" "Distributed computing framework for ML workloads" "Internal ODH" {
            tags "ODH Component"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "OpenShift AI / ODH web dashboard" "Internal ODH" {
            tags "ODH Component"
        }

        containerRegistry = softwareSystem "Container Registry" "Stores pipeline step container images" "External" {
            tags "External Service"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External" {
            tags "Infrastructure"
        }

        // User interactions
        dataScientist -> dspo "Creates/manages pipelines via API, submits pipeline runs" "HTTPS/443 OAuth"
        dataScientist -> odhDashboard "Accesses DSP UI integration" "HTTPS"

        // DSPO internal relationships
        controller -> webhook "Manages lifecycle"
        controller -> apiServer "Deploys and configures"
        controller -> persistenceAgent "Deploys and configures"
        controller -> scheduledWorkflow "Deploys and configures"
        controller -> workflowController "Deploys and configures"
        controller -> mariadb "Deploys (optional)"
        controller -> minio "Deploys (optional)"
        controller -> mlmdGrpc "Deploys (optional)"
        controller -> mlmdEnvoy "Deploys (optional)"
        controller -> ui "Deploys (optional)"

        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiServer -> minio "Stores artifacts" "S3 API/9000"
        apiServer -> mlmdGrpc "Records metadata" "gRPC/8080"
        apiServer -> workflowController "Creates workflows"

        persistenceAgent -> mariadb "Syncs execution status" "MySQL/3306"
        persistenceAgent -> workflowController "Watches workflows"

        scheduledWorkflow -> workflowController "Creates scheduled runs"

        mlmdEnvoy -> mlmdGrpc "Proxies with OAuth"
        mlmdGrpc -> mariadb "Stores lineage" "MySQL/3306"

        workflowController -> minio "Artifact I/O" "S3 API"
        workflowController -> mlmdGrpc "Records lineage" "gRPC"

        // External dependencies
        controller -> k8s "Manages resources via API" "HTTPS/6443"
        apiServer -> k8s "Creates workflows and pods" "HTTPS/6443"
        persistenceAgent -> k8s "Watches workflow status" "HTTPS/6443"
        scheduledWorkflow -> k8s "Creates scheduled workflows" "HTTPS/6443"
        workflowController -> k8s "Orchestrates pipeline pods" "HTTPS/6443"
        webhook -> k8s "Validates/mutates CRs" "HTTPS/6443"

        workflowController -> argoWorkflows "Uses for workflow execution" "In-Process"

        dspo -> oauthProxy "Authenticates external access" "OAuth2/443"

        // Alternative external storage
        apiServer -> externalS3 "Stores artifacts (production)" "HTTPS/443"
        apiServer -> externalDB "Stores metadata (production)" "MySQL/3306"
        workflowController -> externalS3 "Artifact I/O (production)" "HTTPS/443"
        persistenceAgent -> externalDB "Syncs status (production)" "MySQL/3306"
        mlmdGrpc -> externalDB "Stores lineage (production)" "MySQL/3306"

        // Integration points
        apiServer -> kserve "Deploys models from pipelines" "K8s API"
        apiServer -> ray "Executes distributed tasks" "K8s API"
        odhDashboard -> apiServer "DSP UI integration" "HTTPS"

        workflowController -> containerRegistry "Pulls pipeline step images" "HTTPS/443"

        controller -> prometheus "Exposes metrics" "HTTP/8080"
        apiServer -> prometheus "Exposes metrics" "HTTP"
        workflowController -> prometheus "Exposes metrics" "HTTP/9090"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout lr
        }

        container dspo "Containers" {
            include *
            autoLayout tb
        }

        styles {
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "ODH Component" {
                background #7ed321
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Application" {
                background #7ed321
                color #ffffff
            }
            element "Storage" {
                background #e8e8e8
                color #333333
            }
            element "Optional" {
                background #d5e8d4
                color #333333
                stroke #82b366
                strokeWidth 2
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
