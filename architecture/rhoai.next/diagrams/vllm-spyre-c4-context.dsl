workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to deployed LLM models"

        vllmSpyre = softwareSystem "vLLM Spyre" "IBM Spyre-accelerated vLLM inference runtime with TGIS gRPC adapter for high-performance LLM inference on RHEL 9" {
            tgisAdapter = container "vllm_tgis_adapter" "Python entrypoint bridging vLLM with gRPC TGIS protocol and OpenAI-compatible HTTP API" "Python"
            httpApi = container "HTTP API Server" "OpenAI-compatible REST API for text/chat completions" "uvicorn, Port 8000/TCP"
            grpcApi = container "gRPC TGIS Server" "IBM Text Generation Inference Server protocol endpoint" "gRPC, Port 8033/TCP"
            vllmEngine = container "vLLM Inference Engine" "Core inference engine with IBM Spyre hardware acceleration" "Python/C++"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform managing InferenceService lifecycle" "Internal RHOAI"
        servingRuntime = softwareSystem "ServingRuntime CR" "Custom resource defining model serving runtime configuration" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator managing ServingRuntime lifecycle and image versions" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "kube-rbac-proxy / Gateway API / OAuth proxy providing AuthN/AuthZ" "Internal RHOAI"

        spyreHW = softwareSystem "IBM Spyre Accelerator" "Hardware AI accelerator card for inference workloads" "External Hardware"
        s3Storage = softwareSystem "S3 Storage" "Object storage for model weights and artifacts" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model repository for downloading weights and tokenizers" "External"
        rhaiisBase = softwareSystem "RHAIIS Base Image" "Pre-built base image containing vLLM, Spyre drivers, TGIS adapter on UBI9" "External - Red Hat"

        # User interactions
        user -> platformIngress "Sends inference requests" "HTTPS/443, TLS, Bearer Token / OAuth"
        platformIngress -> vllmSpyre "Forwards authenticated requests" "HTTP/8000, gRPC/8033, Plaintext in-cluster"

        # Internal container interactions
        tgisAdapter -> httpApi "Serves HTTP requests"
        tgisAdapter -> grpcApi "Serves gRPC requests"
        httpApi -> vllmEngine "Processes inference"
        grpcApi -> vllmEngine "Processes inference"

        # External dependencies
        vllmEngine -> spyreHW "Executes inference" "Hardware interface (PCIe)"
        vllmEngine -> s3Storage "Downloads model weights at startup" "HTTPS/443, TLS 1.2+, AWS IAM"
        vllmEngine -> huggingFace "Downloads models/tokenizers" "HTTPS/443, TLS 1.2+, Bearer Token"

        # Platform management
        rhodsOperator -> servingRuntime "Manages lifecycle"
        servingRuntime -> vllmSpyre "References container image"
        kserve -> vllmSpyre "Deploys as InferenceService runtime"

        # Base image
        rhaiisBase -> vllmSpyre "Provides base layer" "Container image inheritance"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Hardware" {
                background #e74c3c
                color #ffffff
            }
            element "External - Red Hat" {
                background #cc0000
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba3f5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
