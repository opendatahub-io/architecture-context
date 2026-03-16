workspace {
    model {
        user = person "Data Scientist" "Creates and executes ML pipelines for experimentation and production workflows"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of namespace-scoped Data Science Pipelines instances for ML workflow orchestration" {
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and manages component lifecycle" "Go Operator"
            apiServer = container "API Server" "REST and gRPC API for pipeline management and execution" "Go Service" {
                restAPI = component "REST API" "v2beta1 endpoints for pipeline CRUD operations" "HTTP/gRPC"
                workflowMgr = component "Workflow Manager" "Creates and manages Argo/Tekton workflows" "Go"
                artifactMgr = component "Artifact Manager" "Generates signed URLs for artifact access" "Go"
            }
            persistenceAgent = container "Persistence Agent" "Watches workflows and persists execution metadata to database" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline runs" "Go Service"
            workflowController = container "Workflow Controller" "Argo-specific workflow orchestration (v2 only)" "Go Service"
            mariadb = container "MariaDB" "Metadata database for pipelines, experiments, and runs" "MySQL Database"
            minio = container "Minio" "S3-compatible object storage for artifacts (dev/test only)" "Object Storage"
            mlmdGrpc = container "ML Metadata gRPC" "gRPC server for ML metadata tracking and lineage" "Python/gRPC"
            mlmdEnvoy = container "ML Metadata Envoy" "Envoy proxy providing authentication and routing for MLMD" "Envoy Proxy"
        }

        k8s = softwareSystem "Kubernetes/OpenShift" "Container orchestration platform" "External"
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow engine for pipeline execution (v2)" "External"
        tektonPipelines = softwareSystem "OpenShift Pipelines (Tekton)" "Workflow engine for pipeline execution (v1)" "External"
        certManager = softwareSystem "cert-manager / Service CA" "TLS certificate provisioning for services" "External"
        externalDB = softwareSystem "External Database" "Production-grade managed database (MariaDB/MySQL/PostgreSQL)" "External"
        externalS3 = softwareSystem "External S3 Storage" "Production object storage (AWS S3, Minio, Ceph)" "External"
        oauthProvider = softwareSystem "OpenShift OAuth" "Cluster identity provider for SSO authentication" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and alerting platform" "External"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components and pipelines" "Internal ODH"
        odhOperator = softwareSystem "opendatahub-operator" "Deploys and manages ODH platform components" "Internal ODH"
        elyra = softwareSystem "Elyra" "Pipeline authoring tool and SDK for creating ML workflows" "Internal ODH"

        # User interactions
        user -> dspo "Creates DataSciencePipelinesApplication, submits pipelines, views runs"
        user -> odhDashboard "Manages pipelines via web UI"
        user -> elyra "Authors and submits pipelines"

        # DSPO relationships
        controller -> k8s "Watches CRs, creates/manages deployments, services, routes" "HTTPS/6443"
        controller -> apiServer "Deploys and configures"
        controller -> persistenceAgent "Deploys and configures"
        controller -> scheduledWorkflow "Deploys and configures"
        controller -> workflowController "Deploys and configures (v2 only)"
        controller -> mariadb "Deploys and configures"
        controller -> minio "Deploys and configures (dev/test)"
        controller -> mlmdGrpc "Deploys and configures"
        controller -> mlmdEnvoy "Deploys and configures"
        controller -> certManager "Provisions TLS certificates" "HTTPS/443"

        apiServer -> mariadb "Stores and queries pipeline metadata" "MySQL/3306"
        apiServer -> minio "Stores and retrieves artifacts (dev/test)" "S3 API/9000"
        apiServer -> externalDB "Stores and queries pipeline metadata (production)" "MySQL/3306 or PostgreSQL/5432"
        apiServer -> externalS3 "Stores and retrieves artifacts (production)" "S3 API/443"
        apiServer -> k8s "Creates Workflow CRs, manages pipeline pods" "HTTPS/6443"
        apiServer -> argoWorkflows "Triggers Argo workflows (v2)" "HTTPS/6443"
        apiServer -> tektonPipelines "Triggers Tekton pipelines (v1)" "HTTPS/6443"
        apiServer -> oauthProvider "Validates Bearer tokens via OAuth proxy" "HTTPS/443"

        persistenceAgent -> k8s "Watches Workflow CRs for status updates" "HTTPS/6443"
        persistenceAgent -> mariadb "Persists workflow execution metadata" "MySQL/3306"
        persistenceAgent -> minio "Fetches workflow logs and artifacts" "S3 API/9000"
        persistenceAgent -> externalDB "Persists workflow execution metadata (production)" "MySQL/3306"
        persistenceAgent -> externalS3 "Fetches workflow logs and artifacts (production)" "S3 API/443"

        scheduledWorkflow -> mariadb "Queries scheduled pipeline runs" "MySQL/3306"
        scheduledWorkflow -> apiServer "Creates scheduled pipeline runs" "HTTP/8888"
        scheduledWorkflow -> k8s "Manages schedule CRs" "HTTPS/6443"

        mlmdEnvoy -> mlmdGrpc "Proxies gRPC requests with authentication" "gRPC/8080"
        mlmdGrpc -> mariadb "Persists ML metadata and lineage" "MySQL/3306"
        mlmdGrpc -> externalDB "Persists ML metadata and lineage (production)" "MySQL/3306"

        # ODH integrations
        odhOperator -> controller "Deploys DSPO when datasciencepipelines component enabled in DataScienceCluster"
        odhDashboard -> apiServer "Integrates pipeline UI and management" "HTTPS/443"
        elyra -> apiServer "Submits pipelines via SDK" "HTTPS/443"

        # Monitoring
        prometheus -> controller "Scrapes operator metrics" "HTTP/8080"
        prometheus -> apiServer "Scrapes API server metrics" "HTTP/8080"
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

        component apiServer "APIServerComponents" {
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
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
