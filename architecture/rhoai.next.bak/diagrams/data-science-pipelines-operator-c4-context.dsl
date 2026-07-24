workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines via Dashboard or SDK"
        platformadmin = person "Platform Admin" "Configures DSPA instances and manages platform"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of DSP infrastructure by reconciling DSPA CRs into ML pipeline execution environments" {
            controller = container "DSPO Controller Manager" "Reconciles DSPA CRs into pipeline infrastructure; manages lifecycle of all sub-components" "Go Operator (controller-runtime)" "Operator"
            apiserver = container "DS Pipeline API Server" "KFP v2 API server providing REST (8888) and gRPC (8887) endpoints for pipeline CRUD, run management, and artifact access" "KFP v2" "Service"
            argoController = container "Argo Workflow Controller" "Executes pipeline DAGs as Argo Workflow resources; manages pod lifecycle for pipeline steps" "Argo Workflows" "Service"
            persistenceAgent = container "Persistence Agent" "Watches Argo Workflows and syncs execution state back to the API server" "KFP Component" "Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages cron-based recurring pipeline runs" "KFP Component" "Service"
            mlmdGrpc = container "MLMD GRPC Server" "Stores artifact and execution metadata via gRPC interface (8080)" "ML Metadata" "Service"
            mlmdEnvoy = container "MLMD Envoy Proxy" "HTTP/gRPC-Web proxy (9090) fronting MLMD GRPC for browser and dashboard access" "Envoy" "Service"
            kubeRbacProxy = container "kube-rbac-proxy" "RBAC-enforcing HTTPS proxy (8443) for authentication via SubjectAccessReview" "kube-rbac-proxy" "Sidecar"
            webhook = container "PipelineVersion Webhook" "Validates and mutates PipelineVersion CRs for Kubernetes pipeline store" "Go Webhook" "Service"
            mariadb = container "MariaDB" "Stores pipeline metadata, run history, and MLMD lineage data (3306)" "MariaDB" "Database"
            minio = container "MinIO" "S3-compatible artifact storage for pipeline inputs/outputs (9000)" "MinIO" "Storage"
        }

        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys and configures DSPO" "External"
        kubeflow = softwareSystem "Kubeflow Pipelines" "Upstream pipeline framework (v2.16.0)" "External"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal ODH"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking and model registry" "Internal ODH"
        codeflare = softwareSystem "CodeFlare / MCAD" "Workload queuing via AppWrappers" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal ODH"
        seldon = softwareSystem "Seldon" "ML model serving" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science workflows" "Internal ODH"
        serviceCa = softwareSystem "OpenShift Service CA" "Certificate injection for TLS" "External"
        monitoring = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics scraping and alerting" "External"
        s3storage = softwareSystem "S3 Storage" "External object storage for pipeline artifacts" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Container images and managed pipeline definitions" "External"

        # Person relationships
        datascientist -> dspo "Creates and manages pipelines via REST/gRPC API" "HTTPS/443"
        platformadmin -> dspo "Creates DSPA CRs to provision pipeline infrastructure" "kubectl"

        # External system relationships
        rhodsOperator -> dspo "Deploys controller manager; provides image configuration" "Kubernetes API"
        dspo -> kubeflow "Uses KFP v2 API server and controllers" "Embedded"
        dspo -> kserve "Pipeline steps create InferenceService CRs" "Kubernetes API"
        dspo -> mlflow "Auto-detects MLflow instances for experiment tracking plugin" "HTTP(S)"
        dspo -> codeflare "Pipeline steps create AppWrapper CRs" "Kubernetes API"
        dspo -> ray "Pipeline steps create RayCluster/RayJob/RayService CRs" "Kubernetes API"
        dspo -> seldon "Pipeline steps create SeldonDeployment CRs" "Kubernetes API"
        dspo -> serviceCa "Generates TLS certificates for inter-component encryption" "Annotation-based"
        dspo -> s3storage "Downloads/uploads pipeline artifacts" "HTTPS/443"
        dspo -> ociRegistry "Fetches managed pipeline definitions from container images" "HTTPS/443"
        monitoring -> dspo "Scrapes metrics from operator, API server, workflow controller" "HTTP/8080, 8888, 9090"
        dashboard -> dspo "UI management of pipelines and runs" "HTTPS/8443"

        # Container relationships
        controller -> apiserver "Deploys and configures via templates" "manifestival"
        controller -> argoController "Deploys via templates" "manifestival"
        controller -> mariadb "Deploys and health-checks" "MySQL/3306"
        controller -> minio "Deploys and health-checks" "S3/9000"
        controller -> mlmdGrpc "Deploys via templates" "manifestival"
        controller -> ociRegistry "Fetches managed pipeline manifests" "HTTPS/443"
        apiserver -> mariadb "Stores pipeline metadata" "MySQL/3306"
        apiserver -> argoController "Creates Workflow CRs" "Kubernetes API"
        persistenceAgent -> apiserver "Syncs workflow execution state" "REST/8888, gRPC/8887"
        scheduledWorkflow -> apiserver "Triggers scheduled pipeline runs" "REST/8888"
        mlmdGrpc -> mariadb "Stores artifact lineage data" "MySQL/3306"
        mlmdEnvoy -> mlmdGrpc "Proxies gRPC-Web to gRPC" "gRPC/8080"
        kubeRbacProxy -> apiserver "Authenticated proxy" "HTTP/8888"
        kubeRbacProxy -> mlmdEnvoy "Authenticated proxy" "HTTP/9090"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Service" {
                background #50c878
                color #ffffff
            }
            element "Sidecar" {
                background #e74c3c
                color #ffffff
            }
            element "Database" {
                background #e67e22
                color #ffffff
            }
            element "Storage" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
            }
        }
    }
}
