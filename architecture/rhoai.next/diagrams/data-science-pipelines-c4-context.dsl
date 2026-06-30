workspace {
    model {
        datascientist = person "Data Scientist" "Authors, compiles, and executes ML pipelines via SDK or UI"
        platformadmin = person "Platform Admin" "Deploys and manages DSP instances via DSPA operator"

        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform — define, compile, execute, schedule, cache, and track ML workflows (Kubeflow Pipelines v2)" {
            apiserver = container "API Server" "Central REST/gRPC API for pipeline, run, experiment, and artifact management with dual v1beta1/v2beta1 support" "Go Service" "Primary"
            frontend = container "Frontend UI" "Express-based BFF serving React UI, proxying API requests, handling artifact retrieval" "Node.js/TypeScript"
            persistenceagent = container "Persistence Agent" "Watches Argo Workflows, syncs execution status and metrics to database via gRPC" "Go Service"
            swcontroller = container "Scheduled Workflow Controller" "Manages ScheduledWorkflow CRDs, creates pipeline runs on cron/periodic schedules" "Go Controller"
            viewercontroller = container "Viewer CRD Controller" "Watches Viewer CRDs and creates TensorBoard Deployment + Service instances" "Go Controller"
            cacheserver = container "Cache Server" "Mutating admission webhook for step-level caching in KFP v1 pipelines" "Go Webhook Server"
            cachedeployer = container "Cache Deployer" "Manages webhook certificates and MutatingWebhookConfiguration lifecycle" "Go Service"
            driver = container "V2 Driver" "Argo Workflow sidecar — resolves inputs, manages metadata, computes cache keys, generates pod spec patches" "Go CLI"
            launcher = container "V2 Launcher" "Runs inside user containers to execute pipeline components, handle artifact I/O, publish results" "Go CLI"
            metadatawriter = container "Metadata Writer" "Watches completed Argo Workflow pods and propagates metadata annotations" "Go/Python Service"
        }

        argoworkflows = softwareSystem "Argo Workflows" "DAG workflow execution engine (v3.7.14)" "External"
        sqldb = softwareSystem "MySQL / PostgreSQL" "Relational database for pipeline, run, experiment, cache storage" "External"
        objectstore = softwareSystem "SeaweedFS / MinIO" "S3-compatible object storage for artifacts and pipeline packages" "External"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Execution lineage tracking and artifact metadata service" "External"
        k8sapi = softwareSystem "Kubernetes API" "Cluster API server for CRD operations, RBAC, authentication" "External"
        dspaoperator = softwareSystem "DSPA Operator" "RHOAI platform operator that creates/manages DSP instances" "Internal RHOAI"
        certmanager = softwareSystem "cert-manager" "TLS certificate provisioning (optional)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking integration (optional)" "External"

        # User interactions
        datascientist -> dsp "Creates/manages pipelines and runs" "REST API / gRPC / Web UI"
        datascientist -> frontend "Browses pipelines, views run results" "HTTPS"
        platformadmin -> dspaoperator "Creates DataSciencePipelinesApplication CR" "kubectl / GitOps"
        dspaoperator -> dsp "Deploys and manages DSP instance" "K8s API"

        # Internal container interactions
        frontend -> apiserver "Proxies API requests" "HTTP/8888"
        persistenceagent -> apiserver "Reports run status and metrics" "gRPC/8887"
        swcontroller -> apiserver "Creates V2 pipeline runs" "gRPC/8887"
        driver -> apiserver "Cache key lookup" "gRPC/8887"

        # External dependencies
        apiserver -> sqldb "CRUD pipeline/run/experiment records" "SQL/3306 or 5432"
        apiserver -> objectstore "Store/retrieve artifacts and pipeline packages" "S3 API/9000"
        apiserver -> mlmd "Record and query ML metadata" "gRPC/8080"
        apiserver -> k8sapi "Submit workflows, RBAC checks, TokenReview" "HTTPS/443"
        apiserver -> argoworkflows "Submit and monitor pipeline workflows" "K8s API/443"

        cacheserver -> sqldb "Lookup cache keys" "SQL/3306"
        persistenceagent -> k8sapi "Watch Argo Workflows" "HTTPS/443"
        swcontroller -> k8sapi "Watch/create ScheduledWorkflow CRs" "HTTPS/443"
        swcontroller -> argoworkflows "Create Argo Workflows (V1)" "K8s API/443"

        driver -> mlmd "Create/update execution records" "gRPC/8080"
        driver -> k8sapi "Read ConfigMaps, manage PVCs" "HTTPS/443"
        launcher -> objectstore "Download/upload artifacts" "S3 API/9000"
        launcher -> mlmd "Publish execution results" "gRPC/8080"

        cachedeployer -> certmanager "Request webhook certificates" "K8s API"
        prometheus -> apiserver "Scrape /metrics" "HTTP/8888"
        prometheus -> swcontroller "Scrape /metrics" "HTTP/9090"
        apiserver -> mlflow "Experiment tracking (optional plugin)" "HTTPS/8443"
    }

    views {
        systemContext dsp "SystemContext" {
            include *
            autoLayout
        }

        container dsp "Containers" {
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
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
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
