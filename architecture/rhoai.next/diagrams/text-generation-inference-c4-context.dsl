workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM models for text generation"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and model serving infrastructure"

        tgis = softwareSystem "Text Generation Inference Server (TGIS)" "High-performance text generation inference server for LLMs with batching, quantization, and multi-GPU tensor parallelism" {
            launcher = container "text-generation-launcher" "Orchestrates lifecycle of Python shard processes and Rust router; handles signal propagation, tokenizer preparation, and config resolution" "Rust CLI Binary"
            router = container "text-generation-router" "Client-facing gRPC and HTTP server; implements request batching, queuing, validation, metrics, and health checks" "Rust Service (gRPC :8033, HTTP :3000)"
            shard = container "text-generation-server" "Per-GPU model inference shard; loads model weights, runs forward passes, manages KV cache, supports quantization and flash/paged attention" "Python gRPC Service (UDS)"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService CRs and ServingRuntime lifecycle" "Internal RHOAI"
        gpuOperator = softwareSystem "NVIDIA GPU Operator" "Provides nvidia.com/gpu resources and CUDA drivers on worker nodes" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer file repository" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration, scheduling, health probes" "Infrastructure"

        # User interactions
        user -> tgis "Sends text generation requests via gRPC" "gRPC/8033, Optional TLS"
        platformAdmin -> kserve "Deploys InferenceService CRs" "kubectl/API"

        # Internal container relationships
        launcher -> router "Spawns and monitors" "Process management"
        launcher -> shard "Spawns per-GPU shard processes" "Process management"
        router -> shard "Sends inference requests" "gRPC via Unix Domain Socket"

        # External dependencies
        kserve -> tgis "Manages as ServingRuntime container" "Container lifecycle"
        tgis -> huggingfaceHub "Downloads model weights" "HTTPS/443, Optional auth token"
        tgis -> gpuOperator "Uses GPU resources" "CUDA runtime"
        prometheus -> tgis "Scrapes metrics" "HTTP GET /metrics :3000"
        kubernetes -> tgis "Health probes" "HTTP GET /health :3000"
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
                background #e8e8e8
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
