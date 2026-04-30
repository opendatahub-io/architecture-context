workspace {
    model {
        user = person "Data Scientist" "Creates and runs ML pipelines via Dashboard or CLI"
        admin = person "Platform Admin" "Manages DSPA instances and platform configuration"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Kubeflow Pipelines v2 instances on OpenShift via DSPA custom resources" {
            controller = container "DSPO Controller Manager" "Reconciles DSPA CRs, deploys all DSP sub-components via manifestival templates" "Go Operator (controller-runtime)"
            apiserver = container "DS Pipeline API Server" "KFP v2 REST + gRPC API for pipeline CRUD, execution, and artifact management" "Go Service"
            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow status back to KFP API server database" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow" "Manages cron-scheduled pipeline runs" "Go Service"
            workflowController = container "Argo Workflow Controller" "Orchestrates pipeline execution as Argo Workflows" "Go Controller"
            mlmdServer = container "MLMD gRPC Server" "ML Metadata server for artifact and execution lineage tracking" "gRPC Service"
            mlmdEnvoy = container "MLMD Envoy Proxy" "Envoy proxy + kube-rbac-proxy for authenticated MLMD access" "Envoy + kube-rbac-proxy"
            webhook = container "DS Pipelines Webhook" "Validates/mutates PipelineVersion CRs (conditional)" "Go Webhook"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication/authorization proxy for Route-exposed services" "Sidecar"
        }

        mariadb = softwareSystem "MariaDB" "Default relational database for pipeline metadata (optional, replaceable)" "Infrastructure"
        minio = softwareSystem "Minio" "Default object storage for pipeline artifacts (optional, replaceable)" "Infrastructure"

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys DSPO and provides image configuration" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift service-ca" "Auto-provisions TLS certificates for service-to-service communication" "OpenShift Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Exposes services externally via Routes with TLS" "OpenShift Platform"
        prometheus = softwareSystem "Prometheus" "Monitors component readiness via ServiceMonitor" "Monitoring"
        k8sApi = softwareSystem "Kubernetes API" "CRUD on all managed resources, RBAC enforcement" "Platform"

        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for pipeline orchestration" "External"
        kfpCrds = softwareSystem "KFP Pipeline CRDs" "Kubernetes-native pipeline storage mode (Pipeline, PipelineVersion)" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Hosts managed-pipelines.json manifests" "External"
        externalDb = softwareSystem "External Database" "Optional external DB replacing managed MariaDB" "External"
        externalS3 = softwareSystem "External S3 Storage" "Optional external S3 replacing managed Minio" "External"

        kserve = softwareSystem "KServe" "Pipeline steps can deploy InferenceServices" "Internal RHOAI"
        ray = softwareSystem "Ray" "Pipeline steps can create Ray compute resources" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "Pipeline steps can create distributed workloads" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "User-facing UI for managing pipelines" "Internal RHOAI"

        # System context relationships
        user -> dspo "Creates/runs pipelines via" "HTTPS/443"
        admin -> dspo "Creates DSPA instances via" "kubectl/HTTPS"
        dspo -> mariadb "Stores pipeline metadata" "MySQL/3306 TLS"
        dspo -> minio "Stores pipeline artifacts" "HTTP(S)/9000"
        dspo -> k8sApi "Manages resources" "HTTPS/443"
        dspo -> serviceCa "Provisions TLS certificates" "annotation-based"
        dspo -> openshiftRouter "Creates Routes for external access" "HTTPS/443"
        dspo -> prometheus "Publishes component metrics" "HTTP/8080"
        dspo -> ociRegistry "Fetches managed pipeline manifests" "HTTPS/443"
        dspo -> externalDb "Stores metadata (optional)" "MySQL/3306 TLS"
        dspo -> externalS3 "Stores artifacts (optional)" "HTTPS/443"
        dspo -> kserve "Pipeline steps deploy InferenceServices" "HTTPS"
        dspo -> ray "Pipeline steps create Ray resources" "HTTPS"
        dspo -> codeflare "Pipeline steps create AppWrappers" "HTTPS"
        rhodsOperator -> dspo "Deploys and configures" "CRD/params.env"
        dashboard -> dspo "Manages pipelines via" "HTTPS/443"

        # Container-level relationships
        controller -> apiserver "Deploys via manifestival" "Kubernetes API"
        controller -> persistenceAgent "Deploys" "Kubernetes API"
        controller -> scheduledWorkflow "Deploys" "Kubernetes API"
        controller -> workflowController "Deploys" "Kubernetes API"
        controller -> mlmdServer "Deploys" "Kubernetes API"
        controller -> mlmdEnvoy "Deploys" "Kubernetes API"
        controller -> webhook "Deploys (conditional)" "Kubernetes API"
        controller -> k8sApi "Reconciles resources" "HTTPS/443"
        controller -> ociRegistry "Validates managed pipelines" "HTTPS/443"

        user -> kubeRbacProxy "Pipeline API requests" "HTTPS/8443"
        kubeRbacProxy -> apiserver "Authenticated requests" "HTTP(S)/8888"
        apiserver -> mariadb "Pipeline metadata" "MySQL/3306"
        apiserver -> minio "Pipeline artifacts" "HTTP(S)/9000"
        persistenceAgent -> apiserver "Sync Argo status" "HTTP(S)/8888"
        workflowController -> k8sApi "Manage Workflows" "HTTPS/443"
        mlmdEnvoy -> mlmdServer "Proxy gRPC" "gRPC/8080"
        mlmdServer -> mariadb "Lineage data" "MySQL/3306"
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
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "OpenShift Platform" {
                background #e8744f
                color #ffffff
            }
            element "Monitoring" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
                background #d0d0d0
                color #333333
            }
        }
    }
}
