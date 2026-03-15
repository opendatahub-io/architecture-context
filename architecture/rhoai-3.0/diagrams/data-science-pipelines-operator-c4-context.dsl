workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML pipelines for training, validation, and deployment"
        admin = person "Platform Administrator" "Manages DSP instances and infrastructure"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Data Science Pipeline instances based on Kubeflow Pipelines for ML workflow orchestration" {
            controller = container "DSPO Controller" "Reconciles DataSciencePipelinesApplication CRs and manages component lifecycle" "Go Operator" {
                reconciler = component "Reconciler" "Watches DSPA CRs and orchestrates deployments" "Go"
                healthProbes = component "Health Probes" "Liveness and readiness endpoints" "HTTP/8081"
                metrics = component "Metrics" "Prometheus metrics exporter" "HTTP/8080"
            }

            apiServer = container "DSP API Server" "KFP v2 API for pipeline management, runs, and artifacts" "Go Service" {
                restAPI = component "REST API" "HTTP API endpoints for pipeline operations" "HTTP/8888"
                grpcAPI = component "gRPC API" "Internal gRPC API" "gRPC/8887"
                oauthProxy = component "OAuth Proxy" "Token validation and authentication" "HTTPS/8443"
            }

            persistenceAgent = container "Persistence Agent" "Syncs workflow state to database for pipeline run persistence" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline runs" "Go Service"
            workflowController = container "Workflow Controller" "Namespace-scoped Argo Workflows controller for pipeline execution" "Go Service"

            mariadb = container "MariaDB" "Stores pipeline metadata, runs, and experiment tracking data" "Database" "Optional"
            minio = container "Minio" "Stores pipeline artifacts and intermediate data" "Object Storage" "Optional - dev/test only"
            mlmdGrpc = container "ML Metadata (MLMD)" "Tracks artifact lineage and metadata" "gRPC Service" "Optional"
            mlmdEnvoy = container "MLMD Envoy" "Proxy for MLMD service" "Envoy Proxy" "Optional"
        }

        k8s = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External"
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for pipeline orchestration" "External"
        externalS3 = softwareSystem "External S3 Storage" "Production artifact storage (AWS S3, Ceph, etc.)" "External"
        externalDB = softwareSystem "External Database" "Production metadata storage (MySQL/PostgreSQL)" "External"
        containerRegistry = softwareSystem "Container Registries" "Stores pipeline component images" "External"

        odhDashboard = softwareSystem "ODH Dashboard" "Web interface for pipeline management" "Internal ODH"
        dsc = softwareSystem "DataScienceCluster" "Deploys and manages DSPO via DSC CR" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform for deploying inference services" "Internal ODH"
        workbenches = softwareSystem "Workbenches" "JupyterLab notebooks for data science development" "Internal ODH"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Provides mTLS and traffic management" "Internal ODH"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus/Grafana for metrics collection" "Internal ODH"

        # User interactions
        dataScientist -> dspo "Creates pipelines, submits runs, tracks experiments" "HTTPS/443 OAuth"
        admin -> dspo "Creates DSPA instances, configures storage/database" "kubectl/oc CLI"

        # DSPO to Kubernetes
        controller -> k8s "Creates/manages Workflows, Pods, Services, Routes" "HTTPS/6443 ServiceAccount Token"
        workflowController -> k8s "Creates pipeline execution pods" "HTTPS/6443 ServiceAccount Token"

        # DSPO to Argo Workflows
        workflowController -> argoWorkflows "Executes pipeline workflows" "Workflow CRDs"
        apiServer -> workflowController "Submits workflow definitions" "HTTP/8001 pod-to-pod TLS"

        # DSPO to storage
        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306 TLS"
        apiServer -> externalDB "Stores pipeline metadata (production)" "MySQL/PostgreSQL TLS 1.2+"
        apiServer -> minio "Stores artifacts (dev/test)" "S3 API/9000"
        apiServer -> externalS3 "Stores artifacts (production)" "HTTPS/443 S3 API"
        persistenceAgent -> mariadb "Syncs workflow state" "MySQL/3306 TLS"
        persistenceAgent -> externalDB "Syncs workflow state (production)" "MySQL/PostgreSQL TLS 1.2+"
        mlmdGrpc -> mariadb "Stores artifact lineage" "MySQL/3306 TLS"
        mlmdGrpc -> externalDB "Stores artifact lineage (production)" "MySQL/PostgreSQL TLS 1.2+"

        # Pipeline execution
        apiServer -> mlmdGrpc "Records artifact metadata" "gRPC/8080 mTLS"
        mlmdEnvoy -> mlmdGrpc "Proxies MLMD requests" "gRPC/8080"

        # ODH/RHOAI integrations
        odhDashboard -> apiServer "Pipeline management UI" "HTTPS/443 via Route"
        dsc -> controller "Deploys DSPO" "CR Management"
        apiServer -> kserve "Deploys inference services from pipelines" "HTTP/8080 or HTTPS/443"
        workbenches -> apiServer "Submits pipelines from notebooks" "HTTP/8888 pod-to-pod TLS"
        serviceMesh -> apiServer "mTLS and traffic management" "Sidecar injection"
        monitoring -> controller "Scrapes operator metrics" "HTTP/8080"
        monitoring -> workflowController "Scrapes workflow metrics" "HTTP/9090"

        # External dependencies
        dspo -> containerRegistry "Pulls component images" "HTTPS/443"
    }

    views {
        systemContext dspo "DSPOSystemContext" {
            include *
            autoLayout lr
        }

        container dspo "DSPOContainers" {
            include *
            autoLayout tb
        }

        component controller "DSPOControllerComponents" {
            include *
            autoLayout tb
        }

        component apiServer "DSPOAPIServerComponents" {
            include *
            autoLayout tb
        }

        styles {
            element "Software System" {
                background #1168bd
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

            element "External" {
                background #999999
                color #ffffff
            }

            element "Internal ODH" {
                background #7ed321
                color #000000
            }

            element "Optional" {
                opacity 70
                border dashed
            }
        }

        themes default
    }

    configuration {
        scope softwaresystem
    }
}
