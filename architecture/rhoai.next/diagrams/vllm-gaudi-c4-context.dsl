workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models via RHOAI Dashboard"
        mlEngineer = person "ML Engineer" "Configures model serving runtimes and quantization"

        vllmGaudi = softwareSystem "vLLM Gaudi" "Hardware plugin for vLLM enabling high-performance LLM inference on Intel Gaudi accelerators" {
            apiServer = container "vLLM API Server" "OpenAI-compatible REST API server for model inference" "Python / vLLM 0.16.0" "WebApp"
            hpuPlatform = container "HpuPlatform" "Core platform plugin — device detection, config validation, backend selection" "Python Plugin"
            attentionBackends = container "Attention Backends" "HPUAttention, MLA, UnifiedAttention, UnifiedMLA — optimized for Gaudi FusedSDPA" "Python"
            customOps = container "Custom Ops" "FusedMoE, FP8, GPTQ, AWQ, LayerNorm, RotaryEmbedding, CompressedTensors, Mamba/SSM" "Python / HPU Kernels"
            modelOverrides = container "Model Overrides" "Gaudi-optimized forward passes for 12+ model architectures" "Python"
            hpuWorker = container "HPUWorker" "Worker runtime for memory profiling, KV cache management, async execution on Gaudi" "Python"
            hpuModelRunner = container "HPUModelRunner" "Model execution pipeline on HPU devices" "Python"
            hpuCommunicator = container "HpuCommunicator" "HCCL-based distributed communication for tensor/pipeline/data parallelism" "Python / HCCL"
            extensionSystem = container "Extension System" "Feature flags, bucketing, profiling, defragmentation, config management" "Python"
            calibrationTools = container "Calibration Tools" "FP8 quantization calibration pipeline (6-step)" "Python Scripts"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform — manages InferenceService lifecycle" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI user interface — model deployment configuration" "Internal RHOAI"
        rhoaiController = softwareSystem "RHOAI Model Controller" "Manages InferenceService lifecycle and scaling" "Internal RHOAI"

        vllm = softwareSystem "vLLM (upstream)" "LLM inference engine — base framework extended by vllm_gaudi plugin" "External"
        synapseAI = softwareSystem "Intel SynapseAI Runtime" "Habana device drivers, graph compiler, TPC kernels (v1.23.0)" "External"
        habanaTorch = softwareSystem "habana-torch-plugin" "PyTorch bridge for Gaudi — graph mode, FusedSDPA, mark_step" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework (v2.9.0, forked for HPU backend)" "External"
        ray = softwareSystem "Ray" "Distributed execution framework for multi-card inference (>=2.48.0)" "External"
        transformers = softwareSystem "Hugging Face transformers" "Model loading and tokenization library (>=4.56.0)" "External"

        s3 = softwareSystem "S3 / MinIO Storage" "Model artifact storage — weights downloaded at startup" "External"
        huggingfaceHub = softwareSystem "Hugging Face Hub" "Model registry — model weights, tokenizers, configs" "External"
        gaudiHardware = softwareSystem "Intel Gaudi 2/3 Accelerator" "AI accelerator hardware for LLM inference" "Hardware"

        # Relationships - User
        dataScientist -> rhoaiDashboard "Selects vllm-gaudi as serving runtime"
        dataScientist -> kserve "Creates InferenceService via kubectl/Dashboard"
        dataScientist -> vllmGaudi "Sends inference requests" "HTTPS/443"
        mlEngineer -> calibrationTools "Runs FP8 calibration pipeline"

        # Relationships - Platform
        kserve -> vllmGaudi "Deploys as ServingRuntime container" "HTTP/8000"
        rhoaiDashboard -> kserve "Configures InferenceService"
        rhoaiController -> kserve "Manages lifecycle and scaling"

        # Relationships - Internal
        apiServer -> hpuPlatform "Routes to platform-specific execution"
        hpuPlatform -> attentionBackends "Selects attention backend"
        hpuPlatform -> hpuWorker "Dispatches work"
        hpuWorker -> hpuModelRunner "Executes model forward pass"
        hpuModelRunner -> customOps "Uses HPU-optimized operations"
        hpuModelRunner -> modelOverrides "Uses Gaudi-optimized model code"
        hpuWorker -> hpuCommunicator "Distributed communication"
        hpuPlatform -> extensionSystem "Configuration and feature management"

        # Relationships - External Dependencies
        vllmGaudi -> vllm "Extends via plugin entry points" "In-process"
        vllmGaudi -> synapseAI "Graph compilation, kernel execution" "Device driver"
        vllmGaudi -> habanaTorch "FusedSDPA, mark_step, HPU graphs" "In-process"
        vllmGaudi -> pytorch "Deep learning framework" "In-process"
        vllmGaudi -> ray "Multi-node worker management" "TCP/6379"
        vllmGaudi -> transformers "Model loading, tokenization" "In-process"
        vllmGaudi -> s3 "Downloads model weights" "HTTPS/443"
        vllmGaudi -> huggingfaceHub "Downloads models and configs" "HTTPS/443"
        vllmGaudi -> gaudiHardware "Executes inference" "SynapseAI HAL"
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
            element "Hardware" {
                background #d0021b
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "WebApp" {
                shape WebBrowser
            }
        }
    }
}
