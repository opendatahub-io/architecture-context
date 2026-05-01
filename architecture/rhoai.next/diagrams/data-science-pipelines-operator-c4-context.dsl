workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via Dashboard or CLI"
        platformAdmin = person "Platform Admin" "Configures DSPA instances and manages platform"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Data Science Pipelines (KFP v2) instances on OpenShift" {
            controller = container "DSPO Controller Manager" "Reconciles DSPA CRs, deploys and manages all DSP sub-components via manifestival templates" "Go Operator (controller-runtime)"
            apiServer = container "DS Pipeline API Server" "KFP v2 API server for pipeline CRUD, execution, and artifact management" "KFP 2.16.0"
            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow status back to the KFP API server database" "KFP Component"
            scheduledWorkflow = container "Scheduled Workflow" "Manages cron-scheduled pipeline runs" "KFP Component"
            workflowController = container "Argo Workflow Controller" "Orchestrates pipeline execution via Argo Workflows" "Argo 3.6.12"
            mlmdGrpc = container "MLMD gRPC Server" "ML Metadata gRPC server for artifact and execution lineage tracking" "MLMD"
            mlmdEnvoy = container "MLMD Envoy Proxy" "Envoy proxy fronting MLMD gRPC with kube-rbac-proxy sidecar" "Envoy 2.6"
            mariadb = container "MariaDB" "Relational database for pipeline and MLMD metadata" "MariaDB 10.5" "Database"
            minio = container "Minio" "Object storage for pipeline artifacts" "Minio" "Storage"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication/authorization proxy for Route-exposed services" "Sidecar"
            webhook = container "DS Pipelines Webhook" "Validates/mutates PipelineVersion CRs" "Admission Webhook"
        }

        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator that deploys and configures DSPO" "Internal RHOAI"
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow execution engine for pipeline orchestration" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller exposing Routes externally" "External"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Auto-provisions TLS certificates for services" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Hosts managed pipeline images and manifests" "External"
        s3Storage = softwareSystem "S3 Object Storage" "External S3-compatible storage for pipeline artifacts" "External"
        externalDB = softwareSystem "External Database" "External MySQL/MariaDB for pipeline metadata" "External"

        kserve = softwareSystem "KServe" "Model serving platform" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed compute framework" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "Distributed workload orchestration" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science workflows" "Internal RHOAI"

        # Person interactions
        dataScientist -> dspo "Submits and monitors ML pipelines" "HTTPS/443 via OpenShift Route"
        platformAdmin -> dspo "Creates DSPA CRs to provision pipeline instances" "kubectl / HTTPS"

        # Internal container relationships
        controller -> apiServer "Deploys via manifestival templates"
        controller -> workflowController "Deploys via manifestival templates"
        controller -> persistenceAgent "Deploys via manifestival templates"
        controller -> scheduledWorkflow "Deploys via manifestival templates"
        controller -> mlmdGrpc "Deploys via manifestival templates"
        controller -> mlmdEnvoy "Deploys via manifestival templates"
        controller -> mariadb "Deploys via manifestival templates"
        controller -> minio "Deploys via manifestival templates"
        controller -> webhook "Deploys (conditional)"
        controller -> kubeRbacProxy "Deploys as sidecar"

        kubeRbacProxy -> apiServer "Proxies authenticated requests" "HTTPS/8888"
        kubeRbacProxy -> mlmdEnvoy "Proxies authenticated requests" "HTTP/9090"
        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306 TLS"
        apiServer -> minio "Stores pipeline artifacts" "HTTP/9000"
        mlmdGrpc -> mariadb "Stores ML metadata lineage" "MySQL/3306 TLS"
        mlmdEnvoy -> mlmdGrpc "Forwards gRPC requests" "gRPC/8080 TLS"
        persistenceAgent -> apiServer "Syncs workflow status" "HTTP(S)/8888"
        workflowController -> kubernetesAPI "Manages Workflow CRs" "HTTPS/443"

        # External dependencies
        controller -> kubernetesAPI "CRUD on managed resources" "HTTPS/443"
        controller -> ociRegistry "Fetches managed-pipelines.json" "HTTPS/443"
        controller -> openshiftServiceCA "Triggers TLS cert provisioning" "Annotation-based"
        dspo -> openshiftRouter "Exposes Routes for API server and MLMD" "HTTPS/443 Reencrypt"
        dspo -> prometheus "Publishes component readiness metrics" "HTTP/8080 ServiceMonitor"
        dspo -> argoWorkflows "Pipeline execution orchestration" "CRD management"

        # Internal RHOAI integrations
        rhodsOperator -> dspo "Deploys DSPO, provides image config via params.env"
        dspo -> kserve "Pipeline steps deploy InferenceServices" "CRD CRUD"
        dspo -> ray "Pipeline steps create Ray compute resources" "CRD CRUD"
        dspo -> codeflare "Pipeline steps create distributed workloads" "CRD CRUD"
        dashboard -> dspo "Submits pipelines, views results" "HTTPS/443 via Route"

        # Optional external services
        apiServer -> s3Storage "Stores artifacts (replaces Minio)" "HTTPS/443"
        apiServer -> externalDB "Stores metadata (replaces MariaDB)" "MySQL/3306 TLS"
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
            element "Storage" {
                shape Cylinder
            }
            element "Sidecar" {
                background #e67e22
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
