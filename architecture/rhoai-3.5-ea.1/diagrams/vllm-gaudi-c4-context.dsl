workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models on Intel Gaudi hardware"

        vllmGaudi = softwareSystem "vllm-gaudi" "HPU plugin for vLLM enabling high-performance LLM inference on Intel Gaudi accelerators" {
            apiServer = container "vLLM OpenAI API Server" "OpenAI-compatible inference API server (upstream vLLM)" "Python Service" "Port 8000/TCP"
            gaudiPlugin = container "vllm-gaudi Plugin" "HPU platform registration, attention backends, quantization, model overrides, distributed inference" "Python Package (vLLM plugin)"
            synapseRuntime = container "Habana Synapse AI Runtime" "Gaudi driver stack, graph compiler, and runtime libraries" "System Libraries" "v1.23.0"
            pytorchHPU = container "PyTorch + Habana Extensions" "Deep learning framework with HPU device support, FusedSDPA kernels, graph compilation" "Python Library" "v2.9.0"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication and authorization sidecar proxy injected by platform operator" "Platform Sidecar"
        kserve = softwareSystem "KServe" "Model serving controller that deploys ServingRuntime pods" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage" "Persistent storage for model weights (PVC, S3, or Hugging Face Hub)" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Public model repository for downloading model weights" "External"
        ray = softwareSystem "Ray" "Distributed computing framework for multi-worker inference orchestration" "External"
        gaudiHW = softwareSystem "Intel Gaudi Hardware" "Gaudi 2 or Gaudi 3 HPU accelerator cards" "Hardware"

        # Relationships
        datascientist -> kubeRbacProxy "Sends inference requests" "HTTPS/8443, Bearer Token"
        kubeRbacProxy -> vllmGaudi "Proxies authenticated requests" "HTTP/8000, localhost"
        kserve -> vllmGaudi "Deploys as ServingRuntime container" "Container Image"
        vllmGaudi -> modelStorage "Loads model weights" "HTTPS/443 or filesystem"
        vllmGaudi -> hfHub "Downloads model weights" "HTTPS/443, HF Token"
        vllmGaudi -> ray "Orchestrates distributed workers" "Ray protocol"
        vllmGaudi -> gaudiHW "Executes inference on accelerator" "In-process, HCCL fabric"

        # Internal container relationships
        apiServer -> gaudiPlugin "Loads at startup via entry_points" "In-process"
        gaudiPlugin -> pytorchHPU "HPU device operations, graph compilation" "In-process"
        gaudiPlugin -> synapseRuntime "Kernel execution, device management" "In-process"
        pytorchHPU -> synapseRuntime "Device backend" "Shared libraries"
    }

    views {
        systemContext vllmGaudi "SystemContext" {
            include *
            autoLayout
            description "System context for vllm-gaudi showing external actors and systems"
        }

        container vllmGaudi "Containers" {
            include *
            autoLayout
            description "Internal container structure of vllm-gaudi"
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
            element "Platform Sidecar" {
                background #9b59b6
                color #ffffff
            }
            element "Hardware" {
                background #34495e
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
        }
    }
}
