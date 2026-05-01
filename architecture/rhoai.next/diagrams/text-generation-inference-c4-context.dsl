workspace {
    model {
        user = person "Data Scientist / Application" "Sends text generation requests via gRPC API"

        tgis = softwareSystem "Text Generation Inference Server (TGIS)" "High-performance LLM serving with batching, quantization, and multi-GPU tensor parallelism" {
            launcher = container "text-generation-launcher" "Orchestrates lifecycle of shard processes and router; handles tokenizer prep and config resolution" "Rust CLI Binary"
            router = container "text-generation-router" "Client-facing gRPC/HTTP server; request batching, queuing, validation, metrics, health checks" "Rust Service"
            shard = container "text-generation-server" "Per-GPU model inference shard; loads weights, runs forward passes, manages KV cache, quantization, flash/paged attention" "Python gRPC Service"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService CRs and ServingRuntime lifecycle" "Internal RHOAI"
        gpuOperator = softwareSystem "NVIDIA GPU Operator" "Provides nvidia.com/gpu resources and CUDA drivers on worker nodes" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal"
        k8s = softwareSystem "Kubernetes" "Container orchestration, probes, scheduling" "Infrastructure"
        hfHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer file hosting" "External"
        modelStorage = softwareSystem "Shared Model PVC" "Pre-cached model weight storage" "Internal"

        # External relationships
        user -> tgis "Sends Generate/GenerateStream/Tokenize/ModelInfo requests" "gRPC/8033 (Optional TLS)"
        kserve -> tgis "Manages as ServingRuntime container" "Container Image / CR"
        prometheus -> tgis "Scrapes metrics" "HTTP/3000"
        k8s -> tgis "Liveness/readiness probes" "HTTP/3000 GET /health"
        tgis -> hfHub "Downloads model weights (if not pre-cached)" "HTTPS/443"
        tgis -> modelStorage "Loads pre-cached model weights" "Filesystem mount"
        tgis -> gpuOperator "Uses GPU compute resources" "CUDA runtime"

        # Internal container relationships
        launcher -> shard "Spawns N processes (1 per GPU)" "Process fork"
        launcher -> router "Starts after all shards ready" "Process spawn"
        router -> shard "Batch inference requests" "gRPC over UDS"
        shard -> shard "NCCL/GLOO tensor parallel sync" "TCP/29500 (intra-pod)"
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
            element "Internal" {
                background #85BBF0
                color #ffffff
            }
            element "Infrastructure" {
                background #F5A623
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
        }
    }
}
