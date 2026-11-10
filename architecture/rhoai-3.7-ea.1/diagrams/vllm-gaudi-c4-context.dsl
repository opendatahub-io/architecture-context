workspace {
    model {
        user = person "Data Scientist / API Client" "Sends OpenAI-compatible inference requests"

        vllmGaudi = softwareSystem "vllm-gaudi (odh-vllm-gaudi-rhel9)" "vLLM OpenAI-compatible inference server with the Intel Gaudi (HPU) platform plugin" {
            apiServer = container "vLLM OpenAI API Server" "Upstream vLLM v0.16.0 server; /v1/* inference, /health, /metrics on 8000/TCP" "Python / uvicorn"
            engine = container "vLLM Engine" "Scheduling and model execution (upstream vLLM)" "Python"
            plugin = container "vllm_gaudi Plugin" "HpuPlatform, HPU attention backends, fused MoE, quantization, LoRA, Mamba ops" "Python vLLM platform plugin"
            kvTransfer = container "HPU NIXL KV Connector" "KV-cache transfer for disaggregated prefill/decode (optional)" "Python / NIXL"
            kvOffload = container "CPU-HPU KV Offload" "Offloads KV cache between CPU and HPU" "Python"
            habana = container "Habana PyTorch + Synapse" "PyTorch 2.9.0 HPU backend, Gaudi SW 1.23.0-695" "Vendor libraries"
        }

        kserve = softwareSystem "KServe" "Deploys the image as a ServingRuntime for InferenceServices" "Internal RHOAI"
        templates = softwareSystem "odh-model-controller / odh-dashboard" "Provide ServingRuntime templates for the Gaudi vLLM runtime" "Internal RHOAI"
        devicePlugin = softwareSystem "Intel Gaudi Device Plugin / Habana Operator" "Provides habana.ai/gaudi HPU devices to pods" "External"
        storage = softwareSystem "Model Storage" "S3 / Hugging Face Hub / PVC holding model weights" "External"
        nixlPeer = softwareSystem "Peer vLLM Gaudi Instance" "Prefill or decode instance in disaggregated serving" "External"
        upstream = softwareSystem "Upstream Sources" "github.com, vault.habana.ai, pypi.org, CentOS Stream, EPEL (build time)" "External"

        user -> apiServer "Inference requests" "HTTP/8000, no TLS or auth by default"
        apiServer -> engine "Submits requests"
        engine -> plugin "Loads via vllm.platform_plugins entry point"
        plugin -> habana "Runs kernels on HPU"
        kvOffload -> habana "Moves KV blocks"
        plugin -> kvTransfer "Registers connectors"
        kvTransfer -> nixlPeer "KV-cache transfer" "NIXL/UCX, deployment-defined port, no auth"
        engine -> storage "Downloads model weights" "HTTPS/443"
        kserve -> vllmGaudi "Deploys as ServingRuntime container"
        templates -> kserve "Supply ServingRuntime templates"
        devicePlugin -> habana "Allocates Gaudi HPUs"
        upstream -> vllmGaudi "Image build sources (non-hermetic)" "HTTPS/443"
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
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
