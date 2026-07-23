workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models on Intel Gaudi accelerators"
        mlops = person "MLOps Engineer" "Configures serving runtimes and manages model deployments"

        vllmGaudi = softwareSystem "vllm-gaudi" "vLLM hardware plugin for Intel Gaudi HPU inference, packaged as odh-vllm-gaudi-rhel9 container image" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible REST API (completions, chat, embeddings, models)" "Python / vLLM v0.16.0" "Web Server"
            hpuPlatform = container "HpuPlatform" "HPU platform abstraction with 20+ override methods for device management, config, attention selection" "Python / vllm-gaudi Plugin"
            hpuModelRunner = container "HPUModelRunner" "6,597-line model execution engine handling forward passes, graph compilation, quantization, multimodal inputs" "Python / vllm-gaudi Plugin"
            hpuWorker = container "HPUWorker" "Worker process for HPU devices with HCCL distributed init, KV cache management, memory profiling" "Python / vllm-gaudi Plugin"
            unifiedAttention = container "Unified Attention" "Novel 3-path attention algorithm (causal + shared blocks + unique blocks) with flash-attention-style online softmax merge" "Python / vllm-gaudi Plugin"
            bucketingManager = container "HPUBucketingManager" "Dynamic shape bucketing (exponential, linear, vision strategies) for static shape graph compilation" "Python / vllm-gaudi Plugin"
            calibrationPipeline = container "Calibration Pipeline" "6-step FP8 quantization calibration using Intel Neural Compressor" "Bash / Python Scripts"
        }

        kserve = softwareSystem "KServe" "Kubernetes model serving platform deploying InferenceService pods" "Internal RHOAI"
        platformGateway = softwareSystem "Platform Gateway" "Envoy + kube-rbac-proxy providing TLS termination and auth" "Internal RHOAI"
        synapseAI = softwareSystem "Intel Gaudi Synapse AI" "Habana device drivers, graph compiler, runtime (v1.23.0)" "External"
        pytorchHPU = softwareSystem "PyTorch (Habana fork)" "Deep learning framework with HPU support (v2.9.0)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight repository" "External"
        inc = softwareSystem "Intel Neural Compressor" "FP8 quantization calibration library" "External"
        nixl = softwareSystem "NIXL / UCX" "Distributed KV cache transfer for disaggregated serving" "External"
        ray = softwareSystem "Ray" "Multi-node distributed inference orchestration" "External"
        konfluxCentral = softwareSystem "konflux-central" "Tekton CI/CD pipeline definitions" "Internal Red Hat"

        datascientist -> vllmGaudi "Sends inference requests via OpenAI API" "HTTPS/443 (via Gateway)"
        mlops -> kserve "Configures ServingRuntime CR" "kubectl / Dashboard"

        kserve -> vllmGaudi "Deploys as model serving container" "Container Image"
        platformGateway -> vllmGaudi "Forwards authenticated requests" "HTTP/8000"

        apiServer -> hpuPlatform "Registers HPU platform" "Python entry_points"
        apiServer -> hpuModelRunner "Dispatches inference" "In-process"
        hpuModelRunner -> unifiedAttention "Uses for attention computation"
        hpuModelRunner -> bucketingManager "Uses for shape bucketing"
        hpuModelRunner -> hpuWorker "Delegates device execution"
        calibrationPipeline -> hpuModelRunner "Produces FP8 quantized models"

        vllmGaudi -> synapseAI "Executes compiled graphs on Gaudi HPU" "PCIe/Fabric"
        vllmGaudi -> pytorchHPU "Runs tensor operations" "Python"
        vllmGaudi -> huggingface "Downloads model weights (optional)" "HTTPS/443"
        vllmGaudi -> inc "FP8 calibration (optional)" "Python"
        vllmGaudi -> nixl "KV cache transfer (optional)" "UCX Dynamic/TCP"
        vllmGaudi -> ray "Multi-node orchestration (optional)" "TCP Dynamic"
        konfluxCentral -> vllmGaudi "Provides Tekton pipeline definitions" "Git sync"
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
                background #4a90e2
                color #ffffff
            }
            element "Internal Red Hat" {
                background #cc0000
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
            element "Web Server" {
                shape WebBrowser
            }
        }
    }
}
