workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via Dashboard or CLI"
        platformAdmin = person "Platform Admin" "Configures DSPA instances and storage backends"

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages lifecycle of Kubeflow Pipelines v2 infrastructure on OpenShift" {
            controllerManager = container "DSPO Controller Manager" "Watches DSPA CRs, reconciles pipeline infrastructure via Manifestival templates" "Go Operator (controller-runtime)"
            pipelineWebhook = container "Pipeline Versions Webhook" "Validates and mutates PipelineVersion CRs for Kubernetes-native pipeline store" "Go Webhook Server"
            apiServer = container "DS Pipeline API Server" "REST/gRPC gateway for Kubeflow Pipelines v2 — manages pipelines, runs, artifacts" "Go Service"
            persistenceAgent = container "Persistence Agent" "Tracks Argo Workflow state and persists to API Server" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Handles cron-scheduled pipeline runs via ScheduledWorkflow CRs" "Go Service"
            argoController = container "Argo Workflow Controller" "Executes pipeline steps as Argo Workflows with launcher/driver containers" "Go Service"
            mlmdGrpc = container "MLMD gRPC Server" "ML Metadata storage — stores pipeline lineage and artifact metadata" "gRPC Service"
            mlmdEnvoy = container "MLMD Envoy Proxy" "gRPC-Web proxy with CORS for browser-based MLMD access" "Envoy Proxy"
            mariadb = container "MariaDB" "Embedded MySQL-compatible database for pipeline metadata (optional)" "MariaDB"
            minio = container "MinIO" "Embedded S3-compatible object storage for pipeline artifacts (optional)" "MinIO"
        }

        rhodsOperator = softwareSystem "RHOAI Operator" "Deploys and manages DSPO operator lifecycle via Kustomize" "Internal Platform"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing Data Science projects, pipelines, and experiments" "Internal Platform"
        openShiftRouter = softwareSystem "OpenShift Router" "Exposes services via Routes with TLS termination" "OpenShift Platform"
        serviceCA = softwareSystem "OpenShift Service CA" "Auto-provisions TLS certificates for annotated Services" "OpenShift Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting via ServiceMonitors" "OpenShift Platform"

        kserve = softwareSystem "KServe" "Model serving platform — pipeline steps can deploy InferenceServices" "Internal Platform"
        ray = softwareSystem "Ray" "Distributed compute — pipeline steps can create RayCluster/RayJob CRs" "Internal Platform"
        codeflare = softwareSystem "CodeFlare" "Distributed workload management via AppWrapper CRs" "Internal Platform"

        externalDB = softwareSystem "External MySQL Database" "Production pipeline metadata and MLMD storage" "External"
        externalS3 = softwareSystem "External S3 Storage" "Production pipeline artifact storage (AWS S3, Ceph, etc.)" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Stores managed pipeline definitions as OCI images" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "OpenShift Platform"

        # Relationships - User interactions
        dataScientist -> dspo "Submits and monitors pipelines" "HTTPS/443 via Route"
        dataScientist -> odhDashboard "Uses web UI"
        platformAdmin -> dspo "Creates DSPA CRs via kubectl" "HTTPS/443"
        odhDashboard -> dspo "Manages pipelines via API" "HTTPS/443"

        # Relationships - Operator lifecycle
        rhodsOperator -> dspo "Deploys operator, configures images via dspo-parameters ConfigMap" "Kustomize"
        controllerManager -> kubernetesAPI "Watches DSPA CRs, applies manifests" "HTTPS/443"
        controllerManager -> externalDB "Health checks" "MySQL/TLS"
        controllerManager -> externalS3 "Health checks" "HTTPS/TLS 1.2+"
        controllerManager -> ociRegistry "Fetches managed pipeline manifests" "HTTPS/443"

        # Relationships - Pipeline execution
        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiServer -> minio "Stores pipeline artifacts" "S3/9000"
        apiServer -> externalDB "Stores pipeline metadata (production)" "MySQL/TLS"
        apiServer -> externalS3 "Stores pipeline artifacts (production)" "HTTPS/TLS"
        persistenceAgent -> apiServer "Persists workflow state" "REST API"
        argoController -> kubernetesAPI "Creates launcher/driver pods" "HTTPS/443"
        mlmdGrpc -> mariadb "Stores lineage metadata" "MySQL/3306"
        mlmdEnvoy -> mlmdGrpc "Proxies gRPC requests" "gRPC/8080"

        # Relationships - Platform integrations
        dspo -> kserve "Pipeline steps create InferenceService CRs" "K8s API"
        dspo -> ray "Pipeline steps create RayCluster/RayJob CRs" "K8s API"
        dspo -> codeflare "Pipeline steps create AppWrapper CRs" "K8s API"
        serviceCA -> dspo "Provisions TLS certificates for Services" "Annotation-based"
        prometheus -> dspo "Scrapes operator and API server metrics" "HTTP/8080, HTTP/8888"
        openShiftRouter -> dspo "Routes external traffic to API and MLMD" "HTTPS Reencrypt"
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
            element "Internal Platform" {
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
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
