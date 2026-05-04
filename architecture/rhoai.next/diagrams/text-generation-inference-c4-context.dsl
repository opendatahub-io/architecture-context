workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for text generation"
        application = person "Application" "Upstream application consuming inference API"

        tgis = softwareSystem "Text Generation Inference Server (TGIS)" "High-performance text generation inference server with dynamic batching, tensor parallelism, and multiple inference backends" {
            launcher = container "text-generation-launcher" "Process supervisor that spawns shards and router, handles signals and health polling" "Rust 1.77.2"
            router = container "text-generation-router" "gRPC/HTTP server with continuous batching, request validation, tokenization, and TLS termination" "Rust 1.77.2" {
                grpcServer = component "gRPC Server" "fmaas.GenerationService (Generate, GenerateStream, Tokenize, ModelInfo)" "Tonic gRPC"
                httpServer = component "HTTP Server" "/health, /metrics endpoints" "Hyper HTTP"
                batcher = component "Continuous Batcher" "Dynamic batch formation with queue jumping, prefill weight limits" "Rust"
                validator = component "Request Validator" "Input validation and tokenization" "Rust"
                tlsTerminator = component "TLS Terminator" "TLS/mTLS termination via rustls + OpenSSL" "rustls 0.22.4"
            }
            client = container "text-generation-client" "gRPC client for router-to-shard communication over Unix domain sockets" "Rust 1.77.2"
            shards = container "text-generation-server" "Model inference backend: loads weights, manages KV cache, executes forward passes on GPUs" "Python 3.11" {
                inferenceEngine = component "Inference Engine" "Pluggable backends: hf_transformers, tgis_native, ibm_fms, hf_accelerate, hf_optimum_ort" "Python"
                kvCache = component "KV Cache Manager" "Paged attention / standard KV cache for memory efficiency" "Python/CUDA"
                modelLoader = component "Model Loader" "Loads model weights from PVC or HuggingFace Hub" "Python"
            }
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform managing TGIS as an InferenceService runtime" "Internal RHOAI"
        kubelet = softwareSystem "Kubernetes Kubelet" "Node agent performing health probes" "Kubernetes"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Internal"
        otel = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "Internal"
        hfHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        pvc = softwareSystem "Persistent Volume (PVC)" "Persistent storage for model weights" "Kubernetes"
        gpu = softwareSystem "NVIDIA GPU (CUDA 12.1)" "GPU compute for model inference" "Hardware"

        # Relationships
        dataScientist -> kserve "Deploys InferenceService" "kubectl / Dashboard"
        application -> tgis "Sends inference requests" "gRPC/8033 TLS/mTLS"
        kserve -> tgis "Manages as serving runtime container"
        kubelet -> tgis "Health probes" "HTTP/3000"
        prometheus -> tgis "Scrapes metrics" "HTTP/3000 /metrics"
        tgis -> otel "Exports traces" "gRPC (configurable)"
        tgis -> hfHub "Downloads model weights" "HTTPS/443"
        tgis -> pvc "Reads model weights" "Volume mount"
        tgis -> gpu "Executes inference" "CUDA"

        # Internal relationships
        launcher -> router "Spawns and monitors"
        launcher -> shards "Spawns and monitors"
        router -> client "Delegates inference calls"
        client -> shards "gRPC over UDS" "plaintext"
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

        component shards "ShardComponents" {
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
            element "Internal" {
                background #4a90e2
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
        }
    }
}
