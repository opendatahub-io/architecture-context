workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and uses ML models for text generation inference"
        sre = person "SRE / Platform Admin" "Monitors and operates the inference platform"

        tgis = softwareSystem "Text Generation Inference Server (TGIS)" "High-performance gRPC/HTTP inference server for serving large language models with multi-GPU tensor parallelism, continuous batching, and paged attention" {
            launcher = container "text-generation-launcher" "Process orchestrator that spawns and monitors server shards and router, handles model cache resolution, tokenizer conversion, and graceful shutdown" "Rust CLI"
            router = container "text-generation-router" "External-facing gRPC/HTTP gateway providing fmaas.GenerationService API, request validation, continuous batching, queuing, metrics, and tracing" "Rust Service" {
                grpcServer = component "gRPC Server" "fmaas.GenerationService on port 8033/TCP with optional TLS/mTLS" "tonic"
                httpServer = component "HTTP Server" "Health and metrics endpoints on port 3000/TCP" "axum"
                batcher = component "Continuous Batcher" "Dynamic batch construction with weight-based limits and prefill padding constraints" "Rust"
                queue = component "Request Queue" "Multi-level fitting algorithm with time-based cutoffs" "Rust"
            }
            server = container "text-generation-server" "Model inference engine running one shard per GPU, exposing internal gRPC over Unix Domain Sockets" "Python gRPC Service"
            kernels = container "custom_kernels" "Fused attention kernels targeting NVIDIA Ampere (compute_80)" "CUDA C++ Extension"

            launcher -> router "Spawns and monitors"
            launcher -> server "Spawns one per GPU"
            router -> server "gRPC over Unix Domain Socket" "generate.v1.TextGenerationService"
            server -> kernels "Uses for fused attention" "CUDA"
        }

        kserve = softwareSystem "KServe" "Kubernetes inference service platform that manages TGIS as a serving runtime" "Internal RHOAI"
        caikit = softwareSystem "Caikit Runtime" "Higher-level model management runtime that wraps TGIS" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Internal Platform"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing infrastructure" "Internal Platform"
        hfhub = softwareSystem "HuggingFace Hub" "Model weight repository (offline in production)" "External"
        modelStorage = softwareSystem "Model Storage (PVC)" "Pre-cached model weights on persistent volume" "Internal Platform"
        cudaRuntime = softwareSystem "NVIDIA GPU / CUDA Runtime" "GPU compute for model inference" "Infrastructure"
        nccl = softwareSystem "NCCL" "Multi-GPU collective communication library" "Infrastructure"

        kserve -> tgis "Sends inference requests" "gRPC/8033 Optional TLS"
        caikit -> tgis "Sends inference requests" "gRPC/8033 Optional TLS"
        datascientist -> kserve "Creates InferenceService CR"
        sre -> prometheus "Monitors TGIS health and performance"
        prometheus -> tgis "Scrapes metrics" "HTTP/3000 /metrics"
        tgis -> otel "Exports traces (optional)" "gRPC"
        tgis -> hfhub "Downloads model weights (offline in prod)" "HTTPS/443"
        tgis -> modelStorage "Loads model weights" "Filesystem read-only"
        tgis -> cudaRuntime "GPU compute" "CUDA 12.1"
        tgis -> nccl "Multi-GPU tensor parallelism" "Shared Memory / NVLink"
    }

    views {
        systemContext tgis "SystemContext" {
            include *
            autoLayout
        }

        container tgis "Containers" {
            include *
            autoLayout
        }

        component router "RouterComponents" {
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
