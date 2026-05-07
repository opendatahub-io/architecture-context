workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages LLM evaluation jobs"
        admin = person "Platform Admin" "Configures providers, collections, and RBAC"

        evalHub = softwareSystem "EvalHub" "Lightweight REST API service for orchestrating LLM evaluations across multiple backends" {
            apiServer = container "eval-hub API Server" "Main REST API for evaluation orchestration, job management, provider/collection CRUD" "Go Service"
            authMiddleware = container "Auth Middleware" "TokenReview + SubjectAccessReview enforcement with X-Tenant namespace mapping" "Go Middleware"
            storageLayer = container "Storage Layer" "Abstracted persistence (PostgreSQL for production, SQLite for dev)" "Go Interface"
            mlflowClient = container "MLflow Client" "Experiment creation, run tagging, result aggregation" "Go HTTP Client"
            k8sRuntime = container "Kubernetes Runtime" "Creates evaluation Job pods with 3-container pattern" "Go K8s Client"
        }

        evalJobPod = softwareSystem "Evaluation Job Pod" "Batch v1 Job with init + adapter + sidecar containers" {
            initContainer = container "eval-runtime-init" "Downloads test data from S3 before evaluation starts" "Go Init Container"
            adapter = container "Evaluation Adapter" "Runs evaluation framework (lm-eval, LightEval, Garak, GuideLLM, IBM CLEAR)" "Provider-defined Container"
            sidecar = container "eval-runtime-sidecar" "Reverse proxy for auth injection and upstream routing" "Go Native Sidecar (KEP-753)"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Deploys and manages EvalHub instances via EvalHub CR" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Authentication (TokenReview), authorization (SAR), workload management" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and evaluation result storage" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Production persistent storage for jobs, collections, providers" "External"
        s3 = softwareSystem "S3-compatible Storage" "Test data storage for evaluation jobs" "External"
        ociRegistry = softwareSystem "OCI Registry" "Model artifact storage and retrieval" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication proxy fronting eval-hub service" "External"
        kueue = softwareSystem "Kueue" "Optional queue scheduling for GPU-bound evaluation workloads" "External"

        # User interactions
        user -> evalHub "Creates evaluation jobs, views results" "REST API / Bearer Token"
        admin -> evalHub "Manages providers and benchmark collections" "REST API / Bearer Token"

        # Operator management
        trustyaiOperator -> evalHub "Deploys via EvalHub CR" "CRD Watch"

        # EvalHub internal flows
        apiServer -> authMiddleware "Validates requests"
        authMiddleware -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/443"
        apiServer -> storageLayer "Persists jobs, collections, providers"
        apiServer -> mlflowClient "Creates experiments, tags runs"
        apiServer -> k8sRuntime "Creates evaluation Job pods"

        storageLayer -> postgresql "Production queries" "TCP/5432"
        mlflowClient -> mlflow "Experiment tracking" "HTTP(S)/5000"
        k8sRuntime -> k8sAPI "Job/ConfigMap CRUD" "HTTPS/443"

        # External access
        user -> kubeRBACProxy "HTTPS with Bearer Token" "HTTPS/8443"
        kubeRBACProxy -> evalHub "Pre-authenticated requests" "HTTP/8080"

        # Job pod flows
        evalHub -> evalJobPod "Creates 3-container Job pod"
        initContainer -> s3 "Downloads test data" "HTTPS/443 AWS IAM"
        adapter -> sidecar "All outbound HTTP via localhost" "HTTP/8080"
        sidecar -> evalHub "Status event callbacks" "HTTPS/Bearer SA token"
        sidecar -> mlflow "Experiment tracking calls" "HTTPS/Bearer token"
        sidecar -> ociRegistry "Model artifact push/pull" "HTTPS/Bearer challenge"

        # Optional integration
        evalHub -> kueue "Queue scheduling via Job labels" "Label-based"
    }

    views {
        systemContext evalHub "SystemContext" {
            include *
            autoLayout
        }

        container evalHub "EvalHubContainers" {
            include *
            autoLayout
        }

        container evalJobPod "EvalJobPodContainers" {
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
