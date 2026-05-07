workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for text generation inference"
        sre = person "SRE / Platform Engineer" "Monitors TGIS health, metrics, and GPU utilization"

        tgis = softwareSystem "Text Generation Inference Server (TGIS)" "High-performance text generation inference server with dynamic batching, tensor parallelism, and multiple inference engine backends" {
            launcher = container "text-generation-launcher" "Process supervisor that spawns Python shards and the Rust router, handles signal propagation and health polling" "Rust 1.77.2 CLI"
            router = container "text-generation-router" "High-performance gRPC/HTTP server implementing continuous batching, request validation, tokenization, TLS termination" "Rust 1.77.2 Service" {
                grpcServer = component "gRPC Server" "fmaas.GenerationService - Generate, GenerateStream, Tokenize, ModelInfo RPCs" "Tonic gRPC, 8033/TCP"
                httpServer = component "HTTP Server" "Health probes and Prometheus metrics exposition" "Actix-web, 3000/TCP"
                batcher = component "Continuous Batcher" "Weight-aware dynamic batch formation with queue jumping and mid-inference concatenation" "Rust async"
                validator = component "Request Validator" "Validates input parameters, tokenizes text, enforces limits" "Rust"
            }
            client = container "text-generation-client" "gRPC client library for router-to-shard communication over Unix domain sockets" "Rust Library"
            server = container "text-generation-server" "Model inference backend that loads weights, manages KV cache, executes forward passes. One shard per GPU." "Python 3.11 gRPC Service" {
                inferenceEngine = component "Inference Engine" "Pluggable backend: hf_transformers, tgis_native, ibm_fms, hf_optimum_ort, ds_inference" "Python"
                kvCache = component "KV Cache Manager" "Paged attention memory management for efficient GPU utilization" "Python/CUDA"
                modelLoader = component "Model Loader" "Loads model weights from HuggingFace Hub or PVC, supports GPTQ/bitsandbytes quantization" "Python"
            }
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle and routing" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Internal"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing aggregation" "External"
        pvc = softwareSystem "PVC (Persistent Volume)" "Persistent model weight storage at /shared_model_storage" "Kubernetes"
        nvidiaGpu = softwareSystem "NVIDIA GPU (CUDA 12.1)" "GPU compute for model inference via CUDA and NCCL" "Hardware"

        # Relationships - External
        dataScientist -> tgis "Sends text generation requests via gRPC" "gRPC/8033, TLS/mTLS"
        sre -> tgis "Monitors health and metrics" "HTTP/3000"
        kserve -> tgis "Deploys and manages as InferenceService serving runtime"
        tgis -> hfHub "Downloads model weights and tokenizers at startup" "HTTPS/443, HF Token"
        tgis -> pvc "Reads model weights from persistent storage" "Volume mount"
        tgis -> nvidiaGpu "Executes model forward passes on GPU" "CUDA 12.1"
        tgis -> otelCollector "Exports distributed tracing spans" "gRPC, configurable"
        prometheus -> tgis "Scrapes metrics at /metrics" "HTTP/3000"

        # Relationships - Internal
        launcher -> router "Spawns and monitors"
        launcher -> server "Spawns one per GPU"
        router -> client "Uses for shard communication"
        client -> server "gRPC over Unix domain sockets" "UDS, plaintext"
        grpcServer -> validator "Validates requests"
        validator -> batcher "Enqueues validated requests"
        batcher -> client "Dispatches batched inference"
        server -> nvidiaGpu "Forward passes" "CUDA"
        modelLoader -> hfHub "Downloads weights" "HTTPS/443"
        modelLoader -> pvc "Loads weights" "Volume mount"
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

        component server "ServerComponents" {
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
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Hardware" {
                background #76b900
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
