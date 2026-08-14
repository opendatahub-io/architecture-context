workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to deployed models"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi HPU-optimized vLLM inference server providing OpenAI-compatible API" {
            apiServer = container "vLLM API Server" "OpenAI-compatible HTTP API server for completions, chat, embeddings, and model management" "Python (vLLM v0.16.0)"
            gaudiPlugin = container "vllm_gaudi Plugin" "HpuPlatform OOT plugin providing HPU-optimized attention, MoE, quantization, LoRA, rotary embeddings, and KV cache operations" "Python"
            synapseRuntime = container "SynapseAI Runtime" "Habana SynapseAI 1.23.0 providing HPU kernel execution and device management" "System Library (C++)"
        }

        kserve = softwareSystem "KServe" "Deploys and manages the vllm-gaudi container as a ServingRuntime, handling service creation, routing, and scaling" "RHOAI Platform"
        ray = softwareSystem "Ray" "Distributed compute framework for multi-HPU worker orchestration" "External"
        hfTransformers = softwareSystem "Hugging Face Transformers" "Tokenizer and model weight loading library" "External"
        modelStorage = softwareSystem "Model Storage" "PVC or S3-compatible store for model weights and tokenizer files" "External"
        serviceMesh = softwareSystem "Service Mesh" "Istio/OSSM providing mTLS, traffic management, and authorization policies" "RHOAI Platform"
        gaudiHardware = softwareSystem "Intel Gaudi HPU" "Hardware accelerator providing high-performance matrix operations for LLM inference" "Hardware"

        user -> vllmGaudi "Sends inference requests" "HTTPS/443 (via platform)"
        kserve -> vllmGaudi "Deploys and manages" "Kubernetes API"
        vllmGaudi -> modelStorage "Loads model weights" "Filesystem (PVC) or HTTPS/443 (S3)"
        vllmGaudi -> ray "Orchestrates distributed workers" "gRPC (Ray internal)"
        vllmGaudi -> gaudiHardware "Executes inference kernels" "SynapseAI / HCCL"
        vllmGaudi -> hfTransformers "Loads tokenizers and configs" "Python API"
        serviceMesh -> vllmGaudi "Provides mTLS and auth" "Sidecar injection"

        apiServer -> gaudiPlugin "Delegates device ops" "Python API"
        gaudiPlugin -> synapseRuntime "Dispatches HPU kernels" "habana_frameworks.torch"
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
            element "RHOAI Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Hardware" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
