workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML workflow pipelines for data preparation, model training, and experimentation"

        dsp = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of namespace-scoped Data Science Pipeline stacks for ML workflow orchestration" {
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and manages DSP component lifecycle" "Go Operator" "operator"

            apiServer = container "DS Pipelines API Server" "Provides KFP v1/v2 REST/gRPC API for pipeline management, execution, and artifact tracking" "Go Service" "api"

            workflowController = container "Workflow Controller" "Orchestrates pipeline execution as Kubernetes workflows (namespace-scoped Argo Workflows)" "Go Controller" "workflow"

            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow state to database for persistence and querying" "Go Worker" "agent"

            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline executions" "Go Controller" "scheduler"

            mlmdServer = container "ML Metadata gRPC Server" "Stores ML metadata and lineage information" "gRPC Service" "metadata"

            mlmdEnvoy = container "MLMD Envoy Proxy" "Provides OAuth-protected access to MLMD gRPC server" "Envoy Proxy" "proxy"

            mariadb = container "MariaDB" "Stores pipeline metadata, run history, and ML metadata" "MariaDB 10.x" "database"

            minio = container "Minio" "Stores pipeline artifacts and logs" "Minio S3" "storage"
        }

        k8s = softwareSystem "Kubernetes API Server" "Container orchestration and resource management" "External"

        openshift = softwareSystem "OpenShift OAuth" "User authentication and authorization" "External"

        serviceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate generation for pod-to-pod communication" "External"

        dashboard = softwareSystem "ODH Dashboard" "Data science platform UI for managing pipelines and deployments" "Internal ODH"

        workbenches = softwareSystem "Workbenches/Notebooks" "Jupyter-based environments for pipeline authoring" "Internal ODH"

        elyra = softwareSystem "Elyra" "Visual pipeline authoring tool" "Internal ODH"

        monitoring = softwareSystem "User Workload Monitoring" "Prometheus-based metrics collection and alerting" "Internal ODH"

        s3External = softwareSystem "External S3 Storage" "AWS S3, Google Cloud Storage, or Azure Blob Storage for artifacts" "External Service"

        dbExternal = softwareSystem "External Database" "AWS RDS, Google Cloud SQL, or Azure Database for metadata" "External Service"

        registry = softwareSystem "Container Registry" "Stores container images for pipeline steps" "External Service"

        git = softwareSystem "Git Repositories" "Stores pipeline definitions and source code" "External Service"

        # User relationships
        user -> dsp "Creates DataSciencePipelinesApplication CRs, submits pipelines via KFP SDK/UI"
        user -> workbenches "Authors pipelines in Jupyter notebooks"
        user -> elyra "Creates visual pipeline workflows"
        user -> dashboard "Manages pipelines via web UI"

        # DSP internal relationships
        controller -> k8s "Reconciles CRs, creates DSP components" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        controller -> apiServer "Deploys and configures" "Deploys via K8s API"
        controller -> workflowController "Deploys namespace-scoped instance" "Deploys via K8s API"
        controller -> persistenceAgent "Deploys" "Deploys via K8s API"
        controller -> scheduledWorkflow "Deploys" "Deploys via K8s API"
        controller -> mlmdServer "Deploys (optional)" "Deploys via K8s API"
        controller -> mlmdEnvoy "Deploys (optional)" "Deploys via K8s API"
        controller -> mariadb "Deploys (if internal)" "Deploys via K8s API"
        controller -> minio "Deploys (if internal)" "Deploys via K8s API"

        apiServer -> mariadb "Stores pipeline metadata and run history" "MySQL/3306, TLS 1.2+ optional, DB password"
        apiServer -> minio "Stores artifact references, generates signed URLs" "HTTP/9000, S3 Access Keys"
        apiServer -> s3External "Alternative: Stores artifacts in external S3" "HTTPS/443, TLS 1.2+, AWS IAM"
        apiServer -> dbExternal "Alternative: Stores metadata in external DB" "MySQL/PostgreSQL, TLS 1.2+, DB credentials"
        apiServer -> mlmdEnvoy "Records ML metadata and lineage" "gRPC/9090, TLS 1.3"
        apiServer -> workflowController "Creates Workflow CRs for pipeline execution" "gRPC/HTTP, TLS 1.3, ServiceAccount Token"

        workflowController -> k8s "Creates and manages Pipeline Pods" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        workflowController -> minio "Executes pipeline steps, reads/writes artifacts" "HTTP/9000, S3 Access Keys (via Pipeline Pods)"
        workflowController -> s3External "Alternative: Pipeline artifacts" "HTTPS/443, TLS 1.2+, AWS IAM (via Pipeline Pods)"
        workflowController -> registry "Pulls container images for pipeline steps" "HTTPS/443, TLS 1.2+, Pull Secrets"
        workflowController -> git "Fetches pipeline code and definitions" "HTTPS/443, TLS 1.2+, Git Credentials"
        workflowController -> apiServer "Reports execution status" "gRPC/8887, TLS 1.3, ServiceAccount Token"

        persistenceAgent -> k8s "Watches Workflow CRs for state changes" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        persistenceAgent -> apiServer "Syncs workflow state to database" "gRPC/8887, TLS 1.3, ServiceAccount Token"

        scheduledWorkflow -> apiServer "Triggers scheduled pipeline executions" "gRPC/8887, TLS 1.3, ServiceAccount Token"

        mlmdEnvoy -> mlmdServer "Proxies gRPC requests" "gRPC/Configurable, TLS 1.3 optional mTLS"
        mlmdServer -> mariadb "Stores ML metadata" "MySQL/3306, TLS 1.2+ optional, DB password"
        mlmdServer -> dbExternal "Alternative: Stores ML metadata" "MySQL/PostgreSQL, TLS 1.2+, DB credentials"

        # External integrations
        dashboard -> apiServer "Integrates pipeline management UI" "HTTPS/443 via Route, TLS 1.2+, OAuth2"
        workbenches -> apiServer "Submits pipelines via KFP SDK" "HTTPS/443 via Route, TLS 1.2+, OAuth2"
        elyra -> apiServer "Submits visual pipelines via KFP API" "HTTPS/443 via Route, TLS 1.2+, OAuth2"

        apiServer -> openshift "Authenticates external requests via OAuth2 Proxy" "OAuth2 token validation"
        mlmdEnvoy -> openshift "Authenticates external requests via OAuth2 Proxy" "OAuth2 token validation"

        controller -> serviceCA "Provisions TLS certificates for pod-to-pod encryption" "Service annotations"
        apiServer -> serviceCA "Receives TLS certificates" "Automatic via Service CA"
        mlmdEnvoy -> serviceCA "Receives TLS certificates" "Automatic via Service CA"
        mlmdServer -> serviceCA "Receives TLS certificates" "Automatic via Service CA"
        mariadb -> serviceCA "Receives TLS certificates (optional)" "Automatic via Service CA"

        monitoring -> controller "Scrapes operator metrics" "HTTP/8080, ServiceMonitor"
        monitoring -> workflowController "Scrapes workflow execution metrics" "HTTP/9090, ServiceMonitor"
        monitoring -> apiServer "Scrapes API server metrics" "HTTP/8888, ServiceMonitor"
    }

    views {
        systemContext dsp "SystemContext" {
            include *
            autoLayout
        }

        container dsp "Containers" {
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
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "operator" {
                background #4a90e2
                color #ffffff
            }
            element "api" {
                background #7ed321
                color #000000
            }
            element "workflow" {
                background #7ed321
                color #000000
            }
            element "agent" {
                background #50e3c2
                color #000000
            }
            element "scheduler" {
                background #50e3c2
                color #000000
            }
            element "metadata" {
                background #9013fe
                color #ffffff
            }
            element "proxy" {
                background #b8e986
                color #000000
            }
            element "database" {
                background #bd10e0
                color #ffffff
            }
            element "storage" {
                background #bd10e0
                color #ffffff
            }
        }
    }
}
