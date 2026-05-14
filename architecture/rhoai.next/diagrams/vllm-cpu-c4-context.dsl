workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and manages model deployments"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-only LLM inference serving engine with OpenAI-compatible API, supporting ppc64le and s390x architectures" {
            apiServer = container "OpenAI API Server" "FastAPI/uvicorn HTTP server exposing OpenAI-compatible endpoints for chat completions, embeddings, and more" "Python (FastAPI)" "Service"
            grpcServer = container "gRPC Server" "Alternative inference interface via gRPC protocol" "Python (grpcio)" "Service"
            authMiddleware = container "Auth Middleware" "Bearer token validation with SHA256 hashing and constant-time comparison" "Python" "Security"
            v1Engine = container "V1 EngineCore" "Core inference loop: scheduler, KV cache management, continuous batching, PagedAttention" "Python" "Engine"
            cpuModelRunner = container "CPU Model Runner" "CPU-specific model execution wrapping GPU runner APIs for CPU tensors" "Python" "Runner"
            cpuPlatform = container "CPU Platform" "Architecture detection (x86/ARM/PPC64LE/S390X), NUMA binding, OpenMP thread pinning" "Python" "Platform"
            inputProcessor = container "Input Processor" "Request tokenization and multi-modal input processing" "Python" "Processor"
            outputProcessor = container "Output Processor" "Incremental detokenization and streaming SSE/JSON output" "Python" "Processor"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native serverless ML inference platform managing InferenceService lifecycle" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User interface for configuring serving runtimes and model deployments" "Internal RHOAI"
        modelController = softwareSystem "Model Mesh / Model Controller" "Orchestrates model serving pod lifecycle" "Internal RHOAI"

        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model repository hosting model weights, configs, and tokenizers" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework for CPU tensor computation and model execution" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection and export" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts" "External"
        rayCluster = softwareSystem "Ray Cluster" "Optional distributed execution orchestration" "External"

        # Relationships - External
        dataScientist -> vllmCpu "Sends inference requests" "HTTP(S)/8000, gRPC/50051"
        mlEngineer -> rhoaiDashboard "Configures serving runtimes"

        # Relationships - Internal RHOAI
        kserve -> vllmCpu "Deploys as InferenceService runtime container" "Kubernetes"
        rhoaiDashboard -> kserve "Creates InferenceService CRs"
        modelController -> vllmCpu "Manages pod lifecycle" "Kubernetes"

        # Relationships - Container level
        dataScientist -> apiServer "POST /v1/chat/completions" "HTTP(S)/8000"
        apiServer -> authMiddleware "Validates Bearer token"
        apiServer -> inputProcessor "Processes request"
        inputProcessor -> v1Engine "Submits tokens"
        v1Engine -> cpuModelRunner "Executes model forward pass"
        cpuModelRunner -> cpuPlatform "Gets platform capabilities"
        v1Engine -> outputProcessor "Sends output tokens"
        outputProcessor -> apiServer "Streams response"

        # Relationships - External services
        vllmCpu -> huggingfaceHub "Downloads model weights and configs" "HTTPS/443, Bearer HF_TOKEN"
        vllmCpu -> pytorch "CPU tensor computation" "In-process"
        vllmCpu -> prometheus "Exposes /metrics endpoint" "HTTP/8000"
        vllmCpu -> otlpCollector "Exports traces" "gRPC (insecure default)"
        vllmCpu -> s3Storage "Loads model weights" "HTTPS/443, AWS IAM"
        vllmCpu -> rayCluster "Distributed execution" "Ray/6379"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
            description "vLLM CPU system context showing integration with RHOAI platform and external services"
        }

        container vllmCpu "Containers" {
            include *
            autoLayout
            description "vLLM CPU internal container architecture showing V1 engine pipeline"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Engine" {
                background #f5a623
                color #ffffff
            }
            element "Runner" {
                background #9b59b6
                color #ffffff
            }
            element "Platform" {
                background #9b59b6
                color #ffffff
            }
            element "Processor" {
                background #e67e22
                color #ffffff
            }
            element "Security" {
                background #e74c3c
                color #ffffff
            }
        }
    }
}
