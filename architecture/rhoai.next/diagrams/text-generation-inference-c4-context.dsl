workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Deploys and queries ML models for text generation"

        tgis = softwareSystem "Text Generation Inference Server (TGIS)" "High-performance model serving for large language models with gRPC interface, continuous batching, and GPU-accelerated inference" {
            launcher = container "text-generation-launcher" "Supervisor process that starts Python model shards and the Rust router, manages lifecycle and graceful shutdown" "Rust Binary (clap CLI)"
            router = container "text-generation-router" "HTTP and gRPC frontend; handles request validation, continuous batching, tokenization, and response assembly" "Rust Service (axum + tonic)" {
                grpcServer = component "gRPC Server" "fmaas.GenerationService: Generate, GenerateStream, Tokenize, ModelInfo" "tonic"
                httpServer = component "HTTP Server" "/health, /metrics endpoints" "axum"
                batchEngine = component "Continuous Batching Engine" "PaddedBatch / FlashBatch with memory-aware sizing" "Rust"
                tokenizer = component "Tokenizer" "HuggingFace fast tokenizer for input validation" "tokenizers 0.19.1"
            }
            client = container "text-generation-client" "gRPC client library for communicating with Python model shards over Unix domain sockets" "Rust Library (tonic)"
            server = container "text-generation-server" "Model loading and GPU inference backend; runs as one or more shard processes with PyTorch" "Python Service (grpc.aio)"
            kernels = container "custom_kernels" "Custom fused attention CUDA kernels for optimized model inference on NVIDIA Ampere GPUs" "CUDA C++ Extension"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Serverless ML model serving platform" "External Platform"
        caikit = softwareSystem "Caikit Runtime" "Higher-level AI model management wrapping TGIS" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "External Platform"
        otlp = softwareSystem "OpenTelemetry Collector" "Distributed tracing backend" "External Platform"
        hfHub = softwareSystem "HuggingFace Hub" "Model weight repository" "External Service"
        gpu = softwareSystem "NVIDIA GPU (A100/A10)" "GPU compute for model inference" "Hardware"
        modelStorage = softwareSystem "Model Storage (PVC)" "Persistent volume for cached model weights" "Kubernetes"

        # Relationships
        dataScientist -> kserve "Creates InferenceService via kubectl"
        kserve -> tgis "Deploys as ServingRuntime, sends inference requests" "gRPC/8033"
        caikit -> tgis "Sends inference requests" "gRPC/8033"
        prometheus -> tgis "Scrapes metrics" "HTTP/3000"
        tgis -> otlp "Exports traces" "gRPC OTLP"
        tgis -> hfHub "Downloads model weights (disabled at runtime)" "HTTPS/443"
        tgis -> gpu "GPU inference via CUDA/NCCL" "PCIe/NVLink"
        tgis -> modelStorage "Loads model weights" "Filesystem"

        # Internal relationships
        launcher -> server "Spawns and monitors shard processes" "Process fork"
        launcher -> router "Spawns after shards ready" "Process fork"
        router -> client "Uses for shard communication"
        client -> server "Sends inference requests" "gRPC over Unix socket"
        server -> kernels "Uses for optimized attention" "Python C extension"
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Hardware" {
                background #9b59b6
                color #ffffff
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
        }
    }
}
