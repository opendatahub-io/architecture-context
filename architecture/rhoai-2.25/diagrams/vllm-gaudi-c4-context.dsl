workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM inference endpoints on Gaudi hardware"
        mlEngineer = person "ML Engineer" "Calibrates quantized models and configures multi-model serving"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi HPU plugin for vLLM enabling high-performance LLM inference on Gaudi2/Gaudi3 accelerators" {
            apiServer = container "vLLM API Server" "OpenAI-compatible FastAPI server with multi-model switching support" "Python/FastAPI/uvicorn" "Port 8000/TCP"
            multiModelEngine = container "MultiModelAsyncLLM" "Dynamic model switching engine with sleep/wake/reconfigure lifecycle" "Python"
            hpuModelRunner = container "HPUModelRunner" "Executes model forward passes with HPU graph compilation and bucketing" "Python/habana-frameworks"
            hpuWorker = container "HPUWorker" "Manages HPU device lifecycle, KV cache, profiling, and model execution" "Python"
            hpuPlatform = container "HpuPlatform" "Registers HPU as a vLLM platform, configures attention backends and quantization" "Python"
            extensionFramework = container "Extension Framework" "Runtime configuration, feature flags, bucketing strategies, profiling" "Python"
            calibrationTools = container "Calibration Tools" "FP8/INC quantization calibration pipeline (measure, postprocess, quantize, unify)" "Python Scripts"
        }

        vllm = softwareSystem "vLLM" "Core inference engine that vllm-gaudi extends via platform plugins" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform that deploys vllm-gaudi as a ServingRuntime" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User interface for configuring inference services" "Internal RHOAI"
        modelController = softwareSystem "Model Controller" "Manages InferenceService CR lifecycle and triggers container deployment" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        ray = softwareSystem "Ray" "Distributed computing framework for multi-HPU tensor/data parallel inference" "External"
        nixl = softwareSystem "NIXL" "KV cache transfer library for disaggregated prefill/decode between instances" "External"
        lmcache = softwareSystem "LMCache" "External KV cache connector for cache sharing across instances" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection for inference latency, throughput, KV cache utilization" "Internal RHOAI"
        gaudiHardware = softwareSystem "Intel Gaudi HPU" "Gaudi2/Gaudi3 AI accelerators with SynapseAI 1.24.0 runtime" "Hardware"

        dataScientist -> vllmGaudi "Sends inference requests via OpenAI-compatible API"
        mlEngineer -> vllmGaudi "Calibrates quantized models and switches active models"

        vllmGaudi -> vllm "Extends via platform_plugins and general_plugins entry points"
        kserve -> vllmGaudi "Deploys as ServingRuntime container" "InferenceService CR"
        rhoaiDashboard -> kserve "Users configure inference services" "UI"
        modelController -> kserve "Triggers deployment" "CRD lifecycle"
        vllmGaudi -> huggingfaceHub "Downloads model weights at startup" "HTTPS/443, Bearer HF_TOKEN"
        vllmGaudi -> ray "Worker coordination for multi-HPU inference" "TCP/6379, 8265"
        vllmGaudi -> nixl "KV cache transfer for disaggregated serving" "RDMA/TCP"
        vllmGaudi -> lmcache "External KV cache sharing" "TCP"
        vllmGaudi -> gaudiHardware "Executes inference on HPU devices" "HPU API/habana-frameworks"
        prometheus -> vllmGaudi "Scrapes inference metrics" "HTTP/8000"
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
                background #7b68ee
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
