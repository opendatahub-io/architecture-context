workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages LLM evaluation jobs, collections, and providers"
        mcpAgent = person "MCP Agent" "Interacts with eval-hub via Model Context Protocol tools and resources"

        evalHub = softwareSystem "Eval Hub" "Evaluation hub service for managing LLM evaluation jobs, collections, and providers" {
            apiServer = container "EvalHub API Server" "REST API for evaluation management with optional TLS 1.2-1.3" "Go net/http.ServeMux"
            mcpServer = container "EvalHub MCP Server" "Model Context Protocol interface for tool, resource, and prompt access" "Go MCP SDK"
            metricsServer = container "Metrics Server" "Standalone Prometheus metrics endpoint" "Go HTTP Service"
            initContainer = container "Eval Runtime Init" "Init container for downloading test data from S3" "Go Binary"
        }

        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Identity enforcement proxy in cluster mode" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource orchestration" "External"
        postgresql = softwareSystem "PostgreSQL" "Primary relational data storage" "External"
        sqlite = softwareSystem "SQLite" "Embedded local storage" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for test data and artifacts" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Observability pipeline for traces, metrics, and logs" "External"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and results export" "Internal RHOAI"
        hardwareProfileCR = softwareSystem "HardwareProfile CRD" "Custom resource for hardware profile management" "Internal ODH"

        dataScientist -> kubeRBACProxy "Creates evaluation jobs via REST API" "HTTPS"
        mcpAgent -> kubeRBACProxy "Invokes MCP tools and resources" "stdio / HTTP / SSE"
        kubeRBACProxy -> apiServer "Forwards with X-User, X-Tenant headers" "HTTP"
        kubeRBACProxy -> mcpServer "Forwards with identity headers" "HTTP"
        mcpServer -> apiServer "Delegates API operations" "Internal"
        apiServer -> kubernetesAPI "Manages Jobs, ConfigMaps, Secrets, Pods, HardwareProfiles" "HTTPS/6443"
        apiServer -> postgresql "Stores and queries evaluation data" "pgx/v5"
        apiServer -> sqlite "Local embedded storage" "SQLite driver"
        apiServer -> s3Storage "Downloads test data and artifacts" "HTTPS"
        apiServer -> otelCollector "Exports traces, metrics, logs" "OTLP gRPC/HTTP"
        apiServer -> mlflow "Exports evaluation results" "HTTP"
        apiServer -> hardwareProfileCR "Manages hardware profile resources" "Kubernetes API"
        initContainer -> s3Storage "Downloads test data at startup" "HTTPS"
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
            }
            element "Internal ODH" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
