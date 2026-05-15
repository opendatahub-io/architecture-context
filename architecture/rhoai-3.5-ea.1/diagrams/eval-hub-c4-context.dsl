workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys LLM evaluation jobs, manages benchmark collections"
        aiAgent = person "AI Agent (MCP Client)" "Invokes evaluation workflows via Model Context Protocol"

        evalHub = softwareSystem "EvalHub" "REST API service for orchestrating LLM evaluations across multiple framework backends, tracking experiments via MLflow" {
            evalHubAPI = container "eval-hub API Server" "Primary HTTP API server for evaluation job orchestration, provider/collection management, and MLflow experiment tracking" "Go REST API, 8080/TCP"
            authMiddleware = container "Auth Middleware" "Validates K8s Bearer tokens via TokenReview and checks RBAC via SubjectAccessReview" "Go Middleware"
            evalRuntimeSidecar = container "eval-runtime-sidecar" "Reverse proxy sidecar deployed in evaluation job pods; mediates authenticated access to eval-hub, MLflow, and OCI registries" "Go Reverse Proxy, 8080/TCP"
            evalRuntimeInit = container "eval-runtime-init" "Init container that downloads test data from S3-compatible storage before evaluation jobs run" "Go Init Container"
            evalHubMCP = container "evalhub-mcp" "MCP server exposing eval-hub capabilities via tools, resources, and prompts for AI agent integration" "Go MCP Server, 3001/TCP"
            storage = container "Storage Layer" "Pluggable storage backend for evaluations, providers, and collections" "PostgreSQL or SQLite"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages EvalHub instances on cluster via EvalHub CRD" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for TokenReview, SAR, Job/ConfigMap lifecycle" "Platform"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and artifact management for evaluation runs" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for persistent evaluation storage" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for test data used by evaluation benchmarks" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for model artifact push/pull" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace and metric export endpoint" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and monitoring" "External"
        kueue = softwareSystem "Kueue" "Kubernetes job queue prioritization" "Internal RHOAI"

        # Evaluation framework backends
        lmEvalHarness = softwareSystem "lm-evaluation-harness" "LLM evaluation framework with 167+ benchmarks" "Evaluation Backend"
        ragas = softwareSystem "RAGAS" "RAG evaluation framework" "Evaluation Backend"
        garak = softwareSystem "Garak" "LLM vulnerability scanning framework" "Evaluation Backend"
        guidellm = softwareSystem "GuideLLM" "LLM performance benchmarking" "Evaluation Backend"
        lighteval = softwareSystem "LightEval" "Lightweight LLM evaluation" "Evaluation Backend"
        mteb = softwareSystem "MTEB" "Massive Text Embedding Benchmark" "Evaluation Backend"

        # User interactions
        dataScientist -> evalHub "Submits evaluation jobs, manages collections/providers" "REST API HTTPS/8080"
        aiAgent -> evalHubMCP "Invokes tools, reads resources, uses prompts" "MCP Protocol (stdio/HTTP)"

        # Internal container interactions
        evalHubMCP -> evalHubAPI "Delegates all operations" "REST API HTTP/HTTPS"
        evalHubAPI -> authMiddleware "Validates requests"
        evalHubAPI -> storage "Reads/writes evaluations, providers, collections" "SQL"
        evalRuntimeSidecar -> evalHubAPI "Forwards evaluation status events" "HTTPS, SA Token"
        evalRuntimeSidecar -> mlflow "Forwards experiment/artifact operations" "HTTPS, Projected SA Token"
        evalRuntimeSidecar -> ociRegistry "Proxies model artifact push/pull" "HTTPS/443, OAuth2 Bearer"
        evalRuntimeInit -> s3Storage "Downloads test data" "HTTPS/443, AWS credentials"

        # External interactions
        trustyaiOperator -> evalHub "Deploys and manages via EvalHub CR" "CRD"
        evalHubAPI -> kubernetesAPI "TokenReview, SAR, Job/ConfigMap CRUD" "HTTPS/443, In-cluster SA"
        evalHubAPI -> mlflow "Creates experiments, tracks runs" "HTTPS, SA Token"
        evalHubAPI -> postgresql "Persistent storage" "PostgreSQL/5432, DB credentials"
        evalHubAPI -> otlpCollector "Exports traces and metrics" "gRPC/4317 or HTTP/4318"
        prometheus -> evalHubAPI "Scrapes /metrics endpoint" "HTTP/8080"
        evalHub -> kueue "Job queue prioritization" "K8s label integration"

        # Evaluation backends (launched as K8s Jobs)
        evalHub -> lmEvalHarness "Launches as K8s Job with adapter container"
        evalHub -> ragas "Launches as K8s Job with adapter container"
        evalHub -> garak "Launches as K8s Job with adapter container"
        evalHub -> guidellm "Launches as K8s Job with adapter container"
        evalHub -> lighteval "Launches as K8s Job with adapter container"
        evalHub -> mteb "Launches as K8s Job with adapter container"
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
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Evaluation Backend" {
                background #4ecdc4
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
