workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for text generation"
        mlEngineer = person "ML Engineer" "Configures model serving and optimizes inference performance"

        tgis = softwareSystem "Text Generation Inference Server (TGIS)" "High-performance text generation inference server with gRPC/HTTP APIs, continuous batching, and multi-GPU tensor parallelism" {
            launcher = container "Launcher" "Process supervisor that spawns shards and router, handles signals and health polling" "Rust 1.77.2 CLI"
            router = container "Router" "gRPC/HTTP server with continuous batching, request validation, tokenization, and TLS termination" "Rust 1.77.2 Service" {
                grpcServer = component "gRPC Server" "fmaas.GenerationService: Generate, GenerateStream, Tokenize, ModelInfo" "Tonic gRPC"
                httpServer = component "HTTP Server" "Health probes (/health) and Prometheus metrics (/metrics)" "Actix-Web"
                batcher = component "Continuous Batcher" "Dynamic batch formation with queue jumping and prefill weight limits" "Rust"
                tokenizer = component "Tokenizer" "HuggingFace tokenizer for input processing" "Rust/Python binding"
            }
            server = container "Python Shard" "Model inference backend: loads weights, manages KV cache, executes forward passes" "Python 3.11 gRPC Service" {
                inferenceEngine = component "Inference Engine" "Pluggable backends: hf_transformers, tgis_native, ibm_fms, onnx_rt, deepspeed" "Python"
                kvCache = component "KV Cache Manager" "Paged attention cache with dynamic memory allocation" "Python/CUDA"
                modelLoader = component "Model Loader" "Loads and shards model weights across GPUs" "Python"
            }
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform that manages TGIS as a serving runtime" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Model repository for downloading weights and tokenizers" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing aggregation" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Container orchestration and pod management" "Internal Platform"
        nvidiaGPU = softwareSystem "NVIDIA GPU (CUDA 12.1)" "GPU compute for model inference" "Hardware"
        pvc = softwareSystem "PVC (models-pvc)" "Persistent model weight storage" "Internal Platform"

        # Relationships
        dataScientist -> tgis "Sends text generation requests via gRPC" "gRPC/8033 TLS"
        mlEngineer -> kserve "Configures InferenceService" "kubectl"

        kserve -> tgis "Manages as serving runtime container" "Container lifecycle"
        tgis -> hfHub "Downloads model weights" "HTTPS/443 TLS 1.2+"
        tgis -> nvidiaGPU "Executes model inference" "CUDA 12.1"
        tgis -> pvc "Reads model weights" "Volume mount"
        tgis -> otelCollector "Exports tracing spans" "gRPC"

        prometheus -> tgis "Scrapes /metrics endpoint" "HTTP/3000"
        k8sAPI -> tgis "Health probes" "HTTP/3000"

        # Internal relationships
        launcher -> router "Spawns and monitors"
        launcher -> server "Spawns per GPU"
        router -> server "Inference RPCs (Prefill, NextToken)" "gRPC/UDS plaintext"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Hardware" {
                background #76b900
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
