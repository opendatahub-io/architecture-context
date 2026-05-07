workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines via Dashboard or CLI"
        platformadmin = person "Platform Admin" "Deploys and configures DSPA instances"

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages the lifecycle of DSP infrastructure by reconciling DSPA CRs into a complete KFP v2 pipeline execution stack" {
            controller = container "DSPO Controller" "Reconciles DSPA CRs, performs health checks, renders and applies manifests" "Go Operator (controller-runtime)"
            webhook = container "Admission Webhook" "Validates and mutates Pipeline/PipelineVersion CRs" "Go Webhook Server"
            managedPipelines = container "Managed Pipelines Fetcher" "Pulls and validates pipeline definitions from OCI images" "Go Component"
            manifestival = container "Manifestival Renderer" "Renders Go templates from config/internal/ into Kubernetes resources" "Go Library"
        }

        dspStack = softwareSystem "DSP Stack (per DSPA)" "Deployed pipeline execution components managed by DSPO" {
            apiServer = container "ds-pipeline API Server" "KFP v2 API server with kube-rbac-proxy sidecar" "Python/Go, 8888/TCP, 8443/TCP"
            persistenceAgent = container "Persistence Agent" "Syncs pipeline run state to metadata store" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages recurring pipeline runs" "Go Controller"
            argoController = container "Argo Workflows Controller" "Executes pipeline DAGs as Argo Workflows" "Go Controller"
            mlmdGrpc = container "MLMD gRPC Server" "ML Metadata gRPC service" "Go/C++, 8080/TCP"
            mlmdEnvoy = container "MLMD Envoy Proxy" "HTTP proxy to MLMD gRPC with kube-rbac-proxy sidecar" "Envoy, 9090/TCP, 8443/TCP"
            mariadb = container "MariaDB" "Pipeline metadata relational storage" "MariaDB, 3306/TCP"
            minio = container "Minio" "Pipeline artifact object storage" "Minio, 9000/TCP"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external Route-based access" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Auto-provisions TLS certificates for services" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that creates DSPA CRs" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing Data Science projects" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / User Workload Monitoring" "Metrics collection and alerting" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Stores managed pipeline container images" "External"
        externalS3 = softwareSystem "External S3 Storage" "S3-compatible object storage for pipeline artifacts" "External"
        externalDB = softwareSystem "External Database" "MySQL/MariaDB for pipeline metadata" "External"
        kserve = softwareSystem "KServe" "Model serving for inference from pipeline steps" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed compute for pipeline steps" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "Workload management for pipeline steps" "Internal RHOAI"

        # Relationships - DSPO
        platformadmin -> dspo "Creates DSPA CRs via kubectl/Dashboard"
        rhoaiOperator -> dspo "Creates DSPA CRs to enable pipelines"
        dspo -> k8sApi "CRUD on Deployments, Services, ConfigMaps, Secrets, NetworkPolicies, Routes" "HTTPS/6443"
        dspo -> serviceCa "Triggers TLS cert provisioning via service annotations"
        dspo -> ociRegistry "Fetches managed-pipelines.json" "HTTPS/443"
        dspo -> dspStack "Deploys and manages all sub-components"

        # Relationships - DSP Stack
        datascientist -> odhDashboard "Creates and monitors pipelines"
        odhDashboard -> openshiftRouter "Accesses pipeline API"
        openshiftRouter -> dspStack "Routes to API Server and MLMD Envoy" "HTTPS/443 Reencrypt"
        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiServer -> minio "Stores pipeline artifacts" "S3/9000"
        apiServer -> mlmdGrpc "Stores/retrieves ML metadata" "gRPC/8080"
        mlmdGrpc -> mariadb "Stores MLMD metadata" "MySQL/3306"
        mlmdEnvoy -> mlmdGrpc "Proxies gRPC requests" "gRPC/8080"
        persistenceAgent -> apiServer "Reads pipeline run state"
        scheduledWorkflow -> argoController "Triggers scheduled runs"

        # External integrations from pipeline steps
        dspStack -> kserve "Creates InferenceService CRs for model serving"
        dspStack -> ray "Creates RayCluster/RayJob CRs for distributed compute"
        dspStack -> codeflare "Creates AppWrapper CRs for workload management"
        dspStack -> externalS3 "Stores artifacts in external S3" "HTTPS/443"
        dspStack -> externalDB "Uses external database" "MySQL/3306"

        # Monitoring
        prometheus -> dspo "Scrapes operator metrics" "HTTP/8080"
        prometheus -> dspStack "Scrapes component metrics" "HTTP/8888, gRPC/8887"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
        }

        container dspo "DSPOContainers" {
            include *
            autoLayout
        }

        container dspStack "DSPStackContainers" {
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
