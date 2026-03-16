workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and runs ML pipeline workflows for data preparation, training, and model validation"
        admin = person "Platform Administrator" "Deploys and configures Data Science Pipelines stacks"

        # Main System
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages namespace-scoped Data Science Pipeline stacks for ML workflow orchestration on OpenShift" {
            # Operator Components
            controller = container "DSPO Controller" "Reconciles DataSciencePipelinesApplication CRs and manages DSP stack lifecycle" "Go Operator" {
                reconciler = component "DSPA Reconciler" "Watches DSPA CRs and deploys pipeline components"
                deployer = component "Component Deployer" "Creates Deployments, Services, Routes, Secrets"
                metricsServer = component "Metrics Server" "Exposes operator and DSPA health metrics" "HTTP/8080"
            }

            # DSPA Instance Components (deployed per namespace)
            apiServer = container "API Server" "Provides pipeline management REST/gRPC APIs" "Go Service" {
                restAPI = component "REST API" "Pipeline CRUD operations" "HTTP/8888, HTTPS/8443"
                grpcAPI = component "gRPC API" "Pipeline service interface" "gRPC/8887"
                authProxy = component "OAuth Proxy" "OpenShift user authentication" "HTTPS/8443"
            }

            persistenceAgent = container "Persistence Agent" "Synchronizes Argo workflow state to backend database" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline runs" "Go Controller"
            workflowController = container "Workflow Controller" "Orchestrates pipeline workflow execution using Argo" "Argo Controller"

            mariadb = container "MariaDB" "Stores pipeline metadata, run history, and ML metadata" "Database" "Optional"
            minio = container "Minio" "S3-compatible object storage for pipeline artifacts" "Storage" "Optional, Dev/Test only"

            mlmdGrpc = container "ML Metadata gRPC" "Provides ML metadata lineage tracking" "gRPC Service" "Optional"
            mlmdEnvoy = container "MLMD Envoy Proxy" "HTTP/OAuth proxy for MLMD gRPC service" "Envoy Proxy" "Optional"
        }

        # External Systems (Dependencies)
        openshift = softwareSystem "OpenShift" "Kubernetes platform with Routes, OAuth, service-ca" "External Platform"
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow orchestration engine for DSP v2" "External Dependency"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Monitoring"
        imageRegistry = softwareSystem "Image Registry" "Container image storage (Quay.io, registry.redhat.io)" "External"

        externalS3 = softwareSystem "External S3 Storage" "AWS S3 or compatible storage for pipeline artifacts" "External Storage"
        externalDB = softwareSystem "External Database" "MySQL or PostgreSQL for pipeline metadata" "External Database"

        # Internal ODH Systems
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for viewing and managing pipeline runs" "Internal ODH"
        odhNotebooks = softwareSystem "ODH Notebooks" "JupyterHub notebooks for pipeline development" "Internal ODH"
        odhOperator = softwareSystem "opendatahub-operator" "Manages ODH component lifecycle via DataScienceCluster CR" "Internal ODH"

        # Relationships - People to Systems
        dataScientist -> odhNotebooks "Develops pipelines using kfp SDK"
        dataScientist -> odhDashboard "Views pipeline runs and results"
        dataScientist -> apiServer "Submits and manages pipelines" "HTTPS/443, Bearer Token"
        admin -> dspo "Deploys DSP stacks via DSPA CR"

        # Relationships - Main System Internal
        controller -> apiServer "Deploys and manages"
        controller -> persistenceAgent "Deploys and manages"
        controller -> scheduledWorkflow "Deploys and manages"
        controller -> workflowController "Deploys and manages"
        controller -> mariadb "Deploys and manages (optional)"
        controller -> minio "Deploys and manages (optional)"
        controller -> mlmdGrpc "Deploys and manages (optional)"
        controller -> mlmdEnvoy "Deploys and manages (optional)"

        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306, TLS"
        apiServer -> minio "Stores pipeline artifacts" "S3 API/9000"
        apiServer -> externalS3 "Alternative: stores artifacts" "HTTPS/443, AWS IAM"
        apiServer -> externalDB "Alternative: stores metadata" "MySQL/3306, TLS"

        persistenceAgent -> workflowController "Watches workflow state changes"
        persistenceAgent -> apiServer "Updates run status" "HTTP/8888"

        scheduledWorkflow -> workflowController "Creates scheduled workflows"

        mlmdEnvoy -> mlmdGrpc "Proxies HTTP to gRPC" "gRPC/8080"

        # Relationships - External Dependencies
        dspo -> openshift "Uses Routes, OAuth, service-ca certificates" "HTTPS/6443"
        dspo -> argoWorkflows "Creates and manages Workflow CRs" "HTTPS/6443"
        controller -> prometheus "Exposes metrics via ServiceMonitor" "HTTP/8080"

        workflowController -> openshift "Creates workflow pods" "HTTPS/6443"
        workflowController -> argoWorkflows "Uses Argo CRDs"
        workflowController -> minio "Workflow pods store artifacts" "S3 API/9000"
        workflowController -> externalS3 "Workflow pods store artifacts" "HTTPS/443"
        workflowController -> mlmdGrpc "Workflow pods log metadata" "gRPC/8080, mTLS"
        workflowController -> imageRegistry "Pulls pipeline component images" "HTTPS/443"

        # Relationships - Internal ODH Integration
        odhOperator -> controller "Deploys via DataScienceCluster CR"
        odhDashboard -> apiServer "Displays pipeline runs" "HTTP/8888"
        odhNotebooks -> apiServer "Submits pipelines via kfp SDK" "HTTPS/443"
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

        component controller "OperatorComponents" {
            include *
            autoLayout lr
            description "DSPO Controller internal components"
        }

        component apiServer "APIServerComponents" {
            include *
            autoLayout tb
            description "API Server internal components"
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "External Monitoring" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Storage" {
                background #f5a623
                color #ffffff
            }
            element "External Database" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Database" {
                shape Cylinder
                background #4a90e2
                color #ffffff
            }
            element "Storage" {
                shape Cylinder
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                opacity 70
            }
        }

        theme default
    }
}
