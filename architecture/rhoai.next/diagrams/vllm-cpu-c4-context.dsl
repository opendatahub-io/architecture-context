workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to LLM models via OpenAI-compatible API"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-only LLM inference serving engine for ppc64le and s390x architectures" {
            apiServer = container "OpenAI API Server" "FastAPI-based HTTP server exposing OpenAI-compatible endpoints" "Python / FastAPI / uvicorn" "8000/TCP"
            grpcServer = container "gRPC Server" "gRPC inference endpoint via smg-grpc-servicer" "Python / grpcio" "50051/TCP"
            engineCore = container "V1 EngineCore" "Core inference loop: scheduling, KV cache management, continuous batching" "Python"
            inputProcessor = container "Input Processor" "Tokenization and request preprocessing" "Python / HuggingFace transformers"
            outputProcessor = container "Output Processor" "Detokenization and streaming response assembly" "Python"
            cpuModelRunner = container "CPU Model Runner" "CPU-specific model execution wrapping PyTorch CPU backend" "Python / PyTorch"
            cpuPlatform = container "CPU Platform" "Architecture detection (x86, ARM, PPC64LE, S390X) and dtype/feature support" "Python"
        }

        kserve = softwareSystem "KServe" "Kubernetes inference serving platform - deploys vLLM as InferenceService runtime" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User interface for configuring serving runtimes" "Internal RHOAI"
        modelController = softwareSystem "Model Mesh / Model Controller" "Manages model serving pod lifecycle" "Internal RHOAI"

        huggingface = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework for CPU tensor computation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "Internal Platform"
        s3Storage = softwareSystem "S3-Compatible Storage" "Optional model weight storage" "External"
        glooBackend = softwareSystem "Gloo Distributed Backend" "Tensor/data parallelism communication" "External"
        rayCluster = softwareSystem "Ray Cluster" "Optional distributed execution orchestration" "External"

        # Relationships
        user -> vllmCpu "Sends inference requests" "HTTP(S)/8000, gRPC/50051"
        vllmCpu -> huggingface "Downloads model weights and configs" "HTTPS/443, Bearer HF_TOKEN"
        vllmCpu -> pytorch "Executes model inference" "In-process"
        vllmCpu -> s3Storage "Loads model artifacts (optional)" "HTTPS/443, AWS IAM"
        vllmCpu -> otlpCollector "Exports distributed traces" "gRPC/OTLP"
        vllmCpu -> glooBackend "Distributed parallelism (optional)" "TCP"
        vllmCpu -> rayCluster "Distributed execution (optional)" "Ray/6379"

        prometheus -> vllmCpu "Scrapes metrics" "HTTP/8000"
        kserve -> vllmCpu "Deploys as InferenceService runtime" "Container Image"
        rhoaiDashboard -> kserve "Configures serving runtimes" "Kubernetes API"
        modelController -> vllmCpu "Manages pod lifecycle" "Kubernetes API"

        # Container relationships
        apiServer -> inputProcessor "Forwards parsed requests"
        grpcServer -> inputProcessor "Forwards parsed requests"
        inputProcessor -> engineCore "Sends tokenized input"
        engineCore -> cpuModelRunner "Schedules batch execution"
        cpuModelRunner -> outputProcessor "Returns inference results"
        outputProcessor -> apiServer "Sends streaming/complete response"
        cpuPlatform -> cpuModelRunner "Provides arch-specific config"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
