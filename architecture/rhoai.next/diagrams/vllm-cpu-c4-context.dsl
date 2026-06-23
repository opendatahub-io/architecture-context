workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM models for inference"
        sre = person "SRE / Platform Admin" "Monitors and manages serving infrastructure"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-optimized LLM inference engine providing OpenAI-compatible API server" {
            openaiServer = container "OpenAI API Server" "HTTP REST API for text generation, embeddings, speech-to-text, and model management" "Python FastAPI/Uvicorn" "Port 8000/TCP"
            grpcServer = container "gRPC Server" "Optional gRPC interface for LLM inference" "Python gRPC AsyncIO" "Port 50051/TCP"
            engine = container "vLLM Engine (V1)" "Core inference engine with continuous batching, KV cache management, and model execution" "Python"
            cpuKernels = container "CPU Attention Kernels" "CPU-optimized attention, MoE, quantization, and positional encoding kernels" "C/C++ Extension"

            openaiServer -> engine "Sends inference requests"
            grpcServer -> engine "Sends inference requests"
            engine -> cpuKernels "Executes CPU-optimized operations"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model registry and weight storage" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts" "External"
        modelScope = softwareSystem "ModelScope" "Alternative model registry (China)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing" "Internal Platform"
        modelHostingStandards = softwareSystem "model-hosting-container-standards" "Red Hat model hosting container compliance library" "Internal RHOAI"

        # User interactions
        user -> vllmCpu "Sends inference requests via HTTP/gRPC"
        sre -> prometheus "Monitors metrics"

        # Platform interactions
        kserve -> vllmCpu "Deploys as InferenceService container" "HTTP/8000"
        prometheus -> vllmCpu "Scrapes metrics" "HTTP/8000 GET /metrics"
        vllmCpu -> otelCollector "Exports traces" "OTLP gRPC/HTTP"

        # External service interactions
        vllmCpu -> huggingfaceHub "Downloads model weights and metadata" "HTTPS/443, HF Token"
        vllmCpu -> s3Storage "Loads model artifacts" "HTTPS/443, AWS IAM"
        vllmCpu -> modelScope "Downloads models (alternative)" "HTTPS/443, Token"

        # Library dependency
        vllmCpu -> modelHostingStandards "Compliance with Red Hat container standards" "Python library"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
        }

        container vllmCpu "Containers" {
            include *
            autoLayout
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
                background #e1d5e7
                color #333333
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
        }
    }
}
