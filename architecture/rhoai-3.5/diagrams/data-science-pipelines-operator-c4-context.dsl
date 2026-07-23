workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via Dashboard or SDK"
        platformAdmin = person "Platform Admin" "Deploys and configures DSPA instances"

        dspo = softwareSystem "Data Science Pipelines Operator" "Kubernetes operator managing KFP V2 pipeline infrastructure per namespace" {
            controller = container "DSPO Controller Manager" "Reconciles DSPA CRs, deploys per-namespace pipeline stacks" "Go Operator (controller-runtime)"
            apiServer = container "DS Pipelines API Server" "KFP V2 REST (8888) and gRPC (8887) API for pipeline management" "Go Service"
            kubeRbacProxy = container "kube-rbac-proxy" "RBAC-enforcing reverse proxy sidecar (SubjectAccessReview)" "Sidecar"
            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow state back to API server" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages cron-based scheduled pipeline execution" "Go Service"
            argoController = container "Argo Workflow Controller" "Executes pipeline DAGs as Argo Workflow CRs" "Argo Workflows"
            mlmdGrpc = container "MLMD gRPC Server" "ML Metadata storage and retrieval" "gRPC Service"
            mlmdEnvoy = container "MLMD Envoy Proxy" "gRPC-web to gRPC translation with RBAC proxy" "Envoy + kube-rbac-proxy"
            mariadb = container "MariaDB" "SQL database for pipeline metadata (optional internal)" "MariaDB 10.5"
            minio = container "MinIO" "S3-compatible object storage for artifacts (optional internal)" "MinIO"
            webhook = container "PipelineVersion Webhook" "Admission webhook for PipelineVersion validation/mutation" "Go Service"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline DAG execution engine" "External"
        kubeflowCRDs = softwareSystem "Kubeflow Pipelines CRDs" "ScheduledWorkflow, Pipeline, PipelineVersion resources" "External"
        rhodsOperator = softwareSystem "RHOAI Operator" "Deploys DSPO via kustomize overlays" "Internal RHOAI"
        dashboard = softwareSystem "Data Science Dashboard" "Web UI for pipeline management and metadata viewing" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving — pipeline runner creates InferenceService resources" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata registry" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed compute — pipeline runner creates RayCluster/RayJob" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "Distributed workloads — pipeline runner creates AppWrapper" "Internal RHOAI"
        mlflowOperator = softwareSystem "MLflow Operator" "MLflow tracking endpoint discovery" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift Service CA" "Auto-generates TLS certificates for annotated Services" "OpenShift Platform"
        prometheus = softwareSystem "Prometheus" "Metrics scraping via ServiceMonitor" "OpenShift Platform"
        s3Storage = softwareSystem "S3-Compatible Storage" "External artifact storage" "External"
        ociRegistry = softwareSystem "OCI Registry" "Managed pipelines manifest source" "External"
        externalDb = softwareSystem "External Database" "User-provided SQL database" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server" "OpenShift Platform"

        # User interactions
        dataScientist -> dspo "Creates pipeline runs via Dashboard or SDK"
        platformAdmin -> dspo "Creates/configures DSPA CRs via kubectl"
        dashboard -> dspo "Accesses API Server and MLMD for UI display" "HTTPS/8443"

        # Internal container interactions
        controller -> apiServer "Deploys and reconciles"
        controller -> persistenceAgent "Deploys"
        controller -> scheduledWorkflow "Deploys"
        controller -> argoController "Deploys"
        controller -> mlmdGrpc "Deploys"
        controller -> mlmdEnvoy "Deploys"
        controller -> mariadb "Deploys (optional)"
        controller -> minio "Deploys (optional)"
        controller -> webhook "Deploys (conditional)"
        kubeRbacProxy -> apiServer "Proxies authenticated requests" "HTTP/8888"
        kubeRbacProxy -> mlmdEnvoy "Proxies authenticated requests" "gRPC-web/9090"
        persistenceAgent -> apiServer "Syncs workflow state" "gRPC/8887"
        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        mlmdGrpc -> mariadb "Stores ML metadata" "MySQL/3306"
        mlmdEnvoy -> mlmdGrpc "Forwards gRPC requests" "gRPC/8080"
        argoController -> minio "Stores pipeline artifacts" "HTTP/9000"

        # External dependencies
        dspo -> argoWorkflows "Manages Workflow CRs for pipeline execution"
        dspo -> kubeflowCRDs "Manages ScheduledWorkflow, Pipeline, PipelineVersion CRs"
        dspo -> serviceCa "Uses for pod-to-pod TLS certificate generation"
        dspo -> k8sApi "Reconciles DSPA resources" "HTTPS/6443"
        dspo -> ociRegistry "Pulls managed pipeline manifests" "HTTPS/443"
        dspo -> s3Storage "Stores pipeline artifacts (external)" "HTTPS/443"
        dspo -> externalDb "Stores metadata (external)" "MySQL/3306"
        dspo -> mlflowOperator "Discovers MLflow tracking endpoint"
        dspo -> prometheus "Exposes metrics via ServiceMonitor"

        # Integration with RHOAI platform
        rhodsOperator -> dspo "Deploys via kustomize overlays"
        dspo -> kserve "Pipeline runner creates InferenceService"
        dspo -> ray "Pipeline runner creates RayCluster/RayJob/RayService"
        dspo -> codeflare "Pipeline runner creates AppWrapper"
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
            element "OpenShift Platform" {
                background #ee0000
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
