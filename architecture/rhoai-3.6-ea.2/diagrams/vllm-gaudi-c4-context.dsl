workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and model deployments"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi HPU plugin for vLLM providing OpenAI-compatible LLM inference on Gaudi 2/3 accelerators" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible HTTP API for inference requests" "Python (vLLM)" "Web Server"
            hpuPlatform = container "HpuPlatform" "Platform abstraction for HPU device management, attention backends, and config overrides" "Python" "Plugin"
            hpuWorker = container "HPUWorker" "v1 worker managing HPU device lifecycle, model loading, and inference execution" "Python" "Worker"
            hpuModelRunner = container "HPUModelRunner" "Model execution, bucketing, profiling, and batch processing on HPU" "Python" "Runner"
            extension = container "Extension Module" "Feature detection, environment-based config, bucketing, profiling, defragmentation" "Python" "Configuration"
            ops = container "Custom Operations" "HPU-optimized fused ops: attention, MoE, rotary embeddings, LayerNorm, quantization" "Python/SynapseAI" "Compute Kernels"
        }

        vllm = softwareSystem "vLLM" "Core LLM inference engine (upstream)" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform managing ServingRuntime deployments" "Internal RHOAI"
        odhModelController = softwareSystem "odh-model-controller" "Controller managing lifecycle of model serving deployments" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh providing mTLS, traffic management, and auth enforcement" "External"
        modelStorage = softwareSystem "Model Storage" "S3, PVC, or HuggingFace Hub for model weight artifacts" "External"
        habanaDrivers = softwareSystem "Habana SynapseAI" "Intel Gaudi device drivers and PyTorch HPU bridge (v1.23.0)" "External"

        dataScientist -> vllmGaudi "Sends inference requests via" "HTTPS/443 (via platform ingress)"
        mlEngineer -> kserve "Configures serving runtimes for" "kubectl/API"

        kserve -> vllmGaudi "Deploys as ServingRuntime container image" "Container Image"
        odhModelController -> vllmGaudi "Manages deployment lifecycle" "Container Image"
        istio -> vllmGaudi "Provides mTLS and auth enforcement" "Sidecar Proxy / 8000/TCP"

        vllmGaudi -> vllm "Uses as core inference engine" "Python import (v0.16.0)"
        vllmGaudi -> habanaDrivers "Executes inference on HPU devices" "SynapseAI driver API"
        vllmGaudi -> modelStorage "Downloads model weights at startup" "HTTPS/443, TLS, IAM/token auth"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Web Server" {
                shape WebBrowser
            }
            element "Compute Kernels" {
                background #9b59b6
                color #ffffff
            }
        }
    }
}
