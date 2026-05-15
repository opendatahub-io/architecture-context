workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and executes ML pipelines via Dashboard or API"
        platformAdmin = person "Platform Admin" "Deploys and configures DSPA instances"

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages lifecycle of Data Science Pipelines (Kubeflow Pipelines v2) deployments on OpenShift" {
            controllerManager = container "DSPO Controller Manager" "Reconciles DSPA CRs, deploys and manages all pipeline components using manifestival templates" "Go Operator"
            pipelineVersionWebhook = container "PipelineVersion Webhook" "Validates and mutates PipelineVersion CRs when Kubernetes pipeline store is enabled" "Admission Webhook"
            apiServer = container "DS Pipeline API Server" "REST/gRPC API for pipeline CRUD, execution, and artifact management" "Go Service"
            kubeRbacProxy = container "kube-rbac-proxy" "RBAC-based authentication proxy enforcing SubjectAccessReview for API server and MLMD routes" "Sidecar Proxy"
            persistenceAgent = container "Persistence Agent" "Syncs pipeline run artifacts and metadata to MLMD" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow" "Manages cron-based scheduled pipeline executions" "Go Service"
            workflowController = container "Workflow Controller" "Argo Workflows controller for pipeline step orchestration" "Go Service"
            mlmdGrpcServer = container "MLMD gRPC Server" "ML Metadata storage and retrieval via gRPC" "Go/C++ Service"
            mlmdEnvoyProxy = container "MLMD Envoy Proxy" "gRPC/HTTP proxy with TLS termination for MLMD access" "Envoy Proxy"
            mariaDB = container "MariaDB" "MySQL-compatible metadata store for pipeline definitions and runs" "Database" "Database"
            minIO = container "MinIO" "S3-compatible artifact storage for pipeline artifacts" "Object Storage" "Database"
            managedPipelinesInit = container "Managed Pipelines Init Container" "Pre-loads pipeline definitions from OCI registry images" "Init Container"
        }

        argoWorkflows = softwareSystem "Argo Workflows" "Pipeline execution engine via Workflow CRDs" "External"
        kserve = softwareSystem "KServe" "Model serving platform for inference service deployment" "Internal RHOAI"
        seldonCore = softwareSystem "Seldon Core" "ML model deployment via SeldonDeployment CRs" "External"
        ray = softwareSystem "Ray" "Distributed computing for pipeline execution" "External"
        codeflare = softwareSystem "CodeFlare" "Resource-constrained workload management via AppWrappers" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing external route access" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate generation for services" "External"
        prometheus = softwareSystem "Prometheus / User Workload Monitoring" "Metrics collection via ServiceMonitor" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD" "External"
        ociRegistries = softwareSystem "OCI Registries" "Container image registries for managed pipeline manifests" "External"
        externalDB = softwareSystem "External MySQL Database" "Optional external MySQL-compatible database" "External"
        externalS3 = softwareSystem "External S3 Storage" "Optional external S3-compatible object storage" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator deploying DSPO with distribution-specific config" "Internal RHOAI"

        # Relationships - Users
        dataScientist -> dspo "Creates/executes pipelines via API" "HTTPS/443"
        dataScientist -> odhDashboard "Manages pipelines via UI" "HTTPS"
        platformAdmin -> dspo "Creates DSPA instances" "kubectl"

        # Relationships - Platform
        rhodsOperator -> dspo "Deploys with kustomize overlays" "Kustomize"
        odhDashboard -> dspo "Pipeline management UI" "HTTPS/8443"
        dspo -> kubernetesAPI "Resource CRUD, Workflow management" "HTTPS/443"
        dspo -> openshiftServiceCA "Auto-generates TLS certificates" "Service Annotation"
        dspo -> prometheus "Exposes metrics via ServiceMonitor" "HTTP/8888"
        dspo -> openshiftRouter "Exposes API server and MLMD externally" "Route/443"

        # Relationships - Integrations
        dspo -> argoWorkflows "Creates Workflow CRs for pipeline execution" "K8s API"
        dspo -> kserve "Creates InferenceService CRs from pipeline steps" "K8s API"
        dspo -> seldonCore "Creates SeldonDeployment CRs from pipeline steps" "K8s API"
        dspo -> ray "Creates RayCluster/RayJob for distributed execution" "K8s API"
        dspo -> codeflare "Creates AppWrapper CRs for resource management" "K8s API"
        dspo -> ociRegistries "Fetches managed pipeline manifests" "HTTPS/443"

        # Relationships - External backends
        dspo -> externalDB "Optional external pipeline metadata storage" "MySQL/3306"
        dspo -> externalS3 "Optional external artifact storage" "HTTPS/443"

        # Internal container relationships
        controllerManager -> apiServer "Deploys and manages"
        controllerManager -> mariaDB "Deploys and health checks" "MySQL/3306"
        controllerManager -> minIO "Deploys and health checks" "S3/9000"
        controllerManager -> ociRegistries "Fetches managed-pipelines.json" "HTTPS/443"
        kubeRbacProxy -> apiServer "Proxies authenticated requests" "HTTP(S)/8888"
        apiServer -> mariaDB "Stores pipeline metadata" "MySQL/3306 TLS"
        apiServer -> minIO "Stores pipeline artifacts" "S3/9000 TLS"
        persistenceAgent -> apiServer "Fetches run status" "HTTP(S)/8888"
        persistenceAgent -> mlmdGrpcServer "Syncs metadata" "gRPC/8080"
        mlmdEnvoyProxy -> mlmdGrpcServer "Proxies gRPC requests" "gRPC/8080"
        workflowController -> kubernetesAPI "Creates step pods" "HTTPS/443"
        scheduledWorkflow -> kubernetesAPI "Creates scheduled workflows" "HTTPS/443"
        managedPipelinesInit -> apiServer "Pre-loads pipeline definitions" "Filesystem"
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
            element "Database" {
                shape Cylinder
            }
            element "Person" {
                shape Person
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
        }
    }
}
