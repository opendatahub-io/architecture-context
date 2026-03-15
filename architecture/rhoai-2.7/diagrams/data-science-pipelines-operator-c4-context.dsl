workspace {
    model {
        user = person "Data Scientist" "Creates, submits, and monitors ML pipelines for data preparation, training, and deployment"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages deployment and lifecycle of Data Science Pipeline instances for ML workflow orchestration" {
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and manages DSP component lifecycle" "Go Operator"

            apiServer = container "API Server" "KFP API server providing HTTP/gRPC endpoints for pipeline submission and execution" "Go Service" {
                httpAPI = component "HTTP API" "REST endpoints for pipeline management" "HTTP/8888, gRPC/8887"
                oauthProxy = component "OAuth Proxy" "Authenticates external requests via OpenShift OAuth" "HTTPS/8443"
            }

            persistenceAgent = container "Persistence Agent" "Syncs Tekton PipelineRun metadata to database for tracking" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline executions" "Go Service"
            ui = container "ML Pipelines UI" "Web UI for browsing pipelines, experiments, and runs" "React (unsupported)"

            mlmdEnvoy = container "MLMD Envoy Proxy" "Envoy proxy for ML Metadata gRPC service" "Envoy (optional)"
            mlmdServer = container "MLMD gRPC Server" "ML Metadata service for artifact lineage and metadata tracking" "gRPC (optional)"
            mlmdWriter = container "MLMD Writer" "Writes metadata to MLMD store during pipeline execution" "Python (optional)"

            mariadb = container "MariaDB" "Metadata database for pipelines, runs, experiments, and artifacts" "MariaDB 10.x (dev/test)"
            minio = container "Minio" "S3-compatible object storage for pipeline artifacts" "Minio (dev/test only)"
        }

        tekton = softwareSystem "OpenShift Pipelines (Tekton)" "Pipeline execution engine - executes DSP workflows as Tekton PipelineRuns" "External Required"
        openshift = softwareSystem "OpenShift/Kubernetes" "Container orchestration platform" "External Required"
        oauth = softwareSystem "OpenShift OAuth" "OAuth2 authentication service" "External Required"
        monitoring = softwareSystem "OpenShift Monitoring" "User workload monitoring with Prometheus" "External Required"

        dashboard = softwareSystem "ODH Dashboard" "Integrated pipeline UI experience within ODH/RHOAI" "Internal ODH"
        serviceCa = softwareSystem "OpenShift Service CA" "Auto-generates TLS certificates for services" "Internal ODH"

        externalS3 = softwareSystem "External S3 Storage" "AWS S3, Azure Blob, or S3-compatible storage for production artifact storage" "External Optional"
        externalDB = softwareSystem "External Database" "Managed MySQL/PostgreSQL for production metadata storage" "External Optional"
        registry = softwareSystem "Container Registry" "Stores pipeline task container images" "External Required"

        %% User interactions
        user -> ui "Browses pipelines and experiments via web UI" "HTTPS/443 → OAuth → 3000/TCP"
        user -> apiServer "Submits and manages pipelines via kfp-tekton SDK" "HTTPS/443 → OAuth → 8888/TCP HTTP, 8887/TCP gRPC"

        %% Controller interactions
        controller -> apiServer "Creates and manages API Server deployment" "Kubernetes API"
        controller -> persistenceAgent "Creates and manages Persistence Agent" "Kubernetes API"
        controller -> scheduledWorkflow "Creates and manages Scheduled Workflow Controller" "Kubernetes API"
        controller -> mariadb "Creates and manages MariaDB (if not external)" "Kubernetes API"
        controller -> minio "Creates and manages Minio (if not external)" "Kubernetes API"
        controller -> ui "Creates and manages UI (if enabled)" "Kubernetes API"
        controller -> mlmdEnvoy "Creates and manages MLMD components (if enabled)" "Kubernetes API"
        controller -> openshift "Watches DataSciencePipelinesApplication CRs" "Kubernetes API/443 HTTPS"

        %% API Server interactions
        apiServer -> mariadb "Stores pipeline definitions, runs, and metadata" "MySQL/3306"
        apiServer -> minio "Uploads/downloads pipeline artifacts (dev/test)" "S3 API/9000 HTTP"
        apiServer -> externalS3 "Uploads/downloads pipeline artifacts (production)" "HTTPS/443 AWS IAM"
        apiServer -> externalDB "Stores metadata (production)" "MySQL/3306 or PostgreSQL/5432 TLS optional"
        apiServer -> tekton "Creates and manages Tekton PipelineRuns" "HTTPS/443"
        apiServer -> oauth "Validates OAuth tokens for external requests" "OAuth2"

        %% UI interactions
        ui -> apiServer "Fetches pipeline data and submits runs" "HTTP/8888"
        ui -> oauth "Authenticates users via OAuth proxy" "OAuth2"

        %% Persistence Agent interactions
        persistenceAgent -> tekton "Watches PipelineRun status updates" "HTTPS/443"
        persistenceAgent -> apiServer "Syncs PipelineRun metadata" "HTTP/8888"
        persistenceAgent -> mariadb "Writes run status to database" "MySQL/3306"

        %% Scheduled Workflow interactions
        scheduledWorkflow -> apiServer "Triggers scheduled pipeline runs" "HTTP/8888"

        %% MLMD interactions
        mlmdEnvoy -> mlmdServer "Proxies gRPC requests" "gRPC/8080"
        mlmdServer -> mariadb "Stores artifact metadata and lineage" "MySQL/3306"
        mlmdWriter -> mlmdServer "Writes metadata during execution" "gRPC/8080"

        %% Tekton pipeline execution
        tekton -> minio "Pipeline tasks download/upload artifacts (dev/test)" "S3 API/9000"
        tekton -> externalS3 "Pipeline tasks download/upload artifacts (production)" "HTTPS/443"
        tekton -> mlmdEnvoy "Pipeline tasks log metadata" "gRPC/9090"
        tekton -> registry "Pulls task container images" "HTTPS/443"

        %% ODH integrations
        dashboard -> apiServer "Provides integrated pipeline UI" "HTTPS/8443 via Route"
        monitoring -> controller "Scrapes operator metrics" "HTTP/8080"
        serviceCa -> apiServer "Auto-generates TLS certs for OAuth proxy" "Certificate injection"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout lr
        }

        container dspo "Containers" {
            include *
            autoLayout lr
        }

        component apiServer "APIServerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External Required" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #000000
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
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}
