workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via Dashboard, Workbenches, or CLI"
        platformAdmin = person "Platform Admin" "Deploys and configures DSPA instances for namespaces"

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages full lifecycle of KFP v2 pipeline infrastructure per namespace" {
            controller = container "DSPO Controller Manager" "Watches DSPA CRs, performs health checks, deploys managed components via manifestival templates" "Go Operator (controller-runtime)"
            apiServer = container "DS Pipelines API Server" "KFP v2 REST/gRPC API for pipeline CRUD, run scheduling, artifact management" "Go Service (8888/REST, 8887/gRPC, 8443/kube-rbac-proxy)"
            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow state back to KFP API server for run tracking" "Go Service"
            scheduledWF = container "Scheduled Workflow Controller" "Manages cron-triggered pipeline runs via ScheduledWorkflow CRs" "Go Service"
            argoController = container "Argo Workflows Controller" "Orchestrates pipeline step execution as Argo Workflow pods" "Go Service"
            mlmdServer = container "MLMD gRPC Server" "ML Metadata store providing gRPC API for artifact and execution lineage" "gRPC Service (8080/TCP)"
            mlmdEnvoy = container "MLMD Envoy Proxy" "Proxies MLMD gRPC traffic with kube-rbac-proxy authentication" "Envoy (9090/admin, 8443/kube-rbac-proxy)"
            webhook = container "Pipeline Version Webhook" "Validates and mutates PipelineVersion CRs for Kubernetes pipeline store" "Go Service (8443/HTTPS)"
        }

        mariadb = softwareSystem "MariaDB" "MySQL-compatible database for pipeline metadata (internal or external)" "Optional Internal"
        minio = softwareSystem "MinIO / S3 Storage" "S3-compatible object store for pipeline artifacts (internal or external)" "Optional Internal"

        rhodsOperator = softwareSystem "RHODS / ODH Operator" "Platform operator that deploys DSPO and creates DSPA CRs" "Internal Platform"
        mlflowOperator = softwareSystem "MLflow Operator" "Provides MLflow tracking server endpoint for experiment tracking" "Internal ODH"
        openShiftServiceCA = softwareSystem "OpenShift Service CA" "Generates TLS certificates for annotated services" "Platform Service"
        openShiftRouter = softwareSystem "OpenShift Router" "Exposes services externally via Routes with TLS termination" "Platform Service"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Scrapes operator and component metrics via ServiceMonitor" "Platform Service"
        ociRegistry = softwareSystem "OCI Registry" "Container registry hosting managed pipeline bundle images" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and RBAC" "Platform Service"

        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed compute framework" "Internal ODH"
        codeflare = softwareSystem "CodeFlare" "Distributed workload scheduling" "Internal ODH"
        seldon = softwareSystem "Seldon" "ML model serving" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for pipeline management" "Internal ODH"

        # Person relationships
        platformAdmin -> dspo "Creates DSPA CRs to deploy pipeline infrastructure"
        dataScientist -> dspo "Submits and monitors ML pipelines" "HTTPS/443 via Route"

        # Internal container relationships
        controller -> apiServer "Deploys and configures" "K8s API"
        controller -> mariadb "Health checks before deploying" "MySQL/3306"
        controller -> minio "Health checks before deploying" "HTTP(S)/9000"
        controller -> kubernetesAPI "Creates/watches resources" "HTTPS/6443"
        controller -> ociRegistry "Fetches managed pipeline bundles" "HTTPS/443"

        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiServer -> minio "Stores pipeline artifacts" "HTTP(S)/9000"
        apiServer -> argoController "Creates Workflow CRs" "K8s API"

        persistenceAgent -> apiServer "Syncs workflow state" "HTTP(S)/8888"

        mlmdServer -> mariadb "Stores artifact/execution metadata" "MySQL/3306"
        mlmdEnvoy -> mlmdServer "Proxies gRPC traffic" "gRPC/8080"

        # External relationships
        rhodsOperator -> dspo "Deploys operator, creates DSPA CRs" "CRD Watch"
        dspo -> mlflowOperator "Auto-detects MLflow tracking endpoint" "CRD Read (K8s API)"
        dspo -> openShiftServiceCA "Requests TLS certificates" "Annotation-based"
        dspo -> openShiftRouter "Exposes APIs via Routes" "TLS Reencrypt/Edge"
        prometheus -> dspo "Scrapes metrics" "HTTP/8080"

        # Pipeline step integrations
        dspo -> kserve "Pipeline steps create InferenceService CRs" "K8s API"
        dspo -> ray "Pipeline steps create Ray clusters/jobs" "K8s API"
        dspo -> codeflare "Pipeline steps create AppWrappers" "K8s API"
        dspo -> seldon "Pipeline steps create Seldon deployments" "K8s API"
        dashboard -> dspo "Pipeline management UI" "HTTP(S)/8888,8887"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Internal ODH" {
                background #50c878
                color #ffffff
            }
            element "Platform Service" {
                background #b8860b
                color #ffffff
            }
            element "Optional Internal" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #e74c3c
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
