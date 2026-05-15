workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models on Intel Gaudi hardware"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi HPU plugin for vLLM providing high-performance LLM inference on Gaudi 2/3 accelerators" {
            apiServer = container "vLLM API Server" "OpenAI-compatible HTTP API server (port 8000)" "Python / vLLM Core v0.16.0"
            gaudiPlugin = container "vllm_gaudi Plugin" "HPU platform plugin: attention backends, model runner, worker, quantization, bucketing" "Python Plugin Package"
            hpuModelRunner = container "HPUModelRunner" "Executes model inference on Gaudi HPU with graph compilation and memory management" "Python / habana_frameworks"
            hpuWorker = container "HPUWorker" "Manages HPU device lifecycle, memory profiling, sleep/wake cycles, KV cache allocation" "Python"
            hpuCommunicator = container "HPU Communicator" "HCCL-based collective operations for tensor/data parallelism" "Python / HCCL"
            nixlConnector = container "NIXL Connector" "KV cache transfer for disaggregated prefill/decode serving" "Python / UCX" "Optional"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform that deploys and manages model serving runtimes" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing data science workloads and model deployments" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar injected by KServe for JWT validation and Kubernetes RBAC enforcement" "Internal RHOAI"

        synapeseAI = softwareSystem "Intel SynapseAI" "Habana runtime, drivers, and graph compiler for Gaudi 2/3 accelerators" "External"
        pytorchHabana = softwareSystem "PyTorch (Habana)" "PyTorch with Habana backend (habana_frameworks.torch)" "External"
        ray = softwareSystem "Ray" "Distributed execution framework for multi-card inference" "External"
        transformers = softwareSystem "HuggingFace Transformers" "Model architecture definitions, tokenizers, config loading" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model weight repository for downloading gated/public models" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model weight artifacts" "External"

        # Relationships
        datascientist -> kserve "Deploys InferenceService with Gaudi runtime"
        datascientist -> rhoaiDashboard "Selects Gaudi runtime for model serving"
        datascientist -> vllmGaudi "Sends inference requests via" "HTTPS/443"

        kserve -> vllmGaudi "Deploys as ServingRuntime container"
        kubeRbacProxy -> apiServer "Forwards authenticated requests to" "HTTP/8000"

        apiServer -> gaudiPlugin "Loads via Python entry points"
        gaudiPlugin -> hpuModelRunner "Delegates model execution"
        hpuModelRunner -> hpuWorker "Manages device and memory"
        hpuWorker -> hpuCommunicator "Coordinates distributed inference"
        hpuWorker -> nixlConnector "Transfers KV cache (disaggregated mode)"

        vllmGaudi -> synapeseAI "Uses for HPU graph compilation and device management"
        vllmGaudi -> pytorchHabana "Uses for tensor operations on Gaudi HPU"
        vllmGaudi -> ray "Uses for distributed worker coordination" "gRPC/6379"
        vllmGaudi -> transformers "Uses for model loading and tokenization"
        vllmGaudi -> huggingfaceHub "Downloads model weights" "HTTPS/443"
        vllmGaudi -> s3Storage "Downloads model artifacts" "HTTPS/443"
    }

    views {
        systemContext vllmGaudi "SystemContext" {
            include *
            autoLayout
        }

        container vllmGaudi "Containers" {
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
            element "Optional" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}
