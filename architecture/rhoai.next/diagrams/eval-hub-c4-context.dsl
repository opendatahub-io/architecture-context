workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs LLM evaluation jobs, manages benchmark collections"
        platformAdmin = person "Platform Admin" "Configures evaluation providers, manages RBAC, operates platform"
        aiAgent = person "AI Agent" "Interacts with eval-hub via MCP server for automated evaluation workflows"

        evalHub = softwareSystem "Eval Hub" "REST API service for orchestrating LLM evaluation jobs, managing providers, benchmarks, and tracking results" {
            apiServer = container "eval-hub API Server" "Primary REST API server for evaluation job orchestration, provider/collection management" "Go REST API, 8080/TCP"
            authMiddleware = container "Auth Middleware" "Kubernetes-native AuthN (TokenReview) and AuthZ (SubjectAccessReview) with X-Tenant multi-tenancy" "Go Middleware"
            storageLayer = container "Storage Layer" "Abstraction over SQLite and PostgreSQL for evaluation data persistence" "Go, pgx/modernc.org/sqlite"
            k8sRuntime = container "Kubernetes Runtime" "Creates Batch Jobs with init/sidecar/adapter containers for evaluation execution" "Go, client-go"
            configWatcher = container "Config Watcher" "Watches provider and collection config directories for runtime updates (fsnotify)" "Go"
            runtimeSidecar = container "eval-runtime-sidecar" "Native sidecar container (KEP-753) proxying eval-hub, MLflow, and OCI registry calls with token injection" "Go HTTP Reverse Proxy"
            runtimeInit = container "eval-runtime-init" "Init container downloading S3 test data before evaluation starts" "Go"
            mcpServer = container "evalhub-mcp" "Model Context Protocol server exposing eval-hub resources to AI agents via stdio/HTTP" "Go MCP Server, 3001/TCP"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Authentication (TokenReview), authorization (SAR), and resource management (Jobs, ConfigMaps)" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment creation, run tracking, and artifact management for evaluation results" "External"
        postgresql = softwareSystem "PostgreSQL" "Persistent storage for evaluation jobs, providers, and collections" "External"
        s3 = softwareSystem "S3-compatible Object Storage" "Test data distribution to evaluation jobs" "External"
        ociRegistry = softwareSystem "OCI Registry" "Evaluation artifact export (results, model cards)" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing, metrics, and logs collection" "External"
        kueue = softwareSystem "Kueue" "Job queue management for evaluation workloads" "External"
        serviceCA = softwareSystem "OpenShift Service CA" "Service-serving CA certificates for internal TLS" "Internal RHOAI"
        platformOperator = softwareSystem "RHOAI Platform Operator" "Deploys and configures eval-hub instances" "Internal RHOAI"
        evalProviders = softwareSystem "Evaluation Providers" "Container images for Lighteval, lm-eval-harness, Garak, GuideLLM, IBM CLEAR" "External"

        # User interactions
        dataScientist -> evalHub "Creates evaluation jobs, manages collections via REST API" "HTTPS/8080, Bearer Token"
        platformAdmin -> evalHub "Configures providers, manages platform settings" "HTTPS/8080, Bearer Token"
        aiAgent -> mcpServer "Queries evaluation resources via MCP protocol" "stdio or HTTP/3001"

        # Internal container relationships
        apiServer -> authMiddleware "Delegates authentication and authorization"
        authMiddleware -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/443, SA Token"
        apiServer -> storageLayer "Persists evaluation data"
        apiServer -> k8sRuntime "Dispatches evaluation jobs"
        configWatcher -> apiServer "Reloads provider/collection configs at runtime"
        mcpServer -> apiServer "REST API calls for resource access" "HTTPS/8080, Bearer Token"

        # Runtime relationships
        storageLayer -> postgresql "SQL queries" "TCP/5432"
        k8sRuntime -> k8sAPI "Creates Batch Jobs and ConfigMaps" "HTTPS/443, SA Token"
        runtimeInit -> s3 "Downloads test data" "HTTPS/443, AWS IAM"
        runtimeSidecar -> apiServer "Forwards status events" "HTTPS/8080, SA Token"
        runtimeSidecar -> mlflow "Forwards experiment tracking calls" "HTTPS, Projected SA Token"
        runtimeSidecar -> ociRegistry "Forwards artifact push requests" "HTTPS/443, Bearer Token"

        # External integrations
        evalHub -> otelCollector "Exports traces, metrics, logs" "gRPC/4317 or HTTP/4318"
        evalHub -> kueue "Labels Jobs for queue scheduling" "Job labels"
        platformOperator -> evalHub "Deploys and configures" "Operator CR"
        serviceCA -> evalHub "Provides CA certificates" "ConfigMap"
        k8sRuntime -> evalProviders "Pulls adapter container images" "Container Image"
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
