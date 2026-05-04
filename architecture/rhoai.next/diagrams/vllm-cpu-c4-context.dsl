workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models on CPU hardware"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and manages model deployments"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-only LLM inference serving engine with OpenAI-compatible API (ppc64le, s390x)" {
            apiServer = container "vllm-openai" "OpenAI-compatible HTTP API server with 40+ endpoints" "Python/FastAPI" "Service"
            grpcServer = container "gRPC Server" "LLM inference via gRPC protocol" "Python/grpcio" "Service"
            v1Engine = container "V1 Engine (EngineCore)" "Core inference loop: scheduler, KV cache, batch management" "Python" "Library"
            cpuRunner = container "CPU Model Runner" "CPU-specific model execution adapting GPU runner for CPU tensors" "Python/PyTorch" "Library"
            cpuPlatform = container "CPU Platform" "Architecture detection (x86, ARM, PPC64LE, S390X) and feature support" "Python" "Library"
            inputProcessor = container "Input Processor" "Tokenization and request preprocessing" "Python/transformers" "Library"
            outputProcessor = container "Output Processor" "Detokenization and response streaming (SSE/JSON)" "Python" "Library"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform managing InferenceService lifecycle" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User interface for configuring serving runtimes" "Internal RHOAI"
        modelController = softwareSystem "Model Mesh / Controller" "Manages model serving pod lifecycle" "Internal RHOAI"

        huggingFace = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        rhStats = softwareSystem "Red Hat Stats" "Usage statistics reporting service" "External"

        pytorch = softwareSystem "PyTorch" "Deep learning framework for CPU tensor computation" "External"

        # Relationships
        dataScientist -> vllmCpu "Sends inference requests via" "HTTP(S)/8000, gRPC/50051"
        mlEngineer -> rhoaiDashboard "Configures serving runtimes via" "HTTPS"

        rhoaiDashboard -> kserve "Creates InferenceService referencing vLLM image" "Kubernetes API"
        kserve -> vllmCpu "Deploys and manages as InferenceService runtime" "Container orchestration"
        modelController -> vllmCpu "Manages pod lifecycle" "Kubernetes API"

        vllmCpu -> huggingFace "Downloads model weights and configs" "HTTPS/443, Bearer HF_TOKEN"
        vllmCpu -> s3Storage "Loads model weights from object storage" "HTTPS/443, AWS IAM"
        vllmCpu -> prometheus "Exposes metrics for scraping" "HTTP/8000"
        vllmCpu -> otlpCollector "Exports distributed traces" "gRPC/HTTP (configurable)"
        vllmCpu -> rhStats "Reports usage statistics" "HTTPS/443"
        vllmCpu -> pytorch "Executes model inference on CPU" "In-process"

        # Container relationships
        apiServer -> inputProcessor "Forwards parsed requests"
        grpcServer -> inputProcessor "Forwards parsed requests"
        inputProcessor -> v1Engine "Submits tokenized requests"
        v1Engine -> cpuRunner "Dispatches model execution"
        cpuRunner -> outputProcessor "Returns inference results"
        cpuPlatform -> cpuRunner "Provides arch-specific config"
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
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Library" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
