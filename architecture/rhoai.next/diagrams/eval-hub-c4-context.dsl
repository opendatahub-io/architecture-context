workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages LLM evaluation jobs via Dashboard or API"
        aiAgent = person "AI Agent" "Interacts with eval-hub via MCP protocol for automated evaluation workflows"

        evalHub = softwareSystem "Eval Hub" "REST API service for orchestrating LLM evaluation jobs, managing providers, benchmarks, and tracking results" {
            evalHubAPI = container "eval-hub API" "Primary REST API server for evaluation job orchestration, provider/collection management, authentication/authorization" "Go REST API, 8080/TCP"
            runtimeSidecar = container "eval-runtime-sidecar" "Native sidecar container (KEP-753) proxying API calls from evaluation adapters to eval-hub, MLflow, and OCI registries with token injection" "Go HTTP Reverse Proxy"
            runtimeInit = container "eval-runtime-init" "Init container downloading test data from S3-compatible storage before evaluation adapter starts" "Go Init Container"
            mcpServer = container "evalhub-mcp" "Model Context Protocol server exposing eval-hub resources (providers, benchmarks, collections, jobs) to AI agents" "Go MCP Server, stdio/HTTP 3001/TCP"
            storageLayer = container "Storage Layer" "Evaluation data persistence via SQLite (dev) or PostgreSQL (production)" "SQLite / PostgreSQL"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for authentication (TokenReview), authorization (SubjectAccessReview), and workload management (Jobs, ConfigMaps)" "Kubernetes"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking, run logging, and artifact management for evaluation results" "External"
        postgresql = softwareSystem "PostgreSQL" "Persistent relational storage for evaluation jobs, providers, and collections" "External"
        s3 = softwareSystem "S3-compatible Object Storage" "Test data distribution to evaluation jobs" "External"
        ociRegistry = softwareSystem "OCI Registry" "Evaluation artifact export (results, model cards) via Distribution v2 API" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing, metrics, and log collection via OTLP" "External"
        kueue = softwareSystem "Kueue" "Job queue management and scheduling for evaluation workloads" "Kubernetes"
        serviceCA = softwareSystem "OpenShift Service CA" "Service-serving CA certificate for internal TLS verification" "Internal Platform"
        rhoaiOperator = softwareSystem "RHOAI Platform Operator" "Manages eval-hub Deployment, RBAC, config, and service exposure" "Internal Platform"
        evalProviders = softwareSystem "Evaluation Providers" "Lighteval, lm-evaluation-harness, Garak, GuideLLM, IBM CLEAR — adapter container images" "External"

        # User interactions
        dataScientist -> evalHub "Creates evaluation jobs, manages providers/collections via REST API" "HTTPS/8080, Bearer Token"
        aiAgent -> mcpServer "Queries providers, benchmarks, collections, jobs via MCP protocol" "stdio / HTTP/3001"

        # Internal container relationships
        mcpServer -> evalHubAPI "Fetches resources via REST client (pkg/evalhubclient)" "HTTPS/8080, Bearer Token"
        evalHubAPI -> storageLayer "Reads/writes evaluation data" "SQL"
        evalHubAPI -> k8sAPI "TokenReview, SubjectAccessReview, Job/ConfigMap CRUD" "HTTPS/443, SA Token"
        evalHubAPI -> mlflow "Creates experiments, tracks runs" "HTTPS, Bearer Token"
        runtimeSidecar -> evalHubAPI "Status updates, job metadata" "HTTPS/8080, SA Token"
        runtimeSidecar -> mlflow "Run tracking, experiment management" "HTTPS, Projected SA Token"
        runtimeSidecar -> ociRegistry "Push evaluation artifacts" "HTTPS/443, Bearer Token"
        runtimeInit -> s3 "Downloads test data files" "HTTPS/443, AWS IAM"

        # External integrations
        evalHubAPI -> postgresql "Persistent evaluation data storage" "TCP/5432"
        evalHubAPI -> otelCollector "Distributed tracing, metrics export" "gRPC/4317 OTLP"
        evalHubAPI -> kueue "Job queue scheduling via labels" "Kubernetes API"
        rhoaiOperator -> evalHub "Deploys and configures eval-hub instance" "Kubernetes API"
        serviceCA -> evalHub "Provides CA certificate for internal TLS" "ConfigMap"
        evalProviders -> runtimeSidecar "Adapter containers communicate through sidecar proxy" "HTTP/8080 localhost"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal Platform" {
                background #7ed321
            }
            element "Kubernetes" {
                background #326ce5
            }
        }
    }
}
