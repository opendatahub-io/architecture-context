workspace {
    model {
        # Actors
        dataScientist = person "Data Scientist" "Creates ML pipelines and experiments using KFP SDK or notebooks"
        admin = person "Platform Admin" "Deploys and manages Data Science Pipeline instances"

        # Main System
        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages lifecycle of Kubeflow Pipelines-based ML workflow infrastructure on OpenShift" {
            # Operator Components
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and manages pipeline component lifecycle" "Go Operator" {
                tags "Operator"
            }

            # Per-DSPA Instance Components
            apiServer = container "DS Pipeline API Server" "Provides KFP v2 REST/gRPC API for pipeline/run management and artifact operations" "Go Service" {
                tags "API"
            }

            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and persists execution metadata to database" "Go Controller" {
                tags "Controller"
            }

            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline runs via ScheduledWorkflow CRs" "Go Controller" {
                tags "Controller"
            }

            argoController = container "Argo Workflow Controller" "Executes pipeline tasks as Kubernetes workflows (namespace-scoped)" "Go Controller" {
                tags "Workflow Engine"
            }

            mlmdServer = container "ML Metadata gRPC Server" "Stores artifact lineage and metadata for ML experiments" "Python/gRPC Service" {
                tags "Optional"
            }

            mlmdEnvoy = container "ML Metadata Envoy Proxy" "Provides HTTP/gRPC proxy with mTLS support for MLMD access" "Envoy Proxy" {
                tags "Optional"
            }

            mariadb = container "MariaDB" "MySQL-compatible database for pipeline metadata storage" "MariaDB 10.3+" {
                tags "Optional" "Database"
            }

            minio = container "Minio" "S3-compatible object storage for pipeline artifacts" "Minio" {
                tags "Optional" "Storage"
            }
        }

        # External Dependencies (Required)
        kubernetes = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" "External" {
            tags "Infrastructure"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline workflow execution engine (embedded, namespace-scoped)" "External" {
            tags "Infrastructure"
        }

        # External Services (Production)
        externalDB = softwareSystem "External MySQL Database" "Production-grade MySQL/MariaDB for pipeline metadata persistence" "External" {
            tags "External Service"
        }

        externalS3 = softwareSystem "External S3 Storage" "Cloud object storage (AWS S3, compatible) for pipeline artifacts" "External" {
            tags "External Service"
        }

        imageRegistry = softwareSystem "Image Registries" "Container image registry for pipeline task images" "External" {
            tags "External Service"
        }

        # Internal ODH Dependencies
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for pipeline management and visualization" "Internal ODH" {
            tags "ODH Component"
        }

        workbenches = softwareSystem "Workbenches (Notebooks)" "Jupyter notebooks for data science workflows" "Internal ODH" {
            tags "ODH Component"
        }

        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus-based monitoring for metrics collection" "Internal ODH" {
            tags "ODH Component"
        }

        odhOperator = softwareSystem "ODH Operator" "Manages OpenShift Data Hub platform components via DataScienceCluster CR" "Internal ODH" {
            tags "ODH Component"
        }

        # Relationships - User Interactions
        dataScientist -> odhDashboard "Manages pipelines via UI" "HTTPS/443"
        dataScientist -> workbenches "Develops and submits pipelines" "KFP SDK"
        admin -> dspo "Deploys pipeline instances" "kubectl/oc"

        # ODH Dashboard to DSPO
        odhDashboard -> apiServer "Manages pipelines and runs" "HTTPS/8443 (OAuth Proxy)"
        workbenches -> apiServer "Submits pipelines via KFP SDK" "HTTPS/8443 (OAuth Proxy)"

        # ODH Operator Integration
        odhOperator -> controller "Manages DSPO deployment" "DataScienceCluster CR"

        # Controller to Components
        controller -> apiServer "Creates and manages" "Kubernetes API"
        controller -> persistenceAgent "Creates and manages" "Kubernetes API"
        controller -> scheduledWorkflow "Creates and manages" "Kubernetes API"
        controller -> argoController "Creates and manages" "Kubernetes API"
        controller -> mariadb "Creates and manages (optional)" "Kubernetes API"
        controller -> minio "Creates and manages (optional)" "Kubernetes API"
        controller -> mlmdServer "Creates and manages (optional)" "Kubernetes API"
        controller -> mlmdEnvoy "Creates and manages (optional)" "Kubernetes API"

        # API Server Interactions
        apiServer -> mariadb "Persists pipeline metadata" "MySQL/3306"
        apiServer -> externalDB "Persists pipeline metadata (production)" "MySQL/3306 (TLS)"
        apiServer -> minio "Stores pipeline artifacts" "S3 API/9000"
        apiServer -> externalS3 "Stores pipeline artifacts (production)" "S3 API/443 (HTTPS)"
        apiServer -> kubernetes "Creates Workflow CRs" "HTTPS/6443"

        # Persistence Agent
        persistenceAgent -> kubernetes "Watches Workflow CRs" "HTTPS/6443"
        persistenceAgent -> mariadb "Persists execution metadata" "MySQL/3306"
        persistenceAgent -> externalDB "Persists execution metadata (production)" "MySQL/3306 (TLS)"

        # Scheduled Workflow
        scheduledWorkflow -> kubernetes "Creates scheduled Workflow CRs" "HTTPS/6443"
        scheduledWorkflow -> apiServer "Creates pipeline runs" "gRPC/8887"

        # Argo Workflow Execution
        argoController -> kubernetes "Manages workflow pods" "HTTPS/6443"
        argoWorkflows -> argoController "Workflow execution engine" "Embedded"
        argoController -> apiServer "Fetches pipeline specs" "gRPC/8887"
        argoController -> minio "Uploads/downloads artifacts" "S3 API/9000"
        argoController -> externalS3 "Uploads/downloads artifacts (production)" "S3 API/443 (HTTPS)"
        argoController -> mlmdServer "Tracks artifact lineage (optional)" "gRPC/8080"
        argoController -> imageRegistry "Pulls pipeline task images" "HTTPS/443"

        # ML Metadata
        mlmdEnvoy -> mlmdServer "Proxies with mTLS" "gRPC/8080"
        mlmdServer -> mariadb "Persists artifact metadata" "MySQL/3306"
        mlmdServer -> externalDB "Persists artifact metadata (production)" "MySQL/3306 (TLS)"

        # Monitoring
        monitoring -> controller "Collects operator metrics" "HTTP/8080"
        monitoring -> apiServer "Collects DSPA metrics (optional)" "HTTP/8888"

        # Infrastructure Dependencies
        controller -> kubernetes "Manages Kubernetes resources" "HTTPS/6443"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
            description "System context diagram for Data Science Pipelines Operator (DSPO) showing external actors, ODH components, and external services"
        }

        container dspo "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal components of DSPO and their interactions"
        }

        dynamic dspo "PipelineSubmission" "Pipeline submission flow from data scientist to execution" {
            dataScientist -> workbenches "Develops pipeline"
            workbenches -> apiServer "Submits pipeline (KFP SDK)"
            apiServer -> mariadb "Persists pipeline definition"
            apiServer -> kubernetes "Creates Workflow CR"
            kubernetes -> argoController "Notifies of new Workflow"
            argoController -> kubernetes "Creates workflow pods"
            argoController -> minio "Stores pipeline artifacts"
            persistenceAgent -> kubernetes "Watches workflow status"
            persistenceAgent -> mariadb "Persists execution metadata"
            autoLayout
            description "Dynamic diagram showing pipeline submission and execution flow"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }

            element "Person" {
                shape person
                background #08427b
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

            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }

            element "External Service" {
                background #f5a623
                color #ffffff
            }

            element "Infrastructure" {
                background #666666
                color #ffffff
            }

            element "Optional" {
                background #999999
                color #ffffff
                opacity 70
            }

            element "Operator" {
                background #4a90e2
                color #ffffff
            }

            element "API" {
                background #50e3c2
                color #000000
            }

            element "Controller" {
                background #9013fe
                color #ffffff
            }

            element "Workflow Engine" {
                background #bd10e0
                color #ffffff
            }

            element "Database" {
                shape cylinder
            }

            element "Storage" {
                shape cylinder
            }

            element "ODH Component" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
