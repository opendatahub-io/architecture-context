workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML pipelines for model training, validation, and experimentation"

        dspo = softwareSystem "Data Science Pipelines Operator" "Namespace-scoped ML pipeline platform based on Kubeflow Pipelines 1.x with Tekton backend" {
            controller = container "DSPO Controller" "Reconciles DataSciencePipelinesApplication CRs and manages pipeline infrastructure" "Go Operator (Kubebuilder)"
            apiServer = container "API Server" "KFP API for pipeline management and execution" "Python/Go REST/gRPC Service"
            persistenceAgent = container "Persistence Agent" "Syncs pipeline run status and artifacts to database" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages cron-based pipeline scheduling" "Go Service"
            mariadb = container "MariaDB" "Pipeline metadata database (optional, default)" "MySQL Database"
            minio = container "Minio" "S3-compatible artifact storage (optional, default)" "Object Storage"
            mlmd = container "MLMD Stack" "ML Metadata tracking with gRPC and Envoy" "gRPC Services"
        }

        tekton = softwareSystem "OpenShift Pipelines (Tekton)" "Pipeline execution engine for running KFP workflows" "External Platform"
        odhDashboard = softwareSystem "ODH Dashboard" "Supported UI for pipeline management" "Internal ODH"
        elyra = softwareSystem "Elyra" "Notebook-based pipeline authoring tool" "Internal ODH"
        k8sAPI = softwareSystem "Kubernetes API Server" "OpenShift cluster API for resource management" "External Platform"
        externalS3 = softwareSystem "External S3 Storage" "AWS S3, Azure Blob, or S3-compatible storage for production artifacts" "External Service"
        externalDB = softwareSystem "External Database" "Managed database service (RDS, Azure Database) for production metadata" "External Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Optional mTLS and authorization for MLMD" "External Platform"
        certManager = softwareSystem "Service CA Operator" "TLS certificate provisioning for OAuth proxy" "External Platform"

        # Relationships
        dataScientist -> dspo "Creates pipelines via DataSciencePipelinesApplication CR"
        dataScientist -> odhDashboard "Manages pipelines via web UI"
        dataScientist -> elyra "Authors pipelines in Jupyter notebooks"

        odhDashboard -> apiServer "Fetches pipeline data" "HTTPS/8443 via Route + OAuth"
        elyra -> apiServer "Submits pipelines" "HTTPS/8443 via Route + OAuth"

        controller -> k8sAPI "Reconciles DSPA resources" "HTTPS/6443 + ServiceAccount Token"
        controller -> apiServer "Deploys and manages"
        controller -> persistenceAgent "Deploys and manages"
        controller -> scheduledWorkflow "Deploys and manages"
        controller -> mariadb "Deploys if enabled"
        controller -> minio "Deploys if enabled"
        controller -> mlmd "Deploys if enabled"

        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiServer -> minio "Stores pipeline artifacts" "S3 API/9000"
        apiServer -> externalS3 "Stores artifacts (production)" "HTTPS/443 + S3 Credentials"
        apiServer -> externalDB "Stores metadata (production)" "MySQL/PostgreSQL + TLS"
        apiServer -> tekton "Creates and manages PipelineRuns" "HTTPS/6443 via K8s API + SA Token"
        apiServer -> mlmd "Tracks ML metadata" "gRPC/8080"

        persistenceAgent -> tekton "Watches PipelineRun status" "HTTPS/6443 via K8s API"
        persistenceAgent -> mariadb "Updates run status" "MySQL/3306"

        scheduledWorkflow -> tekton "Creates scheduled runs" "HTTPS/6443 via K8s API"
        scheduledWorkflow -> mariadb "Reads schedules" "MySQL/3306"

        mlmd -> mariadb "Stores ML metadata" "MySQL/3306"
        mlmd -> serviceMesh "Optional mTLS" "Service Mesh"

        prometheus -> controller "Scrapes operator metrics" "HTTP/8080"
        certManager -> apiServer "Provisions OAuth proxy TLS certs" "Service CA"

        tekton -> minio "Stores task artifacts" "S3 API/9000"
        tekton -> externalS3 "Stores task artifacts (production)" "HTTPS/443"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
        }

        container dspo "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6ca6e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}
