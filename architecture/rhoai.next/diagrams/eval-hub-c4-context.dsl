workspace {
    model {
        user = person "Data Scientist" "Creates and monitors LLM evaluation jobs"
        agent = person "AI Agent" "Interacts with EvalHub via MCP protocol"

        evalhub = softwareSystem "EvalHub" "Lightweight REST API service for orchestrating LLM evaluations across multiple backends" {
            apiServer = container "EvalHub API" "Primary evaluation orchestration service; manages jobs, providers, collections via HTTP API" "Go REST Service" "8080/TCP"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics on separate port" "Go HTTP Server" "8081/TCP"
            mcpServer = container "evalhub-mcp" "MCP server exposing evaluation capabilities to AI agents via stdio, HTTP, or SSE" "Go MCP Server" "3001/TCP"
            sidecar = container "eval-runtime-sidecar" "Reverse proxy in evaluation job pods; credential injection, token caching, routing" "Go Sidecar Proxy" "8080/TCP (pod-local)"
            initContainer = container "eval-runtime-init" "Downloads test datasets from S3 before evaluation starts" "Go Init Container"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages EvalHub deployment lifecycle via EvalHub CRD" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication proxy; validates OAuth tokens, injects X-Tenant/X-User headers" "Internal RHOAI"
        evalAdapters = softwareSystem "Evaluation Adapters" "Framework-specific containers: lm-eval-harness, Garak, RAGAS, GuideLLM, LightEval, MTEB" "Internal RHOAI"

        k8sAPI = softwareSystem "Kubernetes API" "Cluster control plane for Job, ConfigMap, Secret management" "Infrastructure"
        postgresql = softwareSystem "PostgreSQL" "Production database for evaluation jobs, providers, collections" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and run management" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Test dataset storage for evaluation jobs" "External"
        ociRegistry = softwareSystem "OCI Registry" "Evaluation card publishing" "External"
        modelEndpoint = softwareSystem "Model Endpoint" "LLM inference endpoints (vLLM, TGI, etc.)" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing, metrics, and log collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping and alerting" "External"

        # User interactions
        user -> kubeRbacProxy "Creates evaluation jobs via kubectl/UI" "HTTPS/443"
        agent -> mcpServer "Submits evaluations, monitors jobs" "MCP over HTTP/3001 or stdio"

        # Auth proxy to API
        kubeRbacProxy -> apiServer "Forwards with X-Tenant, X-User headers" "HTTP(S)/8080"

        # MCP to API
        mcpServer -> apiServer "REST API calls" "HTTP(S)/8080, Bearer Token"

        # API to infrastructure
        apiServer -> k8sAPI "Creates/manages Jobs, ConfigMaps, Secrets" "HTTPS/443, SA Token"
        apiServer -> postgresql "Persistent storage" "TCP/5432"
        apiServer -> mlflow "Experiment tracking" "HTTP(S), Bearer Token"
        apiServer -> otelCollector "Trace/metric/log export" "OTLP gRPC/4317"

        # Operator management
        trustyaiOperator -> evalhub "Deploys and manages via EvalHub CRD" "trustyai.opendatahub.io/v1alpha1"

        # Evaluation job flows
        evalAdapters -> sidecar "All upstream traffic routed through sidecar" "HTTP/8080 (pod-local)"
        initContainer -> s3Storage "Downloads test datasets" "HTTPS/443, AWS credentials"
        sidecar -> apiServer "Job status callbacks" "HTTP(S)/8080, SA Token"
        sidecar -> mlflow "Experiment logging" "HTTP(S), Bearer Token"
        sidecar -> ociRegistry "Eval card publishing" "HTTPS/443, Docker auth"
        sidecar -> modelEndpoint "Model inference" "HTTP(S), Ref Token/SA Token"

        # Metrics
        prometheus -> metricsServer "Scrapes /metrics" "HTTP/8081"
    }

    views {
        systemContext evalhub "SystemContext" {
            include *
            autoLayout
        }

        container evalhub "Containers" {
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
            element "Infrastructure" {
                background #f5a623
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
