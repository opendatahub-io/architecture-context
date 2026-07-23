workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, runs, and monitors ML pipelines"
        platformAdmin = person "Platform Admin" "Deploys and configures DSPA instances"

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages the full lifecycle of Data Science Pipelines (Kubeflow Pipelines v2) on OpenShift" {
            controller = container "DSPO Controller Manager" "Reconciles DSPA CRs, deploys and manages all pipeline infrastructure" "Go Operator (controller-runtime)"
            apiServer = container "DS Pipelines API Server" "REST/gRPC API for pipeline CRUD, run management, artifact access" "Go Service (KFP v2)"
            argoController = container "Argo Workflow Controller" "Executes pipeline DAGs as Argo Workflows; manages pod lifecycle" "Go Service"
            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow run/experiment status to API Server and MLMD" "Go Service"
            scheduledWF = container "Scheduled Workflow Controller" "Manages cron-based pipeline scheduling via ScheduledWorkflow CRs" "Go Service"
            mlmdGRPC = container "ML Metadata gRPC Server" "Stores artifact lineage and execution metadata" "gRPC Service"
            mlmdEnvoy = container "ML Metadata Envoy Proxy" "gRPC-web proxy fronting MLMD with kube-rbac-proxy auth" "Envoy Proxy"
            mariaDB = container "MariaDB" "Default metadata database for API Server and MLMD" "MariaDB 10.5" "Database"
            webhook = container "PipelineVersion Webhook" "Mutating and validating admission webhooks for PipelineVersion CRs" "Go Service"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar enforcing RBAC via SubjectAccessReview" "Sidecar"
        }

        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator that creates and manages DSPA CRs" "Internal RHOAI"
        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline execution engine (bundled CRDs and controller)" "Bundled Dependency"
        openShiftServiceCA = softwareSystem "OpenShift service-CA" "Automatic TLS certificate generation for pod-to-pod encryption" "Platform Service"
        openShiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" "Platform Service"
        mlflowOperator = softwareSystem "MLflow Operator" "Optional MLflow experiment tracking integration" "Internal RHOAI"

        s3Storage = softwareSystem "S3-Compatible Storage" "Pipeline artifact storage (MinIO managed or external S3)" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Source for managed pipeline images" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Controller operations, RBAC, CR management" "Platform Service"

        kserve = softwareSystem "KServe" "Serverless ML inference (pipeline runner can create InferenceServices)" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed compute (pipeline runner can create Ray clusters)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "Platform Service"

        # Relationships - External actors
        platformAdmin -> dspo "Deploys DSPA CRs via kubectl/Dashboard"
        dataScientist -> apiServer "Creates/runs pipelines" "HTTPS/8443 (kube-rbac-proxy)"
        dataScientist -> mlmdEnvoy "Queries artifact metadata" "HTTPS/8443 (Route, kube-rbac-proxy)"

        # Relationships - Internal
        rhodsOperator -> controller "Creates/manages DSPA CRs" "Kubernetes API"
        controller -> apiServer "Deploys and configures" "Kubernetes API"
        controller -> argoController "Deploys and configures" "Kubernetes API"
        controller -> mlmdGRPC "Deploys and configures" "Kubernetes API"
        controller -> mariaDB "Deploys and configures" "Kubernetes API"

        apiServer -> mariaDB "Stores pipeline metadata" "MySQL/3306, Conditional TLS"
        apiServer -> argoController "Creates Workflow CRs" "Kubernetes API"
        argoController -> s3Storage "Pipeline artifacts" "HTTP(S)/443 or 9000"
        persistenceAgent -> apiServer "Syncs run status" "HTTP/8888, gRPC/8887"
        persistenceAgent -> mlmdGRPC "Reads execution metadata" "gRPC/8080"
        mlmdGRPC -> mariaDB "Stores lineage metadata" "MySQL/3306"
        mlmdEnvoy -> mlmdGRPC "Proxies gRPC requests" "gRPC/8080"
        scheduledWF -> apiServer "Triggers scheduled runs" "HTTP/8888"

        # Relationships - External services
        controller -> ociRegistry "Fetches managed pipeline images" "HTTPS/443"
        controller -> openShiftAPIServer "Reads TLS security profile" "HTTPS/443"
        openShiftServiceCA -> dspo "Provisions TLS certificates" "Kubernetes API annotations"
        controller -> k8sAPI "Controller operations, SubjectAccessReview" "HTTPS/443"
        mlflowOperator -> apiServer "MLflow plugin integration" "CRD discovery"

        # Relationships - Downstream integrations
        argoController -> kserve "Pipeline steps create InferenceServices" "Kubernetes API"
        argoController -> ray "Pipeline steps create Ray clusters" "Kubernetes API"
        prometheus -> apiServer "Scrapes /metrics" "HTTP/8888"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform Service" {
                background #4a90e2
                color #ffffff
            }
            element "Bundled Dependency" {
                background #f5a623
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
            element "Sidecar" {
                background #e67e22
                color #ffffff
            }
            element "Person" {
                shape Person
            }
        }
    }
}
