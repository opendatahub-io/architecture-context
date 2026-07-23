workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        mlEngineer = person "ML Engineer" "Configures model serving infrastructure"

        vllmCpu = softwareSystem "vllm-cpu" "CPU-optimized LLM inference and serving engine with OpenAI-compatible API" {
            apiServer = container "OpenAI API Server" "OpenAI-compatible REST API for chat completions, completions, embeddings" "Python FastAPI/Uvicorn" "Service"
            grpcServer = container "gRPC Server" "Protobuf-based inference via Generate service with streaming support" "Python grpc.aio" "Service"
            rustFrontend = container "Rust Frontend" "High-performance tokenization, chat rendering, tool parsing via PyO3" "Rust PyO3" "Library"
            engineCore = container "V1 Engine Core" "Decoupled scheduling engine with ZMQ IPC, KV cache management, continuous batching" "Python" "Engine"
            modelExecutor = container "Model Executor" "Model loading (15+ format plugins), weight management, CPU inference execution" "Python/PyTorch" "Engine"
            cpuPlatform = container "CPU Platform" "NUMA-aware memory, OpenMP threading, arch-specific dtype support (x86_64/ppc64le/s390x)" "Python" "Platform"
            cli = container "CLI" "Command-line interface for serving, benchmarking, and batch processing" "Python" "CLI"
        }

        kserve = softwareSystem "KServe" "Kubernetes model serving platform; deploys vllm-cpu as InferenceService runtime" "External Platform"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External Service"
        s3 = softwareSystem "S3-compatible Storage" "Remote model artifact storage via tensorizer" "External Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection system" "External Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection (not on s390x)" "External Platform"
        modelScope = softwareSystem "ModelScope" "Alternative model download source (CN)" "External Service"

        # User interactions
        dataScientist -> vllmCpu "Sends inference requests via OpenAI-compatible API" "HTTPS/8000"
        mlEngineer -> kserve "Deploys InferenceService CR referencing vllm-cpu image"

        # Internal container relationships
        apiServer -> rustFrontend "Tokenization, chat rendering" "PyO3 FFI"
        apiServer -> engineCore "Sends processed requests" "ZMQ IPC"
        grpcServer -> engineCore "Sends processed requests" "ZMQ IPC"
        engineCore -> modelExecutor "Schedules inference batches" "Function call"
        modelExecutor -> cpuPlatform "NUMA allocation, dtype selection" "Function call"
        cli -> apiServer "Starts serving" "Process launch"

        # External system interactions
        kserve -> vllmCpu "Routes inference traffic to pod" "HTTP/8000"
        vllmCpu -> huggingface "Downloads model weights and configs at startup" "HTTPS/443"
        vllmCpu -> s3 "Loads model artifacts via tensorizer" "HTTPS/443"
        vllmCpu -> modelScope "Alternative model downloads" "HTTPS/443"
        prometheus -> vllmCpu "Scrapes metrics from FastAPI instrumentator" "HTTP/8000"
        vllmCpu -> otelCollector "Exports distributed traces via OTLP" "gRPC"
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Engine" {
                background #7ed321
                color #ffffff
            }
            element "Library" {
                background #e06c37
                color #ffffff
            }
            element "Platform" {
                background #9b59b6
                color #ffffff
            }
            element "CLI" {
                background #4a90e2
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
