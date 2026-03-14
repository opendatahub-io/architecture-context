workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML workflows for experimentation and model training"

        dspo = softwareSystem "Data Science Pipelines Operator" "Kubernetes operator that deploys and manages namespace-scoped ML pipeline infrastructure based on Kubeflow Pipelines" {
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and manages pipeline component lifecycle" "Go Operator" {
                tags "Operator"
            }
            apiServer = container "DS Pipeline API Server" "Provides KFP v2 REST/gRPC API for pipeline/run management and artifact retrieval" "Go Service" {
                tags "API"
            }
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and persists execution metadata to database" "Go Controller" {
                tags "Controller"
            }
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline runs via ScheduledWorkflow CRs" "Go Controller" {
                tags "Controller"
            }
            argoController = container "Argo Workflow Controller" "Executes pipeline tasks as Kubernetes workflows (namespace-scoped)" "Go Controller" {
                tags "WorkflowEngine"
            }
            mlmdServer = container "ML Metadata gRPC Server" "Stores artifact lineage and metadata for ML experiments" "Python gRPC Service" {
                tags "Metadata"
            }
            mlmdEnvoy = container "ML Metadata Envoy Proxy" "Provides HTTP/gRPC proxy with mTLS support for MLMD access" "Envoy Proxy" {
                tags "Proxy"
            }
        }

        # External systems
        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration platform API" "External"
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine (embedded namespace-scoped)" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes platform with OAuth, Routes, and monitoring" "External"

        # Storage systems
        externalDB = softwareSystem "External MySQL/MariaDB" "Production database for pipeline metadata persistence" "External"
        externalS3 = softwareSystem "External S3 Storage" "Production object storage for pipeline artifacts (AWS S3 or compatible)" "External"
        mariadb = softwareSystem "MariaDB" "Optional MySQL-compatible database for dev/test pipeline metadata" "Internal Optional"
        minio = softwareSystem "Minio" "Optional S3-compatible object storage for dev/test artifacts" "Internal Optional"

        # ODH ecosystem
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing pipelines, workbenches, and ODH components" "Internal ODH"
        workbenches = softwareSystem "Workbenches (Notebooks)" "Jupyter notebook environments with KFP SDK for pipeline development" "Internal ODH"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus-based monitoring for metrics collection" "Internal ODH"
        kserve = softwareSystem "KServe" "ML inference serving platform (optional integration)" "Internal ODH"

        # Relationships - User interactions
        user -> dashboard "Manages pipelines via UI" "HTTPS/443"
        user -> workbenches "Develops and submits pipelines" "KFP SDK"
        user -> apiServer "Submits pipelines, views runs" "HTTPS/443 (OAuth)"

        # DSPO internal relationships
        controller -> apiServer "Creates and manages" "Kubernetes"
        controller -> persistenceAgent "Creates and manages" "Kubernetes"
        controller -> scheduledWorkflow "Creates and manages" "Kubernetes"
        controller -> argoController "Creates and manages" "Kubernetes"
        controller -> mlmdServer "Creates and manages (optional)" "Kubernetes"
        controller -> mlmdEnvoy "Creates and manages (optional)" "Kubernetes"
        controller -> mariadb "Creates and manages (optional)" "Kubernetes"
        controller -> minio "Creates and manages (optional)" "Kubernetes"

        # API Server interactions
        apiServer -> externalDB "Stores pipeline metadata" "MySQL/3306"
        apiServer -> mariadb "Stores pipeline metadata (dev/test)" "MySQL/3306"
        apiServer -> externalS3 "Stores/retrieves artifacts" "HTTPS/443 (S3 API)"
        apiServer -> minio "Stores/retrieves artifacts (dev/test)" "HTTP/9000 (S3 API)"
        apiServer -> kubernetes "Creates Workflow CRs" "HTTPS/6443"

        # Workflow execution
        argoController -> kubernetes "Watches Workflow CRs, creates pods" "HTTPS/6443"
        argoController -> externalS3 "Pipeline tasks store artifacts" "HTTPS/443"
        argoController -> minio "Pipeline tasks store artifacts (dev/test)" "HTTP/9000"
        argoController -> mlmdServer "Logs artifact lineage" "gRPC/8080"

        # Persistence and scheduling
        persistenceAgent -> kubernetes "Watches Workflow CRs" "HTTPS/6443"
        persistenceAgent -> apiServer "Fetches workflow details" "gRPC/8887"
        persistenceAgent -> externalDB "Persists execution metadata" "MySQL/3306"
        persistenceAgent -> mariadb "Persists execution metadata (dev/test)" "MySQL/3306"
        scheduledWorkflow -> apiServer "Creates scheduled runs" "gRPC/8887"
        scheduledWorkflow -> kubernetes "Watches ScheduledWorkflow CRs" "HTTPS/6443"

        # MLMD interactions
        mlmdEnvoy -> mlmdServer "Proxies MLMD requests with auth" "gRPC/8080"
        mlmdServer -> externalDB "Stores metadata" "MySQL/3306"
        mlmdServer -> mariadb "Stores metadata (dev/test)" "MySQL/3306"

        # ODH integrations
        dashboard -> apiServer "Pipeline management UI" "HTTPS/8443"
        workbenches -> apiServer "Pipeline submission via KFP SDK" "HTTPS/8443"
        monitoring -> controller "Scrapes operator metrics" "HTTP/8080"
        monitoring -> apiServer "Scrapes pipeline metrics" "HTTP/8888"
        apiServer -> kserve "Deploys inference services (optional)" "Kubernetes API"

        # External dependencies
        controller -> kubernetes "Resource management (CRUD operations)" "HTTPS/6443"
        controller -> openshift "Creates Routes, uses OAuth" "Kubernetes API"
        apiServer -> openshift "OAuth authentication" "OAuth/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal Optional" {
                background #9013fe
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "API" {
                background #4a90e2
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "WorkflowEngine" {
                background #50e3c2
                color #000000
            }
            element "Metadata" {
                background #50e3c2
                color #000000
            }
            element "Proxy" {
                background #f5a623
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
