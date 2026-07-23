workspace {
    model {
        dataScientist = person "Data Scientist" "Submits LLM evaluation jobs and reviews results"
        mlEngineer = person "ML Engineer" "Configures evaluation providers and benchmark collections"
        aiAgent = person "AI Agent / IDE" "Interacts with EvalHub via MCP protocol for automated evaluations"

        evalHub = softwareSystem "EvalHub" "Lightweight REST API service for orchestrating LLM evaluations across multiple backends on OpenShift" {
            apiServer = container "eval-hub API" "Primary REST API server for evaluation job orchestration, provider/collection management, and metrics" "Go 1.26, 8080/TCP"
            sidecar = container "eval-runtime-sidecar" "Reverse proxy sidecar injected into evaluation job pods; handles credential injection, token caching, and TLS termination" "Go, 8080/TCP (pod-local)"
            initContainer = container "eval-runtime-init" "Init container that downloads test data from S3 before evaluation adapter starts" "Go, batch process"
            mcpServer = container "evalhub-mcp" "MCP server exposing evaluation capabilities as AI-native tools, resources, and prompts" "Go, 3001/TCP"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint for evaluation lifecycle counters" "Go, 8081/TCP"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Deploys and manages EvalHub instances via EvalHub CR" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "RBAC enforcement sidecar for API authentication" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for Job/Pod/Secret/ConfigMap management" "Infrastructure"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking, run management, and artifact storage" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Test data storage (MinIO or AWS S3)" "External"
        ociRegistry = softwareSystem "OCI Registry" "Evaluation card artifact storage (Quay, etc.)" "External"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "LLM serving endpoints for evaluation" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing, metrics, and log aggregation" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and monitoring" "Infrastructure"
        evalHubSDK = softwareSystem "eval-hub-sdk (Python)" "Framework adapter SDK used by evaluation job pods" "Internal RHOAI"

        # Person interactions
        dataScientist -> evalHub "Submits evaluation jobs, reviews results" "HTTPS/8443"
        mlEngineer -> evalHub "Configures providers and collections" "HTTPS/8443"
        aiAgent -> evalHub "Automated evaluations via MCP tools" "HTTP/3001"

        # Internal container interactions
        mcpServer -> apiServer "Proxies MCP tool calls" "HTTP/8080, Bearer token"
        sidecar -> apiServer "Reports benchmark status" "HTTPS/8443, SA token"
        evalHubSDK -> sidecar "Framework adapters send results" "HTTP/8080 (localhost)"

        # External system interactions
        trustyaiOperator -> evalHub "Deploys via EvalHub CR" "CRD Watch"
        kubeRBACProxy -> apiServer "Enforces RBAC, injects identity headers" "HTTP/8080"
        apiServer -> k8sAPI "Job/Pod/Secret CRUD" "HTTPS/443, SA token"
        apiServer -> mlflow "Create experiments, log results" "HTTPS/5000, Bearer token"
        initContainer -> s3Storage "Download test data" "HTTPS/443, AWS IAM"
        sidecar -> mlflow "Proxy experiment tracking" "HTTPS/5000, Bearer token"
        sidecar -> ociRegistry "Push evaluation card artifacts" "HTTPS/443, Bearer token"
        sidecar -> modelEndpoint "Proxy inference requests" "HTTPS, API key"
        apiServer -> otelCollector "Export traces, metrics, logs" "OTLP/4317"
        prometheus -> evalHub "Scrape metrics" "HTTP/8081"
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
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #6b6b6b
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
