workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models for inference on CPU hardware"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-only LLM inference server providing OpenAI-compatible API for large language model serving" {
            apiServer = container "vLLM API Server" "OpenAI-compatible REST API server handling chat completions, text completions, embeddings, and model management" "Python (FastAPI/Uvicorn)" "Service"
            asyncEngine = container "AsyncLLM Engine" "Async inference engine managing model loading, continuous batching, scheduling, and token generation" "Python" "Engine"
            cpuKernels = container "C/C++ CPU Kernels" "CPU-optimized attention, quantization, and MoE kernels compiled via CMake" "C/C++" "Library"
            grpcServer = container "gRPC Server" "Optional gRPC interface for inference via smg-grpc-servicer" "Python (gRPC)" "Service"
            promMetrics = container "Prometheus Metrics" "Exposes /metrics endpoint with inference and request metrics" "Python" "Middleware"
            otelTracing = container "OpenTelemetry Tracing" "Distributed tracing via OTLP exporter for observability" "Python" "Module"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, routing, scaling, and model storage initialization" "Internal RHOAI"
        huggingfaceHub = softwareSystem "Hugging Face Hub" "Model weight and tokenizer repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model weight artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "Internal Platform"

        # External relationships
        user -> vllmCpu "Submits inference requests via" "HTTPS/443 (through KServe)"
        kserve -> vllmCpu "Deploys and manages as inference runtime via" "InferenceService CRD"
        vllmCpu -> huggingfaceHub "Downloads model weights and tokenizer configs" "HTTPS/443, Bearer Token"
        vllmCpu -> s3Storage "Downloads model weights from object storage" "HTTPS/443, AWS IAM"
        prometheus -> vllmCpu "Scrapes inference metrics from /metrics" "HTTP/8000"
        vllmCpu -> otlpCollector "Exports distributed traces" "gRPC/4317"

        # Internal container relationships
        apiServer -> asyncEngine "Submits inference requests" "Python async (in-process)"
        asyncEngine -> cpuKernels "Executes CPU-optimized operations" "C FFI (in-process)"
        grpcServer -> asyncEngine "Submits gRPC inference requests" "Python async (in-process)"
        promMetrics -> apiServer "Instruments HTTP requests" "FastAPI middleware"
        otelTracing -> otlpCollector "Exports traces" "gRPC/4317"
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
            description "Internal structure of the vLLM CPU inference server"
        }

        styles {
            element "Software System" {
                background #438DD5
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
                background #85C1E9
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Service" {
                shape RoundedBox
            }
            element "Engine" {
                shape Hexagon
            }
            element "Library" {
                shape Component
            }
            element "Middleware" {
                shape Pipe
            }
            element "Module" {
                shape Folder
            }
        }
    }
}
