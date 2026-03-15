workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML pipeline workflows for data preparation, model training, and experimentation"

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages lifecycle of Data Science Pipeline applications based on Kubeflow Pipelines" {
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and deploys pipeline infrastructure" "Go Operator" {
                tags "Operator"
            }
            apiServer = container "DS Pipeline API Server" "Provides KFP v2 REST/gRPC API for pipeline management, artifact retrieval, and workflow orchestration" "Go Service" {
                tags "API"
            }
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and persists execution metadata to database" "Go Controller" {
                tags "Controller"
            }
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline runs via ScheduledWorkflow CRs" "Go Controller" {
                tags "Controller"
            }
            argoController = container "Argo Workflow Controller" "Executes pipeline tasks as Kubernetes workflows (namespace-scoped)" "Go Workflow Engine" {
                tags "WorkflowEngine"
            }
            mlmdServer = container "ML Metadata gRPC Server" "Stores artifact lineage and metadata for ML experiments" "Python gRPC Service" {
                tags "Optional"
            }
            mlmdEnvoy = container "ML Metadata Envoy Proxy" "Provides HTTP/gRPC proxy with mTLS and OAuth support for MLMD access" "Envoy Proxy" {
                tags "Optional"
            }
            mariadb = container "MariaDB" "MySQL-compatible database for pipeline metadata storage" "MariaDB" {
                tags "Database" "Optional"
            }
            minio = container "Minio" "S3-compatible object storage for pipeline artifacts" "Minio" {
                tags "Storage" "Optional"
            }
        }

        k8s = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" {
            tags "Platform"
        }

        argo = softwareSystem "Argo Workflows" "Workflow execution engine embedded in DSPO" {
            tags "Platform"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for pipeline management and visualization" {
            tags "Internal ODH"
        }

        workbenches = softwareSystem "Workbenches (Notebooks)" "Jupyter notebooks for data science development" {
            tags "Internal ODH"
        }

        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus-based monitoring and metrics collection" {
            tags "Platform"
        }

        externalS3 = softwareSystem "External S3 Storage" "AWS S3 or S3-compatible object storage for production artifact storage" {
            tags "External Service"
        }

        externalDB = softwareSystem "External MySQL/MariaDB" "External managed database for production metadata persistence" {
            tags "External Service"
        }

        imageRegistry = softwareSystem "Image Registries" "Container image storage (quay.io, registry.redhat.io)" {
            tags "External Service"
        }

        // User interactions
        user -> dspo "Creates DataSciencePipelinesApplication CR, submits pipelines, monitors runs" "kubectl/KFP SDK/UI"
        user -> odhDashboard "Manages pipelines via web UI" "HTTPS"
        user -> workbenches "Develops and submits pipelines using KFP SDK" "HTTPS"

        // ODH component interactions
        odhDashboard -> dspo "Pipeline management API calls" "HTTPS/8443 (OAuth)"
        workbenches -> dspo "Submit pipelines, query runs" "HTTPS/8443 (OAuth)"

        // Controller interactions
        controller -> k8s "Manages DSPA resources, deployments, services, routes" "HTTPS/6443 (ServiceAccount Token)"
        apiServer -> k8s "Creates and manages Workflow CRs" "HTTPS/6443 (ServiceAccount Token)"
        persistenceAgent -> k8s "Watches Workflow CRs for status updates" "HTTPS/6443 (ServiceAccount Token)"
        scheduledWorkflow -> k8s "Creates scheduled Workflow CRs" "HTTPS/6443 (ServiceAccount Token)"
        argoController -> k8s "Manages workflow task pods" "HTTPS/6443 (ServiceAccount Token)"

        // Data flow
        apiServer -> mariadb "Stores pipeline metadata (runs, experiments, artifacts)" "MySQL/3306"
        apiServer -> minio "Stores pipeline artifacts (dev/test)" "HTTP/9000 (S3 API)"
        apiServer -> externalS3 "Stores pipeline artifacts (production)" "HTTPS/443 (S3 API)"
        apiServer -> externalDB "Stores pipeline metadata (production)" "MySQL/3306"

        persistenceAgent -> mariadb "Persists workflow execution metadata" "MySQL/3306"
        persistenceAgent -> apiServer "Fetches workflow details" "gRPC/8887"

        mlmdServer -> mariadb "Stores ML metadata and lineage" "MySQL/3306"
        mlmdEnvoy -> mlmdServer "Proxies MLMD requests with auth" "gRPC/8080"

        // Workflow execution
        argoController -> argo "Executes pipeline tasks as workflows" "Internal"
        argo -> k8s "Creates ephemeral task pods" "HTTPS/6443"

        // External dependencies
        k8s -> imageRegistry "Pulls container images for pipeline tasks" "HTTPS/443"

        // Monitoring
        monitoring -> controller "Scrapes operator metrics" "HTTP/8080"
        monitoring -> apiServer "Scrapes API server metrics" "HTTP/8888"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Platform" {
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
            element "Container" {
                background #438dd5
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
                background #5b9bd5
                color #ffffff
            }
            element "WorkflowEngine" {
                background #70ad47
                color #ffffff
            }
            element "Database" {
                background #ed7d31
                color #ffffff
            }
            element "Storage" {
                background #ffc000
                color #000000
            }
            element "Optional" {
                border dashed
            }
        }
    }
}
