workspace {
    model {
        user = person "Data Scientist / Application" "Sends LLM inference requests via OpenAI API or TGIS gRPC"

        vllm = softwareSystem "vLLM CUDA (RHOAI)" "GPU-accelerated LLM inference serving with dual-protocol support (OpenAI HTTP + TGIS gRPC)" {
            krbpSidecar = container "kube-rbac-proxy" "Authentication and authorization enforcement sidecar" "Go Service" "Auth Proxy"
            vllmContainer = container "vLLM Container" "vllm_tgis_adapter entrypoint - serves OpenAI API (8000) and TGIS gRPC (8033)" "Python (from RHAIIS base image)"
            nvidiaGpu = container "NVIDIA GPU" "CUDA 12.x+ - executes model inference" "Hardware" "GPU"
        }

        kserve = softwareSystem "KServe" "Deploys and manages InferenceService pods with model serving containers" "Internal RHOAI"
        kserveServingRuntime = softwareSystem "KServe ServingRuntime" "Defines container args, resource limits, and model format support" "Internal RHOAI"
        gatewayApi = softwareSystem "Gateway API (HTTPRoute)" "External ingress with TLS termination managed by platform operator" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Internal RHOAI"

        huggingface = softwareSystem "HuggingFace Hub" "Public model repository for downloading pre-trained model weights" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model weights (S3, MinIO)" "External"
        pvcStorage = softwareSystem "PVC Volume" "Persistent volume for pre-loaded model weights" "External"
        rhaiisBaseImage = softwareSystem "RHAIIS vllm-cuda-rhel9" "Base container image providing vLLM runtime, CUDA drivers, Python deps, TGIS adapter" "External - Red Hat"

        # Relationships
        user -> gatewayApi "Sends inference requests" "HTTPS/443 (TLS 1.2+, JWT)"
        gatewayApi -> krbpSidecar "Routes to inference pod" "HTTPS/8443 (TLS 1.2+)"
        krbpSidecar -> vllmContainer "Forwards pre-authenticated requests" "HTTP/8000, gRPC/8033 (plaintext localhost)"
        vllmContainer -> nvidiaGpu "Executes model inference" "CUDA API"

        kserve -> vllm "Deploys InferenceService pod"
        kserveServingRuntime -> vllm "Configures container runtime"

        vllmContainer -> huggingface "Downloads model weights (optional)" "HTTPS/443 (Bearer HF_TOKEN)"
        vllmContainer -> s3Storage "Downloads model weights" "HTTPS/443 (AWS IAM / HMAC)"
        vllmContainer -> pvcStorage "Mounts model weights" "Filesystem"
        rhaiisBaseImage -> vllmContainer "Provides base runtime" "Container Image Layer"

        prometheus -> vllmContainer "Scrapes metrics" "HTTP/8000 (/metrics)"
    }

    views {
        systemContext vllm "SystemContext" {
            include *
            autoLayout
        }

        container vllm "Containers" {
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
            element "External - Red Hat" {
                background #cc0000
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
            element "Auth Proxy" {
                background #e8a838
                color #ffffff
            }
            element "GPU" {
                background #76b900
                color #ffffff
            }
        }
    }
}
