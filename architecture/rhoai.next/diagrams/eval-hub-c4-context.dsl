workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages LLM evaluation jobs via Dashboard or CLI"
        platformAdmin = person "Platform Administrator" "Deploys and configures eval-hub as part of RHOAI"

        evalHub = softwareSystem "Eval-Hub" "REST API service for orchestrating LLM benchmark evaluations across multiple providers with MLflow tracking" {
            apiServer = container "eval-hub API Server" "Main REST API managing evaluations, providers, collections. Delegates auth to K8s API." "Go REST Service, 8080/TCP"
            runtimeSidecar = container "eval-runtime-sidecar" "Reverse proxy in Job pods for eval-hub, MLflow, OCI registry auth. Native sidecar (KEP-753)." "Go Sidecar, 8080/TCP localhost"
            runtimeInit = container "eval-runtime-init" "Downloads S3 test data into Job pods before benchmark execution." "Go Init Container"
            configLoader = container "Config Loader" "Hot-reloads provider/collection configs from ConfigMap mounts via inotify." "Go (embedded)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Authentication (TokenReview), authorization (SubjectAccessReview), Job scheduling" "External"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for evaluations, collections, providers (JSONB)" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment creation and run tracking with workspace scoping" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Test data storage for evaluation jobs" "External"
        ociRegistry = softwareSystem "OCI Registry" "Evaluation result artifact export via Distribution API v2" "External"
        kueue = softwareSystem "Kueue" "Priority queue scheduling for evaluation Jobs" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Deploys and manages eval-hub lifecycle" "Internal RHOAI"
        serviceCA = softwareSystem "OpenShift Service CA" "Provides CA certificates for internal HTTPS" "External"

        lmEvalHarness = softwareSystem "LM Evaluation Harness" "Evaluation adapter for 180+ NLP benchmarks" "Adapter"
        garak = softwareSystem "Garak" "Evaluation adapter for security/red-team scans (8 benchmarks)" "Adapter"
        lighteval = softwareSystem "Lighteval" "Evaluation adapter for Lighteval framework benchmarks (30+)" "Adapter"
        guideLLM = softwareSystem "GuideLLM" "Evaluation adapter for performance benchmarks" "Adapter"
        ibmCLEAR = softwareSystem "IBM CLEAR" "Evaluation adapter for IBM CLEAR benchmarks" "Adapter"

        # Person relationships
        dataScientist -> evalHub "Creates evaluation jobs, manages collections/providers" "HTTPS/8080, Bearer Token"
        platformAdmin -> rhoaiOperator "Configures and deploys eval-hub" "kubectl/oc"

        # Core service relationships
        evalHub -> kubernetesAPI "TokenReview, SubjectAccessReview, Job CRUD, ConfigMap CRUD" "HTTPS/443, SA Token"
        evalHub -> postgresql "CRUD for evaluations, collections, providers" "pgx/5432, Username/Password"
        evalHub -> mlflow "Create/track experiments and runs" "HTTPS, Bearer Token"
        evalHub -> s3Storage "Download test data (via init container)" "HTTPS/443, AWS IAM"
        evalHub -> ociRegistry "Push evaluation result artifacts (via sidecar)" "HTTPS/443, Docker Registry Token"
        evalHub -> kueue "Priority scheduling for evaluation Jobs" "K8s labels"
        rhoaiOperator -> evalHub "Deploys and manages lifecycle" "Kubernetes API"
        serviceCA -> evalHub "Provides CA certificates" "ConfigMap mount"

        # Internal container relationships
        apiServer -> runtimeSidecar "Callback destination for status events" "HTTPS/8443"
        runtimeInit -> s3Storage "Downloads test data" "HTTPS/443, AWS IAM"
        runtimeSidecar -> apiServer "Proxies status callbacks" "HTTPS/8443, SA Token"
        runtimeSidecar -> mlflow "Proxies MLflow API calls" "HTTPS, Projected SA Token"
        runtimeSidecar -> ociRegistry "Proxies OCI push/pull" "HTTPS/443, Registry Token"

        # Adapter relationships
        lmEvalHarness -> runtimeSidecar "Benchmark results via proxy" "HTTP/8080 localhost"
        garak -> runtimeSidecar "Security scan results via proxy" "HTTP/8080 localhost"
        lighteval -> runtimeSidecar "Evaluation results via proxy" "HTTP/8080 localhost"
        guideLLM -> runtimeSidecar "Performance results via proxy" "HTTP/8080 localhost"
        ibmCLEAR -> runtimeSidecar "Evaluation results via proxy" "HTTP/8080 localhost"
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
