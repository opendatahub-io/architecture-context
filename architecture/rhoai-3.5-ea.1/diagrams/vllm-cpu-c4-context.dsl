workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models via KServe InferenceService"
        developer = person "Application Developer" "Integrates LLM inference into applications via OpenAI-compatible API"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-optimized LLM inference server providing OpenAI-compatible REST and gRPC APIs for ppc64le and s390x architectures" {
            apiServer = container "OpenAI API Server" "Primary HTTP entrypoint providing OpenAI-compatible REST API for LLM inference" "Python FastAPI/Uvicorn" "Port 8000/TCP"
            grpcServer = container "gRPC Server" "Alternative entrypoint providing gRPC-based inference API" "Python grpc.aio" "Port 50051/TCP"
            asyncEngine = container "AsyncLLM Engine V1" "Core async inference engine managing model loading, scheduling, KV-cache, and continuous batching" "Python"
            cpuKernels = container "CPU Kernels" "Optimized attention, cache, and activation kernels for CPU execution" "C/C++ Extensions"
            authMiddleware = container "Auth Middleware" "Optional Bearer token authentication for API endpoints" "Python FastAPI Middleware"
            sslRefresher = container "SSL Cert Refresher" "Hot-reloading of TLS certificates without server restart via watchfiles" "Python"
            prometheusInstrumentator = container "Prometheus Instrumentator" "Metrics collection and exposure via Prometheus client at /metrics" "Python"
            otelTracing = container "OpenTelemetry Tracing" "Distributed tracing via OpenTelemetry SDK and OTLP exporter" "Python"
        }

        kserve = softwareSystem "KServe" "Kubernetes model serving platform that manages InferenceService lifecycle and routing" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model registry hosting model weights and tokenizers" "External"
        modelStorage = softwareSystem "Model Storage" "Persistent model artifact storage via PVC or S3-compatible object storage" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace aggregation and export" "Internal Platform"
        rhoaiStats = softwareSystem "RHOAI Usage Stats" "Red Hat telemetry service at console.redhat.com/api/rhaiis-stats" "External Red Hat"

        # Relationships - External
        dataScientist -> kserve "Creates InferenceService CR referencing vLLM CPU runtime"
        developer -> vllmCpu "Sends inference requests" "HTTPS/443 via KServe Ingress"

        # Relationships - KServe to vLLM
        kserve -> vllmCpu "Routes inference traffic, manages pod lifecycle" "HTTP/8000"

        # Relationships - Internal
        apiServer -> authMiddleware "Validates Bearer token"
        authMiddleware -> asyncEngine "Forwards validated requests"
        grpcServer -> asyncEngine "Forwards gRPC inference requests"
        asyncEngine -> cpuKernels "Executes model computation" "C FFI"
        sslRefresher -> apiServer "Hot-reloads TLS certificates"
        apiServer -> prometheusInstrumentator "Collects request metrics"
        apiServer -> otelTracing "Emits trace spans"

        # Relationships - External Services
        asyncEngine -> huggingfaceHub "Downloads model weights and tokenizers" "HTTPS/443, Bearer HF_TOKEN"
        asyncEngine -> modelStorage "Loads pre-downloaded model weights" "File I/O / S3 API"
        prometheusInstrumentator -> prometheus "Exposes /metrics endpoint" "HTTP/8000"
        otelTracing -> otelCollector "Exports traces" "OTLP HTTP/gRPC"
        vllmCpu -> rhoaiStats "Reports usage telemetry" "HTTPS/443"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
            description "System context showing vLLM CPU in the RHOAI ecosystem"
        }

        container vllmCpu "Containers" {
            include *
            autoLayout
            description "Internal container view of vLLM CPU components"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Red Hat" {
                background #cc0000
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
