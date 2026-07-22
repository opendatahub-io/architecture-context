workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to deployed LLM models"

        vllmSpyre = softwareSystem "vllm-spyre" "IBM Spyre accelerator-optimized vLLM inference serving runtime for RHOAI" {
            tgisAdapter = container "vllm_tgis_adapter" "Entry module that wraps vLLM engine with TGIS gRPC + OpenAI HTTP APIs" "Python"
            vllmEngine = container "vLLM Engine" "High-throughput LLM inference engine with IBM Spyre accelerator support" "Python/C++"
            httpAPI = container "HTTP API" "OpenAI-compatible REST API on port 8000" "HTTP/8000"
            grpcAPI = container "gRPC API" "TGIS-compatible generation service on port 8033" "gRPC/8033"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar injected by platform operator" "Sidecar"
        kserve = softwareSystem "KServe" "Serverless ML inference platform managing ServingRuntime lifecycle" "Internal RHOAI"
        spyreHW = softwareSystem "IBM Spyre Accelerator" "AI hardware accelerator for inference computation" "Hardware"
        spyrePlugin = softwareSystem "IBM Spyre Device Plugin" "Kubernetes device plugin for Spyre accelerator allocation" "Internal"
        modelStorage = softwareSystem "Model Storage" "PVC or S3-backed storage for pre-downloaded model weights" "Internal"
        rhaiisBase = softwareSystem "RHAIIS Base Image" "Pre-built vLLM + Spyre runtime image (vllm-spyre-rhel9:3.2.2)" "Build Dependency"
        aipccBase = softwareSystem "AIPCC Spyre Base" "IBM Spyre accelerator base image from AI Platform Core Components" "Build Dependency"

        # Runtime relationships
        user -> kubeRbacProxy "Sends inference requests" "HTTPS/8443, Bearer Token"
        kubeRbacProxy -> vllmSpyre "Forwards pre-authenticated requests" "HTTP/8000, gRPC/8033 (localhost)"
        kserve -> vllmSpyre "Deploys and manages container lifecycle" "Kubernetes API"
        spyrePlugin -> spyreHW "Allocates accelerator devices to pods" "Device Plugin API"
        vllmSpyre -> spyreHW "Offloads inference computation" "Hardware Interface"
        modelStorage -> vllmSpyre "Provides model weight files" "Filesystem (Volume Mount)"

        # Internal container relationships
        tgisAdapter -> vllmEngine "Manages inference engine"
        tgisAdapter -> httpAPI "Serves OpenAI API"
        tgisAdapter -> grpcAPI "Serves TGIS API"
        vllmEngine -> spyreHW "Accelerated inference" "Spyre SDK"

        # Build-time relationships
        vllmSpyre -> rhaiisBase "Built FROM" "Container Image"
        rhaiisBase -> aipccBase "Built FROM" "Container Image"
    }

    views {
        systemContext vllmSpyre "SystemContext" {
            include *
            autoLayout
            description "System context showing vllm-spyre in the RHOAI inference ecosystem"
        }

        container vllmSpyre "Containers" {
            include *
            autoLayout
            description "Internal structure of the vllm-spyre inference runtime"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Sidecar" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #85bbf0
                color #ffffff
            }
            element "Hardware" {
                background #9b59b6
                color #ffffff
            }
            element "Build Dependency" {
                background #999999
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
