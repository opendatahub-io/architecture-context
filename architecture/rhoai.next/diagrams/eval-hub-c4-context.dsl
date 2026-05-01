workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages LLM evaluation jobs"
        platformAdmin = person "Platform Administrator" "Deploys and configures eval-hub via RHOAI operator"

        evalHub = softwareSystem "Eval-Hub" "REST API service for orchestrating LLM benchmark evaluations across multiple evaluation providers with integrated experiment tracking" {
            apiServer = container "eval-hub API Server" "Main REST API managing evaluations, providers, collections. Handles job lifecycle, RBAC delegation, and config hot-reload" "Go REST API"
            runtimeSidecar = container "eval-runtime-sidecar" "Reverse proxy in evaluation Job pods. Handles auth token resolution for eval-hub, MLflow, and OCI registry calls" "Go Sidecar (KEP-753)"
            runtimeInit = container "eval-runtime-init" "Downloads S3 test data into evaluation Job pods before benchmark execution" "Go Init Container"
            storageLayer = container "Storage Layer" "Dual-backend: PostgreSQL (production) or SQLite (development). Entity data stored as JSONB/JSON TEXT" "pgx / modernc.org/sqlite"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "TokenReview, SubjectAccessReview, batch/v1 Job CRUD, ConfigMap management" "External"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for evaluations, collections, providers" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment creation, run tracking, metric logging with workspace scoping" "Internal RHOAI"
        s3 = softwareSystem "S3-compatible Storage" "Test data storage for evaluation jobs (AWS S3 or MinIO)" "External"
        ociRegistry = softwareSystem "OCI Registry" "Evaluation result artifact export via Distribution API v2" "External"
        kueue = softwareSystem "Kueue" "Priority-based queue scheduling for evaluation jobs" "External"
        serviceCA = softwareSystem "OpenShift Service CA" "Provides CA certificates for internal HTTPS verification" "External"

        lmEval = softwareSystem "LM Evaluation Harness" "Runs 180+ LLM benchmarks via adapter container" "Adapter"
        garak = softwareSystem "Garak" "Runs security/red-team evaluation scans (8 benchmarks)" "Adapter"
        lighteval = softwareSystem "Lighteval" "Runs Lighteval framework benchmarks (30+ benchmarks)" "Adapter"
        guidellm = softwareSystem "GuideLLM" "Runs GuideLLM performance benchmarks" "Adapter"
        ibmClear = softwareSystem "IBM CLEAR" "Runs IBM CLEAR evaluation benchmarks" "Adapter"

        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys and manages eval-hub as part of the RHOAI platform" "Internal RHOAI"

        dataScientist -> evalHub "Creates evaluation jobs, manages collections and providers" "HTTPS/8080, Bearer Token"
        platformAdmin -> rhoaiOperator "Configures RHOAI platform including eval-hub" "CLI/Console"

        rhoaiOperator -> evalHub "Deploys and manages" "Kubernetes Resources"

        evalHub -> k8sAPI "TokenReview, SAR, Job CRUD, ConfigMaps" "HTTPS/443, SA Token"
        evalHub -> postgresql "CRUD for evaluations, collections, providers" "pgx/5432, Username/Password"
        evalHub -> mlflow "Experiment creation, run tracking" "HTTPS, Bearer Token"
        evalHub -> s3 "Test data download (init container)" "HTTPS/443, AWS IAM"
        evalHub -> ociRegistry "Result artifact export (sidecar)" "HTTPS/443, Docker Registry Token"
        evalHub -> kueue "Priority job scheduling" "Job Labels"
        evalHub -> serviceCA "CA certificates" "ConfigMap Mount"

        evalHub -> lmEval "Spawns as adapter container in evaluation Job" "K8s Job"
        evalHub -> garak "Spawns as adapter container in evaluation Job" "K8s Job"
        evalHub -> lighteval "Spawns as adapter container in evaluation Job" "K8s Job"
        evalHub -> guidellm "Spawns as adapter container in evaluation Job" "K8s Job"
        evalHub -> ibmClear "Spawns as adapter container in evaluation Job" "K8s Job"
    }

    views {
        systemContext evalHub "SystemContext" {
            include *
            autoLayout
        }

        container evalHub "Containers" {
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
            element "Adapter" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
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
