workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models on Gaudi hardware"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and quantization"

        vllmGaudi = softwareSystem "vLLM Gaudi" "HPU plugin for vLLM enabling high-performance LLM inference on Intel Gaudi accelerators" {
            apiServer = container "vLLM API Server" "OpenAI-compatible REST API server serving /v1/completions, /v1/chat/completions, /v1/models, /v1/embeddings" "Python / uvicorn" "Web Server"
            hpuPlatform = container "HpuPlatform Plugin" "Core platform class — device detection, config validation, attention backend selection, memory management" "Python Plugin"
            attentionBackends = container "HPU Attention Backends" "HPUAttention, HPU MLA, HPU UnifiedAttention, HPU UnifiedMLA — optimized for Gaudi FusedSDPA" "Python"
            customOps = container "HPU Custom Ops" "FusedMoE, FP8, GPTQ, AWQ, LayerNorm, RotaryEmbedding, CompressedTensors, Mamba/SSM ops" "Python / HPU kernels"
            modelOverrides = container "HPU Model Overrides" "Gaudi-optimized forward passes for 12+ architectures (DeepSeek, Qwen, Gemma, Pixtral, etc.)" "Python"
            hpuWorker = container "HPUWorker / HPUModelRunner" "Worker lifecycle, memory profiling, KV cache allocation, async execution on Gaudi devices" "Python"
            hpuCommunicator = container "HpuCommunicator" "HCCL-based all-reduce, all-gather, reduce-scatter for distributed inference" "Python / HCCL"
            calibTools = container "Calibration Tools" "FP8 quantization calibration pipeline for model weight quantization" "Python scripts"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform — deploys vllm-gaudi as InferenceService" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User interface for model deployment and runtime selection" "Internal RHOAI"
        rhoaiController = softwareSystem "RHOAI Model Controller" "Manages InferenceService lifecycle and scaling" "Internal RHOAI"

        synapseAI = softwareSystem "Intel Gaudi SynapseAI" "Habana device drivers, graph compiler, TPC kernels (v1.23.0)" "External Hardware"
        pytorch = softwareSystem "PyTorch 2.9.0" "Deep learning framework — Gaudi fork with HPU backend" "External"
        vllmUpstream = softwareSystem "vLLM v0.16.0" "LLM inference engine — base framework extended by this plugin" "External"
        ray = softwareSystem "Ray" "Distributed execution framework for multi-card/multi-node inference" "External"

        s3 = softwareSystem "S3 / MinIO" "Model artifact storage for weight download at startup" "External Service"
        huggingFace = softwareSystem "Hugging Face Hub" "Model registry for weights, tokenizers, and configs" "External Service"

        # User interactions
        dataScientist -> vllmGaudi "Sends inference requests via OpenAI-compatible API" "HTTPS/443"
        mlEngineer -> rhoaiDashboard "Selects vllm-gaudi serving runtime" "HTTPS"

        # Internal RHOAI interactions
        rhoaiDashboard -> kserve "Creates InferenceService with vllm-gaudi runtime" "Kubernetes API"
        rhoaiController -> kserve "Manages InferenceService lifecycle" "Kubernetes API"
        kserve -> vllmGaudi "Routes inference traffic to vllm-gaudi container" "HTTP/8000"

        # Plugin/framework interactions
        vllmGaudi -> vllmUpstream "Extends via vllm.platform_plugins and vllm.general_plugins entry points" "In-process"
        vllmGaudi -> synapseAI "Device communication via SynapseAI HAL" "System library"
        vllmGaudi -> pytorch "Torch operations via habana-torch-plugin" "In-process"
        vllmGaudi -> ray "Multi-node worker management" "Ray protocol/6379"

        # External service interactions
        vllmGaudi -> s3 "Downloads model weights at startup" "HTTPS/443, AWS IAM"
        vllmGaudi -> huggingFace "Downloads models and tokenizers" "HTTPS/443, Bearer Token"
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
                background #666666
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
            element "Web Server" {
                shape WebBrowser
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
        }
    }
}
