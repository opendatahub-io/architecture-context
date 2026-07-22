workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM models on Intel Gaudi hardware"

        vllmGaudi = softwareSystem "vllm-gaudi" "vLLM hardware plugin enabling high-performance LLM inference on Intel Gaudi (Habana) accelerators" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible HTTP API for model inference (completions, chat, embeddings)" "Python / vLLM 0.16.0" "8000/TCP"
            gaudiPlugin = container "vllm-gaudi Plugin" "HPU platform plugin: attention backends, model runner, workers, bucketing, quantization" "Python Plugin Package"
            hpuWorker = container "HPU Worker" "Executes inference graphs on Gaudi accelerators via SynapseAI" "Python / habana_frameworks"
        }

        kserve = softwareSystem "KServe" "Kubernetes serving runtime that manages vllm-gaudi container lifecycle" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Manages ServingRuntime CRs referencing vllm-gaudi image" "Internal RHOAI"
        gaudiHardware = softwareSystem "Intel Gaudi Accelerator" "Gaudi2/Gaudi3 HPU with SynapseAI 1.23.0 drivers" "Hardware"
        ray = softwareSystem "Ray" "Distributed execution framework for multi-HPU inference" "External"
        modelStorage = softwareSystem "Model Storage" "S3-compatible or PVC-based storage for model weights" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and tokenizer repository" "External"
        pytorch = softwareSystem "PyTorch (Habana Fork)" "Deep learning framework with HPU backend support" "External"

        user -> vllmGaudi "Sends inference requests via HTTP" "HTTPS/443 (via KServe ingress)"
        user -> kserve "Creates InferenceService / ServingRuntime via kubectl"
        kserve -> vllmGaudi "Manages container lifecycle, routes traffic" "HTTP/8000"
        rhoaiOperator -> kserve "Configures ServingRuntime CRs"
        vllmGaudi -> gaudiHardware "Executes compiled graphs" "PCIe / HPU API"
        vllmGaudi -> ray "Coordinates multi-HPU distributed inference" "Ray protocol/6379"
        vllmGaudi -> modelStorage "Downloads model weights at startup" "HTTPS/443 or PVC mount"
        vllmGaudi -> huggingface "Downloads models and tokenizers" "HTTPS/443"
        vllmGaudi -> pytorch "Uses for tensor operations with HPU backend" "In-process"
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
                background #438DD5
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
            element "Hardware" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
