workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM models via InferenceService"
        mlops = person "MLOps Engineer" "Configures ServingRuntimes and manages model deployments"

        vllm = softwareSystem "vLLM CUDA" "GPU-accelerated LLM inference server with dual-protocol serving (OpenAI HTTP + TGIS gRPC)" {
            httpServer = container "vLLM HTTP Server" "OpenAI-compatible REST API for chat/text completions" "Python/vLLM" "Port 8000/TCP"
            tgisAdapter = container "vllm_tgis_adapter" "TGIS-compatible gRPC adapter wrapping vLLM engine" "Python" "Port 8033/TCP"
            inferenceEngine = container "vLLM Inference Engine" "High-performance LLM inference with PagedAttention" "Python/C++"
            cudaRuntime = container "CUDA Runtime" "NVIDIA GPU compute layer" "CUDA"
        }

        kserve = softwareSystem "KServe" "Model serving orchestration - deploys InferenceService pods" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "External ingress gateway with TLS termination and routing" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar proxy" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        s3 = softwareSystem "S3 / Object Storage" "Model weight artifact storage" "External"
        huggingface = softwareSystem "Hugging Face Hub" "Public model and tokenizer repository" "External"
        kubeAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"

        # User interactions
        datascientist -> rhoaiGateway "Sends inference requests" "HTTPS/443 TLS 1.2+"
        mlops -> kserve "Creates InferenceService/ServingRuntime CRs" "kubectl/HTTPS"

        # Platform → vLLM
        rhoaiGateway -> kubeRbacProxy "Routes inference traffic" "HTTPS/8443 TLS"
        kubeRbacProxy -> vllm "Forwards authenticated requests" "HTTP/8000, gRPC/8033 (localhost)"
        kserve -> vllm "Deploys and manages pods" "Kubernetes API"
        prometheus -> vllm "Scrapes inference metrics" "HTTP/8000"

        # vLLM internal
        httpServer -> inferenceEngine "Processes HTTP inference requests" "In-process"
        tgisAdapter -> inferenceEngine "Processes gRPC inference requests" "In-process Python"
        inferenceEngine -> cudaRuntime "Executes model computation" "CUDA API"

        # vLLM → External
        vllm -> s3 "Downloads model weights at startup" "HTTPS/443 TLS 1.2+ AWS IAM"
        vllm -> huggingface "Downloads models/tokenizers (optional)" "HTTPS/443 TLS 1.2+"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
