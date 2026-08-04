workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to deployed models"

        vllmGaudi = softwareSystem "vllm-gaudi" "Intel Gaudi (HPU) plugin for vLLM providing OpenAI-compatible LLM inference on Habana Gaudi accelerators" {
            apiServer = container "vLLM API Server" "OpenAI-compatible HTTP API server (port 8000)" "Python (upstream vLLM v0.16.0)"
            plugin = container "vllm_gaudi Plugin" "HPU device backend: workers, model runner, memory manager, scheduler, speculative decoding" "Python Plugin"
            synapseRuntime = container "SynapseAI Runtime" "Intel Habana device drivers and graph compiler" "Native Libraries"
            pytorchGaudi = container "PyTorch for Gaudi" "Deep learning framework with HPU accelerator support" "Python/C++"
        }

        kserve = softwareSystem "KServe" "Serverless model serving platform managing ServingRuntime lifecycle" "RHOAI Platform"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh providing mTLS, traffic management, and ingress" "External"
        modelStorage = softwareSystem "Model Storage" "S3, PVC, or other storage for model weight artifacts" "External"
        gaudiHardware = softwareSystem "Intel Gaudi Accelerator" "Habana Gaudi HPU hardware for inference execution" "Hardware"
        konflux = softwareSystem "Konflux Build Pipeline" "CI/CD pipeline producing container images" "Build Infrastructure"
        habanaRepo = softwareSystem "Intel Habana Artifact Repositories" "SynapseAI drivers and PyTorch for Gaudi packages" "External"

        // Runtime relationships
        user -> kserve "Sends inference requests" "HTTP/HTTPS"
        kserve -> vllmGaudi "Routes inference requests to container" "HTTP/8000"
        apiServer -> plugin "Delegates HPU inference execution"
        plugin -> pytorchGaudi "Executes model forward passes"
        pytorchGaudi -> synapseRuntime "Compiles and runs HPU graphs"
        synapseRuntime -> gaudiHardware "Drives accelerator hardware" "PCIe/Device Driver"
        apiServer -> modelStorage "Loads model weights at startup" "HTTPS/Filesystem"

        // Build-time relationships
        konflux -> vllmGaudi "Builds container image" "Dockerfile.konflux.gaudi"
        konflux -> habanaRepo "Fetches SynapseAI drivers and PyTorch" "HTTPS"
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
            element "RHOAI Platform" {
                background #7ed321
                color #ffffff
            }
            element "Hardware" {
                background #4a90e2
                color #ffffff
            }
            element "Build Infrastructure" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
