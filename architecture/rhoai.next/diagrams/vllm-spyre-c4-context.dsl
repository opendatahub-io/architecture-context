workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models for inference"
        platformAdmin = person "Platform Admin" "Configures KServe ServingRuntimes and model serving"

        vllmSpyre = softwareSystem "vllm-spyre" "IBM Spyre-accelerated vLLM inference server with TGIS gRPC adapter for RHOAI model serving" {
            tgisAdapter = container "vllm-tgis-adapter" "Bridges vLLM OpenAI API to TGIS gRPC protocol; serves HTTP (8000) and gRPC (8033)" "Python"
            vllmEngine = container "vLLM Engine" "High-throughput LLM inference engine with Spyre plugin" "Python/C++"
            spyrePlugin = container "vllm-spyre Plugin" "IBM Spyre accelerator integration for vLLM" "Python"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication and authorization sidecar proxy" "Platform-Injected"
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform managing InferenceService lifecycle" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving infrastructure for KServe" "Internal RHOAI"
        spyreHardware = softwareSystem "IBM Spyre Accelerator" "AI inference accelerator hardware (VFIO passthrough)" "Hardware"
        modelStorage = softwareSystem "Model Storage" "Pre-downloaded HuggingFace model weights (PVC)" "Storage"
        baseImage = softwareSystem "rhaiis/vllm-spyre-rhel9" "Pre-built base image with all runtime components" "External"
        konflux = softwareSystem "Konflux Pipeline" "Build system for supply chain provenance attestation" "Build Infrastructure"

        dataScientist -> vllmSpyre "Sends inference requests via HTTPS/8443"
        platformAdmin -> kserve "Configures ServingRuntime CRs"

        kubeRbacProxy -> tgisAdapter "Forwards authenticated requests (HTTP/8000, gRPC/8033)" "HTTP/gRPC localhost"
        tgisAdapter -> vllmEngine "In-process Python calls" "Python"
        vllmEngine -> spyrePlugin "Dispatches to accelerator plugin" "Python"
        spyrePlugin -> spyreHardware "Model inference computation" "VFIO passthrough"

        kserve -> vllmSpyre "Deploys as ServingRuntime container"
        modelMesh -> vllmSpyre "Routes inference requests via gRPC/TGIS"
        modelStorage -> vllmEngine "Model weights mounted as volume" "Filesystem"
        baseImage -> konflux "Source base image for rebuild" "Container Registry"
        konflux -> vllmSpyre "Produces attested container image" "Container Image"
    }

    views {
        systemContext vllmSpyre "SystemContext" {
            include *
            autoLayout
        }

        container vllmSpyre "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Platform-Injected" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Hardware" {
                background #e74c3c
                color #ffffff
            }
            element "Storage" {
                background #f5a623
                color #333333
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Build Infrastructure" {
                background #999999
                color #ffffff
            }
        }
    }
}
