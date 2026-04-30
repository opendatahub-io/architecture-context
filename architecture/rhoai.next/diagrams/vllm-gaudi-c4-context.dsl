workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models on Intel Gaudi hardware"
        platformAdmin = person "Platform Admin" "Configures RHOAI and selects serving runtimes"

        vllmGaudi = softwareSystem "vllm-gaudi" "vLLM hardware plugin enabling high-performance LLM inference on Intel Gaudi (Habana) accelerators" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible REST API for inference requests" "Python / vLLM" "WebBrowser"
            hpuPlatform = container "HpuPlatform" "Registers HPU as an out-of-tree platform in vLLM's plugin registry" "Python"
            hpuWorker = container "HPUWorker" "Manages HPU device initialization, memory profiling, and distributed communication" "Python"
            hpuModelRunner = container "HPUModelRunner" "Core model execution engine handling forward passes, KV cache, attention metadata, and graph compilation" "Python"
            extensionModule = container "Extension Module" "Configuration framework with feature flags, hardware detection, bucketing, and profiling" "Python"
            attentionBackends = container "Attention Backends" "Standard HPU, MLA, Unified, and Unified MLA attention implementations" "Python / SynapseAI"
            quantization = container "Quantization Module" "FP8, INC, GPTQ, AWQ, compressed-tensors, and ModelOpt quantization support" "Python"
            distributedComms = container "Distributed Communication" "HPU communicator, NIXL KV connector, and data parallel utilities" "Python / HCCL"
        }

        containerImage = softwareSystem "odh-vllm-gaudi-rhel9" "Production container image bundling SynapseAI, PyTorch, vLLM, and vllm-gaudi plugin" "Container"

        vllm = softwareSystem "vLLM" "Core LLM inference engine providing the plugin framework" "External"
        synapseAI = softwareSystem "Intel Gaudi SynapseAI" "Habana device drivers, graph compiler, and runtime libraries" "External"
        pytorchHPU = softwareSystem "PyTorch HPU" "PyTorch with Habana HPU backend support" "External"
        ray = softwareSystem "Ray" "Distributed computing framework for multi-device inference" "External"

        kserve = softwareSystem "KServe" "Orchestrates model serving pods via ServingRuntime CRDs" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication and authorization sidecar proxy" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "UI for selecting serving runtimes and managing models" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores container image references for model serving" "Internal RHOAI"

        huggingface = softwareSystem "HuggingFace Hub" "Model weight and tokenizer downloads" "External Service"
        s3 = softwareSystem "S3 / Object Storage" "Model artifact storage" "External Service"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for RBAC and resource management" "External Service"

        # Relationships
        dataScientist -> vllmGaudi "Sends inference requests via HTTPS/8443" "HTTPS"
        dataScientist -> rhoaiDashboard "Selects vLLM-Gaudi runtime" "HTTPS"
        platformAdmin -> kserve "Configures ServingRuntime" "kubectl"

        vllmGaudi -> vllm "Registers as HPU platform plugin" "Python entry points"
        vllmGaudi -> synapseAI "Uses device drivers and graph compiler" "In-process"
        vllmGaudi -> pytorchHPU "Uses HPU tensor operations" "In-process"
        vllmGaudi -> ray "Coordinates distributed inference" "TCP/6379"
        vllmGaudi -> huggingface "Downloads model weights" "HTTPS/443"
        vllmGaudi -> s3 "Downloads model artifacts" "HTTPS/443"

        kubeRBACProxy -> vllmGaudi "Proxies authenticated requests 8443→8000" "HTTP"
        kserve -> containerImage "Deploys as InferenceService container" "Container"
        modelRegistry -> kserve "Provides image references" "API"

        # Container relationships
        apiServer -> hpuWorker "Dispatches inference requests" "In-process"
        hpuWorker -> hpuModelRunner "Manages model execution" "In-process"
        hpuModelRunner -> attentionBackends "Selects attention implementation" "In-process"
        hpuModelRunner -> quantization "Applies quantization during loading" "In-process"
        hpuWorker -> distributedComms "Coordinates multi-HPU inference" "HCCL/Ray"
        extensionModule -> hpuModelRunner "Provides configuration and feature flags" "In-process"
        hpuPlatform -> vllm "Registers HPU platform" "Entry points"
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
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #e67e22
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
