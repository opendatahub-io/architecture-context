workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and model deployments"

        vllmGaudi = softwareSystem "vllm-gaudi" "HPU plugin + inference server for vLLM on Intel Gaudi accelerators, exposing OpenAI-compatible API" {
            plugin = container "vllm-gaudi Plugin" "HPU platform registration, custom ops, attention backends, model overrides" "Python Package"
            hpuPlatform = container "HpuPlatform" "Platform interface implementation for HPU devices" "Python Class"
            hpuWorker = container "HPUWorker" "vLLM v1 worker for HPU inference execution, memory profiling, KV cache" "Python Class"
            customOps = container "HPU Custom Ops" "Fused MoE, attention, FP8/AWQ/GPTQ quantization, rotary embedding, LoRA, Mamba" "Python Modules"
            modelOverrides = container "HPU Model Overrides" "Model-specific HPU implementations for Gemma3, Qwen, DeepSeek, Pixtral, and others" "Python Modules"
            apiServer = container "OpenAI API Server" "vLLM entrypoint serving /v1/completions, /v1/chat/completions, /v1/models, /v1/embeddings" "Python HTTP Server" "Port 8000"
        }

        vllm = softwareSystem "vLLM" "Core inference engine providing plugin framework and serving infrastructure" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform managing ServingRuntimes" "Internal RHOAI"
        modelController = softwareSystem "Model Controller" "Operator registering serving runtimes as Kubernetes CRDs" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh providing mTLS, auth, and traffic management" "Internal RHOAI"
        synapseAI = softwareSystem "Intel SynapseAI SDK" "Gaudi accelerator driver, firmware, and runtime libraries" "External"
        modelStorage = softwareSystem "Model Storage" "S3/PVC for model weight artifacts" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model repository for downloading model weights" "External"
        gaudiHPU = softwareSystem "Intel Gaudi HPU" "Gaudi 2 / Gaudi 3 accelerator hardware" "External Hardware"

        dataScientist -> vllmGaudi "Sends inference requests via KServe endpoint" "HTTPS/443"
        mlEngineer -> kserve "Creates InferenceService with vllm-gaudi runtime" "kubectl"

        vllmGaudi -> vllm "Extends via plugin interface" "Python entry points"
        vllmGaudi -> synapseAI "Uses for HPU compute" "SynapseAI API"
        vllmGaudi -> gaudiHPU "Executes inference on" "PCIe/HCCL"
        vllmGaudi -> modelStorage "Downloads model weights" "HTTPS/443, NFS"
        vllmGaudi -> hfHub "Downloads models" "HTTPS/443"

        kserve -> vllmGaudi "Deploys as ServingRuntime container" "Container lifecycle"
        modelController -> kserve "Registers vllm-gaudi runtime" "ServingRuntime CRD"
        istio -> vllmGaudi "Provides mTLS sidecar and auth enforcement" "Envoy sidecar"
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
            element "External Hardware" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
