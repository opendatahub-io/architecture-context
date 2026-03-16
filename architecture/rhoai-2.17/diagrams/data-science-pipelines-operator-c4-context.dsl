workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML pipeline workflows for data preparation, training, and validation"

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages lifecycle of Data Science Pipelines instances through custom resources on OpenShift/Kubernetes clusters" {
            controller = container "DSPO Controller Manager" "Reconciles DSPA CRs and manages pipeline component lifecycle" "Go Operator" {
                tags "Operator"
            }
            apiServer = container "DS Pipelines API Server" "RESTful/gRPC API server for pipeline management and execution" "Go Service" {
                tags "API"
            }
            persistenceAgent = container "Persistence Agent" "Syncs workflow state from Argo to database" "Go Service" {
                tags "Agent"
            }
            workflowController = container "Workflow Controller" "Namespace-scoped Argo Workflow controller for pipeline orchestration" "Argo Workflows" {
                tags "Controller"
            }
            scheduledWF = container "Scheduled Workflow Controller" "Manages scheduled/recurring pipeline runs" "Go Service" {
                tags "Controller"
            }
            mariadb = container "MariaDB" "MySQL-compatible database for pipeline metadata storage" "MariaDB StatefulSet" {
                tags "Database"
            }
            minio = container "Minio" "S3-compatible object storage for pipeline artifacts" "Minio Deployment" {
                tags "Storage"
            }
            mlmd = container "ML Metadata gRPC" "gRPC service for ML metadata artifact lineage tracking" "Python Service" {
                tags "Metadata"
            }
            ui = container "ML Pipelines UI" "Web interface for pipeline visualization and management" "React App" {
                tags "UI"
            }
        }

        # External Systems - Required
        k8s = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" "External" {
            tags "External" "Platform"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine (embedded, namespace-scoped)" "External" {
            tags "External" "Embedded"
        }

        # External Systems - Optional
        externalS3 = softwareSystem "External S3 Storage" "AWS S3, MinIO, or S3-compatible object storage" "External" {
            tags "External" "Storage"
        }

        externalDB = softwareSystem "External MySQL Database" "RDS, Cloud SQL, or MySQL-compatible database" "External" {
            tags "External" "Database"
        }

        # Internal ODH Dependencies
        odhDashboard = softwareSystem "ODH Dashboard" "Provides UI integration for pipeline management" "Internal ODH" {
            tags "Internal" "ODH"
        }

        openshiftOAuth = softwareSystem "OpenShift OAuth" "Authentication and authorization for external API access" "Internal ODH" {
            tags "Internal" "OAuth"
        }

        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Generates service-serving certificates for internal TLS" "Internal ODH" {
            tags "Internal" "Security"
        }

        prometheus = softwareSystem "User Workload Monitoring" "Prometheus metrics collection for operator and pipeline components" "Internal ODH" {
            tags "Internal" "Monitoring"
        }

        containerRegistry = softwareSystem "Container Registry" "Quay, Docker Hub, or registry.redhat.io" "External" {
            tags "External" "Registry"
        }

        # User Interactions
        user -> dspo "Creates DataSciencePipelinesApplication CR via kubectl/UI"
        user -> apiServer "Submits and manages pipelines via KFP SDK or UI" "gRPC/HTTP 8887/8888"
        user -> ui "Visualizes and manages pipelines" "HTTPS/443"

        # Container Relationships
        controller -> apiServer "Creates and manages" "Kubernetes API"
        controller -> persistenceAgent "Creates and manages" "Kubernetes API"
        controller -> workflowController "Creates and manages" "Kubernetes API"
        controller -> scheduledWF "Creates and manages" "Kubernetes API"
        controller -> mariadb "Creates and manages (optional)" "Kubernetes API"
        controller -> minio "Creates and manages (optional)" "Kubernetes API"
        controller -> mlmd "Creates and manages (optional)" "Kubernetes API"
        controller -> ui "Creates and manages (optional)" "Kubernetes API"

        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiServer -> workflowController "Creates Workflow CRs" "HTTP/8080"
        apiServer -> externalDB "Stores pipeline metadata (if configured)" "MySQL/3306"

        workflowController -> k8s "Creates pipeline execution pods" "HTTPS/6443"

        persistenceAgent -> apiServer "Queries workflow state" "gRPC/8887"
        persistenceAgent -> mariadb "Persists workflow state" "MySQL/3306"

        scheduledWF -> workflowController "Creates scheduled workflows" "Kubernetes API"

        mlmd -> mariadb "Stores ML metadata" "MySQL/3306"

        # External Dependencies
        dspo -> k8s "Uses for resource management" "HTTPS/6443"
        dspo -> argoWorkflows "Uses for workflow execution orchestration" "Embedded"
        dspo -> openshiftOAuth "Uses for external API authentication" "OAuth2 Proxy"
        dspo -> openshiftServiceCA "Uses for TLS certificate generation" "Service CA"
        dspo -> odhDashboard "Integrates with for UI management" "Route/API"
        dspo -> prometheus "Exposes metrics to" "HTTP/8080"
        dspo -> externalS3 "Stores and retrieves artifacts (optional)" "HTTPS/443"
        dspo -> externalDB "Persists metadata (optional)" "MySQL/3306"
        dspo -> containerRegistry "Pulls component images" "HTTPS/443"

        # Pipeline Execution Flows
        apiServer -> minio "Generates signed URLs for artifacts" "HTTP/9000"
        apiServer -> externalS3 "Generates signed URLs for artifacts (if configured)" "HTTPS/443"

        # ML Metadata Flows
        apiServer -> mlmd "Tracks artifact lineage" "gRPC/8080"
    }

    views {
        systemContext dspo "DSPOSystemContext" {
            include *
            autoLayout
            description "System context diagram for Data Science Pipelines Operator showing external systems and users"
        }

        container dspo "DSPOContainers" {
            include *
            autoLayout
            description "Container diagram showing internal components of Data Science Pipelines Operator"
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

            element "Internal" {
                background #7ed321
                color #ffffff
            }

            element "ODH" {
                background #50e3c2
                color #000000
            }

            element "Platform" {
                background #f5a623
                color #ffffff
            }

            element "Embedded" {
                background #bd10e0
                color #ffffff
            }

            element "Operator" {
                background #4a90e2
                color #ffffff
            }

            element "API" {
                background #7ed321
                color #ffffff
            }

            element "Database" {
                background #bd10e0
                color #ffffff
            }

            element "Storage" {
                background #f5a623
                color #ffffff
            }

            element "UI" {
                background #50e3c2
                color #000000
            }
        }

        theme default
    }
}
