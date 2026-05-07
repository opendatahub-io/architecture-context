workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM inference endpoints on Intel Gaudi hardware"
        mlEngineer = person "ML Engineer" "Configures model serving, quantization, and parallelism strategies"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi hardware plugin for vLLM providing optimized LLM inference with OpenAI-compatible API" {
            apiServer = container "vLLM API Server" "OpenAI-compatible REST API (completions, chat, embeddings, models)" "Python / FastAPI" "Application"
            hpuPlatform = container "HPU Platform Plugin" "Registers HpuPlatform via vllm.platform_plugins entry point; routes to HPU workers and attention backends" "Python Plugin"
            extensionFramework = container "Extension Framework" "Lazy-evaluated config engine with feature flags for bucketing, compilation, quantization, attention modes" "Python"
            customOps = container "Custom Operators" "HPU-optimized rotary embeddings, layer norm, FP8/AWQ/GPTQ quantization, MoE, Mamba SSM" "Python / HPU Kernels"
            attentionBackends = container "Attention Backends" "Paged attention, unified attention, MLA, unified MLA for Gaudi accelerators" "Python / HPU Kernels"
            hpuWorker = container "HPU Worker" "Model execution with HCCL distributed comm, KV cache management, HPU graph compilation, profiling" "Python"
            distributedComm = container "Distributed Communication" "HCCL communicator (all-reduce, all-gather), NIXL KV connector, expert parallelism" "Python / HCCL / NIXL"
            modelOverrides = container "Model Overrides" "HPU-optimized implementations for Gemma3, Qwen2.5-VL, Qwen3-VL, Qwen3-MoE" "Python"
            calibration = container "Calibration Tools" "FP8 model calibration pipeline: device detection, measurement, quantization, scale unification" "Python Scripts"
        }

        kserve = softwareSystem "KServe / ServingRuntime" "Kubernetes model serving infrastructure that deploys vllm-gaudi containers" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar injected by RHOAI platform" "Internal RHOAI"
        vllmUpstream = softwareSystem "vLLM" "Core inference engine (v0.14.1) providing model serving framework" "External"
        gaudiSoftware = softwareSystem "Intel Gaudi Software (Synapse AI)" "Habana drivers, firmware, graph compiler, and HPU runtime (v1.23.0)" "External"
        pytorchGaudi = softwareSystem "PyTorch for Gaudi" "PyTorch framework with HPU backend support (v2.9.0)" "External"
        ray = softwareSystem "Ray" "Distributed execution and worker orchestration for multi-node inference" "External"
        modelStorage = softwareSystem "Model Storage" "PVC, NFS, or S3 object storage for model weights" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and tokenizer repository" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        # User relationships
        dataScientist -> kserve "Creates InferenceService CR to deploy model"
        dataScientist -> vllmGaudi "Sends inference requests via KServe route"
        mlEngineer -> vllmGaudi "Configures quantization, parallelism, bucketing via env vars"
        mlEngineer -> calibration "Runs FP8 calibration pipeline"

        # Internal container relationships
        apiServer -> hpuWorker "Schedules inference requests"
        hpuPlatform -> extensionFramework "Initializes runtime configuration"
        hpuPlatform -> hpuWorker "Routes to HPU worker class"
        hpuPlatform -> attentionBackends "Selects attention backend"
        extensionFramework -> customOps "Configures operator behavior"
        hpuWorker -> customOps "Executes HPU-optimized operators"
        hpuWorker -> attentionBackends "Runs attention computation"
        hpuWorker -> distributedComm "Coordinates multi-card execution"
        hpuWorker -> modelOverrides "Loads HPU-optimized model implementations"

        # External relationships
        kubeRbacProxy -> apiServer "Proxies authenticated requests" "HTTP/8000 plaintext"
        kserve -> vllmGaudi "References container image in ServingRuntime CR"
        vllmGaudi -> vllmUpstream "Extends via plugin architecture" "Python entry points"
        vllmGaudi -> gaudiSoftware "Uses HPU drivers and graph compiler" "PCIe/RDMA"
        vllmGaudi -> pytorchGaudi "Executes models on HPU backend" "Python API"
        vllmGaudi -> ray "Orchestrates distributed workers" "RPC/6379"
        vllmGaudi -> modelStorage "Loads model weights at startup" "Filesystem/HTTPS"
        vllmGaudi -> huggingfaceHub "Downloads tokenizers and configs" "HTTPS/443"
        prometheus -> vllmGaudi "Scrapes /metrics endpoint" "HTTP/8000"
    }

    views {
        systemContext vllmGaudi "SystemContext" {
            include *
            autoLayout
            description "System context showing vllm-gaudi in the RHOAI model serving ecosystem"
        }

        container vllmGaudi "Containers" {
            include *
            autoLayout
            description "Internal container architecture of the vllm-gaudi plugin"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
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
            element "Application" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
