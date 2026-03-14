workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and executes ML pipeline workflows for data preparation, model training, and experimentation"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Data Science Pipeline applications on OpenShift/Kubernetes clusters" {
            controller = container "DSPO Controller" "Reconciles DataSciencePipelinesApplication CRs and deploys DSP components" "Go Operator" {
                tags "Operator"
            }
            webhookServer = container "Webhook Server" "Validates and mutates PipelineVersion resources" "Go Service" {
                tags "Operator"
            }
        }

        dspaInstance = softwareSystem "DSPA Instance" "Namespace-scoped Data Science Pipeline stack for executing ML workflows" {
            apiServer = container "API Server" "Main DSP API for pipeline management, execution, and artifact access" "Go Service" {
                tags "Application"
            }
            workflowController = container "Argo Workflow Controller" "Namespace-scoped controller for pipeline orchestration" "Go Controller" {
                tags "Application"
            }
            persistenceAgent = container "Persistence Agent" "Syncs workflow execution status to database" "Go Service" {
                tags "Application"
            }
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled/recurring pipeline executions" "Go Service" {
                tags "Application"
            }
            mlmdGrpc = container "MLMD gRPC Server" "ML Metadata service for artifact lineage tracking" "Go Service" {
                tags "Application"
            }
            mariadb = container "MariaDB" "Metadata database for pipeline definitions and execution history" "MariaDB 10.3+" {
                tags "Database"
            }
            minio = container "Minio" "S3-compatible object storage for pipeline artifacts" "Minio" {
                tags "Storage"
            }
            ui = container "ML Pipelines UI" "Upstream KFP UI for pipeline visualization" "React Frontend" {
                tags "UI"
            }
        }

        k8s = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" {
            tags "External"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow orchestration engine for DSP v2" {
            tags "External"
        }

        externalS3 = softwareSystem "External S3 Storage" "Production artifact storage (AWS S3 or compatible)" {
            tags "External"
        }

        externalDB = softwareSystem "External Database" "Production metadata database (MySQL/MariaDB)" {
            tags "External"
        }

        containerRegistry = softwareSystem "Container Registry" "Source for pipeline step container images" {
            tags "External"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "Open Data Hub web console for DSP UI integration" {
            tags "Internal ODH"
        }

        kserve = softwareSystem "KServe" "Model serving platform for ML inference" {
            tags "Internal ODH"
        }

        ray = softwareSystem "Ray" "Distributed computing framework for ML workloads" {
            tags "Internal ODH"
        }

        serviceMesh = softwareSystem "Service Mesh (Istio)" "Service mesh for mTLS and traffic management" {
            tags "Internal ODH"
        }

        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" {
            tags "Internal ODH"
        }

        oauthProxy = softwareSystem "OpenShift OAuth" "Authentication and authorization service" {
            tags "External"
        }

        // User interactions
        dataScientist -> dspaInstance "Creates and manages ML pipelines via API or UI" "HTTPS/443 OAuth"
        dataScientist -> odhDashboard "Accesses DSP UI through ODH Dashboard" "HTTPS/443"

        // DSPO to DSPA
        controller -> k8s "Watches DataSciencePipelinesApplication CRs" "HTTPS/6443 TLS1.2+"
        controller -> dspaInstance "Deploys and manages DSPA components" "Kubernetes API"
        webhookServer -> k8s "Validates/mutates PipelineVersion CRs" "HTTPS/8443 TLS1.2+"

        // DSPA internal dependencies
        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiServer -> minio "Stores pipeline artifacts" "HTTP/9000"
        apiServer -> mlmdGrpc "Tracks artifact lineage (optional)" "gRPC/8080"
        apiServer -> k8s "Creates Workflow CRs" "HTTPS/6443 TLS1.2+"

        workflowController -> k8s "Watches Workflows, creates pods" "HTTPS/6443 TLS1.2+"
        persistenceAgent -> k8s "Watches Workflow status" "HTTPS/6443 TLS1.2+"
        persistenceAgent -> mariadb "Syncs execution status" "MySQL/3306"
        scheduledWorkflow -> k8s "Creates scheduled Workflows" "HTTPS/6443 TLS1.2+"

        mlmdGrpc -> mariadb "Stores metadata" "MySQL/3306"

        // External dependencies
        apiServer -> externalS3 "Uses for production artifact storage (optional)" "HTTPS/443 TLS1.2+"
        apiServer -> externalDB "Uses for production metadata (optional)" "MySQL/3306 TLS1.2+"

        workflowController -> argoWorkflows "Leverages Argo for workflow orchestration" "In-cluster"
        workflowController -> containerRegistry "Pulls pipeline step images" "HTTPS/443 TLS1.2+"

        // Integration points
        odhDashboard -> apiServer "Provides DSP UI integration" "HTTPS/443 OAuth"
        apiServer -> kserve "Deploys inference services from pipelines" "Kubernetes API"
        apiServer -> ray "Launches distributed compute jobs" "Kubernetes API"

        apiServer -> oauthProxy "Authenticates external requests" "OAuth2"
        dspaInstance -> serviceMesh "Optional mTLS integration" "Service Mesh"

        controller -> prometheus "Exposes metrics" "HTTP/8080"
        apiServer -> prometheus "Exposes metrics" "HTTP/8080"
    }

    views {
        systemContext dspo "DSPOSystemContext" {
            include *
            autoLayout lr
        }

        systemContext dspaInstance "DSPASystemContext" {
            include *
            autoLayout lr
        }

        container dspo "DSPOContainers" {
            include *
            autoLayout lr
        }

        container dspaInstance "DSPAContainers" {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Application" {
                background #50e3c2
                color #000000
            }
            element "Database" {
                shape cylinder
                background #e8e8e8
                color #000000
            }
            element "Storage" {
                shape cylinder
                background #f5a623
                color #ffffff
            }
            element "UI" {
                background #bd10e0
                color #ffffff
            }
        }
    }
}
