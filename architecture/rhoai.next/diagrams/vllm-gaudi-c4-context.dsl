workspace {
    model {
        user = person "Data Scientist" "Creates and deploys LLM inference workloads on Intel Gaudi hardware"

        vllmGaudi = softwareSystem "vllm-gaudi" "vLLM hardware plugin enabling high-performance LLM inference on Intel Gaudi accelerators" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible HTTP API for completions, chat, embeddings" "Python / vLLM 0.16.0" "Port 8000/TCP"
            hpuPlatform = container "HpuPlatform" "Registers HPU as out-of-tree platform in vLLM's plugin framework" "Python Plugin"
            hpuWorker = container "HPUWorker" "Manages HPU device init, memory profiling, distributed communication" "Python"
            hpuModelRunner = container "HPUModelRunner" "Core model execution: forward passes, KV cache, attention, graph compilation" "Python (~6600 lines)"
            extensionModule = container "Extension Module" "Configuration framework with 150+ feature flags, hardware detection, bucketing, profiling" "Python"
            attentionBackends = container "Attention Backends" "Standard, MLA, Unified, Unified-MLA attention implementations" "Python (~4000+ lines)"
            quantizationEngine = container "Quantization Engine" "FP8, INC, GPTQ, AWQ, Compressed-Tensors, ModelOpt quantization support" "Python"
            distributedComm = container "Distributed Communication" "HPU communicator (HCCL), NIXL KV transfer, data parallel MoE" "Python"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication and authorization sidecar proxy" "Platform-injected"
        kserve = softwareSystem "KServe" "Model serving orchestration via ServingRuntime CRDs" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User interface for selecting and managing serving runtimes" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores container image references for model serving" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator managing deployments" "Internal RHOAI"

        vllm = softwareSystem "vLLM (upstream)" "Core LLM inference engine providing the plugin framework" "External" {
            tags "External"
        }
        synapseAI = softwareSystem "Intel Gaudi SynapseAI" "Habana device drivers, graph compiler, and runtime libraries (v1.23.0)" "External" {
            tags "External"
        }
        pytorchHPU = softwareSystem "PyTorch (Habana fork)" "PyTorch with HPU backend support (v2.9.0)" "External" {
            tags "External"
        }
        ray = softwareSystem "Ray" "Distributed computing framework for multi-device inference" "External" {
            tags "External"
        }
        huggingFace = softwareSystem "HuggingFace Hub" "Model weight and tokenizer downloads" "External" {
            tags "External"
        }
        s3Storage = softwareSystem "S3 Storage" "Model artifact storage (AWS S3, MinIO, or compatible)" "External" {
            tags "External"
        }

        # User relationships
        user -> rhoaiDashboard "Selects vLLM-Gaudi runtime for Intel Gaudi workloads"
        user -> vllmGaudi "Sends inference requests via HTTPS"

        # Platform relationships
        kserve -> vllmGaudi "Deploys container image as InferenceService"
        rhodsOperator -> kserve "Manages KServe deployment"
        rhoaiDashboard -> kserve "Triggers model serving deployments"
        modelRegistry -> kserve "Provides container image references"
        kubeRbacProxy -> vllmGaudi "Proxies authenticated requests" "HTTPS 8443 → HTTP 8000"

        # Internal container relationships
        apiServer -> hpuPlatform "Loads via plugin entry points"
        hpuPlatform -> hpuWorker "Registers HPU workers"
        hpuPlatform -> extensionModule "Loads configuration"
        hpuWorker -> hpuModelRunner "Executes model inference"
        hpuModelRunner -> attentionBackends "Selects attention implementation"
        hpuModelRunner -> quantizationEngine "Applies quantization"
        hpuWorker -> distributedComm "Coordinates distributed inference"

        # External dependency relationships
        vllmGaudi -> vllm "Plugin framework (v0.16.0)" "Python entry points"
        vllmGaudi -> synapseAI "Device drivers and graph compiler" "Shared libraries"
        vllmGaudi -> pytorchHPU "Tensor operations on HPU" "Python library"
        vllmGaudi -> ray "Multi-HPU worker coordination" "TCP/6379"
        vllmGaudi -> huggingFace "Downloads model weights" "HTTPS/443, HF_TOKEN"
        vllmGaudi -> s3Storage "Downloads model artifacts" "HTTPS/443, AWS IAM"
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
            element "Platform-injected" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
