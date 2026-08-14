workspace {
    model {
        user = person "Data Scientist / Platform User" "Submits evaluation jobs and reviews results"
        aiAgent = person "AI Agent" "Interacts via Model Context Protocol"

        evalHub = softwareSystem "Eval-Hub" "Evaluation orchestration service for RHOAI - manages evaluation jobs, collections, and providers" {
            apiServer = container "Eval-Hub API Server" "REST API for managing evaluations, jobs, collections, providers" "Go Service, Port 8080"
            metricsServer = container "Metrics Server" "Standalone Prometheus metrics endpoint" "Go Service, Port 8081"
            identityGate = container "Identity Gate Middleware" "Conditional X-User/X-Tenant header enforcement" "Go Middleware"
            runtimeInit = container "eval_runtime_init" "Init container that downloads test data from S3" "Go Init Container"
            runtimeSidecar = container "eval_runtime_sidecar" "Sidecar proxy for evaluation runtime containers" "Go Sidecar"
            mcpServer = container "evalhub_mcp" "Model Context Protocol server interface for AI agents" "Go Service"
            configValidator = container "validate_configs" "Validates evaluation configurations" "Go CLI"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer_k8s = container "Kubernetes API Server" "Manages cluster resources" "Port 6443, HTTPS"
        }

        s3 = softwareSystem "S3-Compatible Storage" "Object storage for test data artifacts" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and model versioning" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Observability data collection (traces, metrics, logs)" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for persistent storage (production)" "External"

        # User interactions
        user -> evalHub "Submits evaluation jobs via REST API" "HTTP/8080"
        aiAgent -> evalHub "Interacts via MCP protocol"

        # Internal container relationships
        apiServer -> identityGate "Routes through for protected endpoints"
        apiServer -> metricsServer "Exposes Prometheus metrics"

        # External integrations
        evalHub -> kubernetes "Creates Jobs, ConfigMaps, Secrets; queries HardwareProfiles" "HTTPS/6443"
        evalHub -> s3 "Downloads test data (via eval_runtime_init)" "HTTPS, AWS SDK"
        evalHub -> mlflow "Tracks experiments and model metadata" "HTTPS, TLS 1.2-1.3"
        evalHub -> otelCollector "Exports traces, metrics, logs" "OTLP/gRPC"
        evalHub -> postgresql "Persists evaluation records" "PostgreSQL/pgx"

        # Container-level detail
        runtimeInit -> s3 "Downloads test data" "HTTPS, AWS SDK Auth"
        apiServer -> kubernetes "Creates batch/v1 Jobs with init+sidecar" "HTTPS/6443, ServiceAccount"
        apiServer -> mlflow "Experiment tracking" "HTTPS, TLS 1.2-1.3, Custom CA"
        apiServer -> otelCollector "Telemetry export" "OTLP/gRPC"
        apiServer -> postgresql "SQL queries" "pgx driver"
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
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
