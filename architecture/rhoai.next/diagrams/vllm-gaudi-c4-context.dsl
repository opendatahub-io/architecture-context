workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM inference endpoints"
        mlops = person "MLOps Engineer" "Configures serving runtimes and hardware acceleration"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi hardware plugin for vLLM inference engine, enabling LLM serving on HPU accelerators" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible REST API for completions, chat, embeddings" "Python (uvicorn)" "Web Server"
            hpuPlatform = container "HpuPlatform" "Registers Gaudi as vLLM platform, configures device settings and attention backends" "Python Plugin"
            hpuModelRunner = container "HPUModelRunner" "Orchestrates model forward passes with HPU-optimized bucketing and graph compilation" "Python"
            hpuWorker = container "HPUWorker" "Manages model execution, KV cache, and HPU device lifecycle" "Python"
            attentionBackends = container "Attention Backends" "HPUAttentionV1, HPUUnifiedAttention, HPUMLAAttention, HPUUnifiedMLA" "Python/HPU Kernels"
            customOps = container "Custom Ops" "HPU-optimized FP8, FusedMoE, LayerNorm, RotaryEmb, LoRA, Mamba kernels" "Python/HPU Kernels"
            extensionFramework = container "Extension Framework" "Runtime configuration, feature detection, bucketing strategies" "Python"
            hpuCommunicator = container "HpuCommunicator" "HCCL-based collective operations for tensor/data/expert parallelism" "Python/HCCL"
            modelOverrides = container "Model Overrides" "HPU-specific model implementations for Gemma3, Qwen, DeepSeek, etc." "Python"
        }

        vllmCore = softwareSystem "vLLM Core" "Core inference engine providing pluggable hardware architecture" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework with Habana PT bridge" "External"
        synapseAI = softwareSystem "Intel Synapse AI" "Habana driver stack, graph compiler, runtime libraries" "External"
        ray = softwareSystem "Ray" "Distributed execution framework for multi-HPU inference" "External"
        transformers = softwareSystem "HuggingFace Transformers" "Model loading, tokenization, HuggingFace model hub" "External"
        inc = softwareSystem "Intel Neural Compressor" "FP8 quantization calibration and inference" "External"
        nixl = softwareSystem "NIXL" "KV cache transfer for disaggregated prefill/decode" "External"

        kserve = softwareSystem "KServe / ModelMesh" "Serving runtime platform that deploys vllm-gaudi container" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI operator managing platform lifecycle" "Internal RHOAI"
        platformIngress = softwareSystem "Gateway API / kube-rbac-proxy" "Auth enforcement and TLS termination sidecar" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External Service"
        gaudiHPU = softwareSystem "Intel Gaudi 2/3 HPU" "Hardware accelerator for ML inference" "Hardware"

        # User relationships
        datascientist -> vllmGaudi "Sends inference requests via OpenAI API" "HTTPS/443"
        mlops -> kserve "Configures serving runtime" "kubectl/API"

        # Internal container relationships
        apiServer -> hpuModelRunner "Routes inference requests" "In-process"
        hpuModelRunner -> attentionBackends "Selects attention implementation" "In-process"
        hpuModelRunner -> customOps "Uses optimized kernels" "In-process"
        hpuModelRunner -> modelOverrides "Loads HPU-specific models" "In-process"
        hpuWorker -> hpuModelRunner "Manages execution" "In-process"
        hpuPlatform -> extensionFramework "Configures runtime" "In-process"
        extensionFramework -> hpuModelRunner "Applies configuration" "In-process"
        hpuWorker -> hpuCommunicator "Collective communication" "HCCL/TCP"

        # External dependency relationships
        vllmGaudi -> vllmCore "Extends via Python entry_points plugin system" "In-process"
        vllmGaudi -> pytorch "Uses for tensor operations and HPU bridge" "In-process"
        vllmGaudi -> synapseAI "Uses for graph compilation and HPU runtime" "Driver API"
        vllmGaudi -> ray "Uses for distributed multi-HPU orchestration" "TCP/6379, 10001"
        vllmGaudi -> transformers "Uses for model loading and tokenization" "In-process"
        vllmGaudi -> inc "Uses for FP8 quantization" "In-process"
        vllmGaudi -> nixl "Uses for KV cache transfer (disaggregated serving)" "UCX/TCP"
        vllmGaudi -> gaudiHPU "Executes inference on hardware" "PCIe/RDMA"

        # Platform relationships
        kserve -> vllmGaudi "Deploys as serving runtime container" "Container Image"
        rhodsOperator -> kserve "Manages serving platform" "Kubernetes API"
        platformIngress -> vllmGaudi "Terminates TLS, enforces auth" "8443→8000/TCP"

        # Egress
        vllmGaudi -> hfHub "Downloads model weights at startup" "HTTPS/443, HF_TOKEN"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
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
            element "Hardware" {
                background #e1d5e7
                color #333333
            }
            element "Person" {
                shape person
                background #08427b
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
