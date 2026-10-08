workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        application = person "Application" "Sends inference requests to deployed models"

        vllmGaudi = softwareSystem "vllm-gaudi" "Hardware plugin enabling vLLM large-language-model inference on Intel Gaudi (Habana) AI accelerators, exposing an OpenAI-compatible API server" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible HTTP API for model inference (completions, chat, models, health)" "Python / vLLM v0.16.0" "8000/TCP"
            hpuPlatform = container "HpuPlatform" "Platform plugin registering Intel Gaudi as a vLLM platform, configuring attention backends, compilation, and block sizes" "Python Plugin"
            hpuWorker = container "HPUWorker" "Manages HPU device lifecycle, memory profiling, KV-cache allocation, model loading, and inference execution" "Python Worker"
            hpuModelRunner = container "HPUModelRunner" "Executes model forward passes on HPU with graph compilation, bucketing, and profiling" "Python Model Runner"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Serving runtime that deploys and routes to inference containers" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh providing TLS termination, mTLS, and traffic management" "External"
        synapseAI = softwareSystem "Habana SynapseAI" "Intel Gaudi accelerator runtime, drivers, and graph compiler (v1.23.0)" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework (Habana fork v2.9.0 for HPU support)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        s3 = softwareSystem "S3 / PVC Storage" "Model artifact storage" "External"
        nixl = softwareSystem "NIXL" "Disaggregated KV-cache transfer library (UCX/RDMA)" "External"
        ray = softwareSystem "Ray" "Distributed computing framework for multi-device inference" "External"

        application -> vllmGaudi "Sends inference requests" "HTTP/8000 (via KServe ingress)"
        dataScientist -> kserve "Deploys InferenceService with vllm-gaudi runtime"
        kserve -> vllmGaudi "Deploys and routes to container" "HTTP/8000"
        vllmGaudi -> synapseAI "Uses for HPU hardware access" "PCIe / Device Driver"
        vllmGaudi -> pytorch "Uses for tensor computation" "In-process"
        vllmGaudi -> huggingface "Downloads model weights and tokenizers" "HTTPS/443"
        vllmGaudi -> s3 "Downloads model artifacts" "HTTPS/443"
        vllmGaudi -> nixl "Transfers KV-cache between instances" "UCX/RDMA"
        vllmGaudi -> ray "Coordinates distributed inference" "In-process"
        istio -> vllmGaudi "Provides TLS termination and mTLS sidecar"
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
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
