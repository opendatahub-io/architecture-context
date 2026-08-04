workspace {
    model {
        user = person "Data Scientist" "Creates and manages model evaluation jobs"
        admin = person "Platform Admin" "Configures inference providers and hardware profiles"

        evalHub = softwareSystem "eval-hub" "Evaluation orchestration service that manages evaluation job lifecycle, provider configurations, and result export for RHOAI" {
            apiServer = container "eval-hub API Server" "REST API for managing evaluation jobs, collections, and inference providers" "Go net/http.ServeMux, Port 8080"
            storageLayer = container "SQL Storage Layer" "Persists evaluation job, collection, and provider state" "PostgreSQL (prod) / SQLite (dev), OTel instrumented"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint with request-ID correlation" "Go HTTP Server"
            runtimeSidecar = container "eval-runtime-sidecar" "Credential-injecting reverse proxy for evaluation pods" "Go binary, sidecar container"
            runtimeInit = container "eval-runtime-init" "Downloads test data from S3-compatible storage" "Go binary, init container"
            mcpServer = container "evalhub-mcp" "Model Context Protocol server for AI tool integration" "Go binary"
            configValidator = container "validate-configs" "Offline configuration validation tool" "Go binary"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Manages cluster resources (Jobs, ConfigMaps, Secrets, HardwareProfiles)" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for evaluation state persistence" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for test data and model artifacts" "External"
        modelEndpoint = softwareSystem "Model Endpoint" "ML model serving endpoint for inference" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and evaluation result export" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evalcard publishing" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Telemetry aggregation for traces, metrics, and logs" "External"

        # User interactions
        user -> evalHub "Submits evaluation jobs via REST API"
        admin -> evalHub "Configures providers and hardware profiles"

        # Internal container relationships
        apiServer -> storageLayer "Persists and queries evaluation state" "SQL"
        apiServer -> metricsServer "Exposes Prometheus metrics"

        # External integrations
        evalHub -> k8sAPI "Creates Jobs, ConfigMaps, Secrets; reads HardwareProfiles" "HTTPS/WSS/6443"
        evalHub -> postgresql "Stores evaluation job/collection/provider state" "TCP (pgx), Configurable TLS"
        evalHub -> s3 "Downloads test data via eval-runtime-init" "HTTPS/443"
        evalHub -> modelEndpoint "Proxies inference requests via eval-runtime-sidecar" "HTTP/HTTPS, Configurable TLS"
        evalHub -> mlflow "Exports evaluation results for experiment tracking" "HTTP/HTTPS, Configurable TLS + custom CA"
        evalHub -> ociRegistry "Publishes evalcards" "HTTP/HTTPS"
        evalHub -> otelCollector "Exports traces, metrics, and logs" "OTLP/gRPC"
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
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
