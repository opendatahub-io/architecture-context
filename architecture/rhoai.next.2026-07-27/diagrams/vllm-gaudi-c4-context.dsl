workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries ML models on Intel Gaudi hardware"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi (HPU) acceleration plugin for vLLM, providing hardware-specific platform integration, attention backends, custom ops, model support, and distributed inference" {
            hpuPlatform = container "HpuPlatform" "Registers HPU backend with vLLM via platform_plugins entry point; selects attention backend and quantization methods" "Python"
            hpuAttention = container "HPU Attention Backends" "Four backends: HPUUnifiedAttention, HPUUnifiedMLA, HPUMLA, HPUAttentionV1; dynamically selected based on MLA mode" "Python"
            hpuCustomOps = container "HPU Custom Ops" "FP8, fused MoE, rotary embedding, and other HPU-optimized operator kernels" "Python / C++"
            hpuWorker = container "HPU Worker" "Manages per-device inference execution and model forward passes" "Python"
            hpuCommunicator = container "HpuCommunicator" "Handles collective operations (all-reduce, all-gather) via HCCL for multi-device inference" "Python"
            nixlConnector = container "NIXL KV Connector" "Transfers KV cache between prefill and decode nodes for disaggregated serving" "Python"
            modelRegistry = container "HPU Model Registry" "Registers HPU-adapted model implementations via general_plugins entry point" "Python"
        }

        vllmCore = softwareSystem "vLLM Core" "High-throughput LLM inference engine with OpenAI-compatible API" "External"
        rhoaiServing = softwareSystem "RHOAI Model Serving" "Red Hat OpenShift AI model serving layer (KServe)" "Internal RHOAI"
        synapseAI = softwareSystem "Habana Synapse AI" "Intel Gaudi software stack and runtime (v1.23.0)" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework (v2.9.0)" "External"
        transformers = softwareSystem "HuggingFace Transformers" "Tokenization and model loading (>=4.56.0)" "External"
        ray = softwareSystem "Ray" "Distributed computing framework for multi-node inference (>=2.48.0)" "External"
        gaudiHardware = softwareSystem "Intel Gaudi HPU" "Hardware accelerator for AI/ML inference" "External Hardware"

        user -> rhoaiServing "Deploys InferenceService and sends inference requests"
        rhoaiServing -> vllmCore "Routes inference requests to vLLM serving pod"
        vllmCore -> vllmGaudi "Loads HPU plugin via setuptools entry points"
        vllmGaudi -> synapseAI "Uses for HPU device management and kernel execution"
        vllmGaudi -> pytorch "Uses for tensor operations and autograd"
        vllmGaudi -> transformers "Uses for tokenizer and model weight loading"
        vllmGaudi -> ray "Uses for distributed multi-node coordination"
        vllmGaudi -> gaudiHardware "Executes inference kernels on Gaudi accelerators"
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
            }
            element "External Hardware" {
                background #f5a623
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
