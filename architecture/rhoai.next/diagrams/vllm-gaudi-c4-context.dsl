workspace {
    model {
        user = person "Data Scientist" "Deploys and queries LLM models on Gaudi hardware via RHOAI"

        vllmGaudi = softwareSystem "vLLM Gaudi" "HPU plugin for vLLM enabling high-performance LLM inference on Intel Gaudi accelerators" {
            apiServer = container "vLLM API Server" "OpenAI-compatible REST API server (port 8000)" "Python / vLLM v0.16.0"
            hpuPlatform = container "HpuPlatform Plugin" "Core platform plugin — device detection, attention backend selection, config validation" "Python Plugin"
            attentionBackends = container "HPU Attention Backends" "HPUAttention, MLA, UnifiedAttention, UnifiedMLA — optimized for Gaudi FusedSDPA" "Python"
            customOps = container "HPU Custom Ops" "FusedMoE, FP8, GPTQ, AWQ, LayerNorm, RotaryEmbedding, CompressedTensors, Mamba ops" "Python / Habana"
            modelOverrides = container "HPU Model Overrides" "Gaudi-optimized forward passes for 12+ architectures (DeepSeek, Qwen, Gemma, Pixtral, etc.)" "Python"
            hpuWorker = container "HPUWorker / HPUModelRunner" "Worker lifecycle, memory profiling, KV cache allocation, async execution" "Python"
            communicator = container "HpuCommunicator" "HCCL-based all-reduce, all-gather, reduce-scatter for distributed inference" "Python / HCCL"
            extensionSystem = container "Extension System" "Dynamic config, feature flags, bucketing, profiling, defragmentation" "Python"
        }

        kserve = softwareSystem "KServe" "Kubernetes inference serving platform — manages InferenceService lifecycle" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web console for selecting serving runtimes and deploying models" "Internal RHOAI"
        rhoaiController = softwareSystem "RHOAI Model Controller" "Manages InferenceService lifecycle and scaling" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar for TLS termination and Kubernetes RBAC enforcement" "Internal RHOAI"

        synapseAI = softwareSystem "Intel SynapseAI Runtime" "Habana device drivers, graph compiler, TPC kernels (v1.23.0)" "External Hardware"
        pytorch = softwareSystem "PyTorch for Gaudi" "Deep learning framework with HPU backend (v2.9.0)" "External"
        ray = softwareSystem "Ray" "Distributed execution framework for multi-card/multi-node inference" "External"

        s3 = softwareSystem "S3 / MinIO" "Object storage for ML model weights" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model registry for downloading model weights and tokenizers" "External"

        user -> rhoaiDashboard "Selects vllm-gaudi serving runtime"
        user -> kserve "Creates InferenceService via kubectl/API"
        user -> vllmGaudi "Sends inference requests" "HTTPS/443"

        kserve -> vllmGaudi "Routes inference traffic" "HTTP/8000"
        rhoaiDashboard -> kserve "Configures serving runtimes"
        rhoaiController -> kserve "Manages InferenceService lifecycle"
        kubeRbacProxy -> vllmGaudi "Forwards authenticated requests" "HTTP/8000 (localhost)"

        vllmGaudi -> synapseAI "Executes model inference on Gaudi devices" "SynapseAI HAL"
        vllmGaudi -> pytorch "Deep learning operations" "In-process"
        vllmGaudi -> ray "Distributed worker management" "Ray/6379"
        vllmGaudi -> s3 "Downloads model weights" "HTTPS/443"
        vllmGaudi -> huggingFace "Downloads models and tokenizers" "HTTPS/443"
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
            element "External Hardware" {
                background #9b59b6
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                shape Person
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
