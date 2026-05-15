workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        application = person "Application / Service" "Consumes LLM inference API programmatically"

        vllmcpu = softwareSystem "vllm-cpu" "CPU-only LLM inference server with OpenAI/Anthropic-compatible API, deployed as KServe runtime" {
            openaiServer = container "OpenAI API Server" "FastAPI application serving OpenAI-compatible REST API (chat completions, completions, embeddings, responses, messages)" "Python (FastAPI + uvicorn)" "Web Server"
            grpcServer = container "gRPC Server" "Alternative high-performance inference entrypoint using protobuf" "Python (grpcio)" "gRPC Service"
            asyncEngine = container "V1 Async Engine (AsyncLLM)" "Core LLM engine managing model loading, scheduling, token generation, and memory management" "Python" "Engine"
            cpuKernels = container "CPU Kernels" "Architecture-specific optimized C++ extensions for attention and tensor operations (x86_64, ppc64le, s390x)" "C++ (CMake)" "Native Library"
            prometheusInstrumentator = container "Prometheus Instrumentator" "Exposes inference metrics via /metrics endpoint" "Python (prometheus_client)" "Metrics"
            otelTracing = container "OpenTelemetry Tracing" "Distributed tracing via OTLP exporter" "Python (opentelemetry-sdk)" "Tracing"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, creates Routes, handles scaling" "Internal RHOAI"
        huggingfaceHub = softwareSystem "Hugging Face Hub" "Model weights and tokenizer hosting (huggingface.co)" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Alternative model artifact storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "Internal Platform"
        mcpServers = softwareSystem "MCP Tool Servers" "Model Context Protocol servers for tool use / function calling" "External"

        # External relationships
        datascientist -> vllmcpu "Sends inference requests via REST API" "HTTPS/HTTP 8000"
        application -> vllmcpu "Sends inference requests via REST or gRPC" "HTTP 8000 / gRPC 50051"
        kserve -> vllmcpu "Deploys and manages as InferenceService runtime container"

        # Internal relationships
        openaiServer -> asyncEngine "Forwards inference requests" "in-process Python call"
        grpcServer -> asyncEngine "Forwards inference requests" "in-process Python call"
        asyncEngine -> cpuKernels "Executes tensor operations" "Python/C++ FFI"

        # Egress relationships
        asyncEngine -> huggingfaceHub "Downloads model weights and tokenizer at startup" "HTTPS/443 TLS 1.2+ Bearer HF_TOKEN"
        asyncEngine -> s3Storage "Downloads model weights (alternative source)" "HTTPS/443 TLS 1.2+ AWS IAM"
        otelTracing -> otelCollector "Exports distributed traces" "HTTPS/gRPC TLS 1.2+"
        asyncEngine -> mcpServers "Executes MCP tools for function calling" "HTTP/HTTPS configurable"

        # Monitoring relationships
        prometheus -> prometheusInstrumentator "Scrapes /metrics endpoint" "HTTP/8000"
    }

    views {
        systemContext vllmcpu "SystemContext" {
            include *
            autoLayout
            description "System context diagram showing vllm-cpu in the RHOAI ecosystem"
        }

        container vllmcpu "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal components of vllm-cpu"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
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
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Web Server" {
                shape hexagon
            }
            element "gRPC Service" {
                shape hexagon
            }
            element "Engine" {
                shape component
            }
            element "Native Library" {
                shape component
            }
        }
    }
}
