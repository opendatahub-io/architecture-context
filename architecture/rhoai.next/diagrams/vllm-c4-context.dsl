workspace {
    model {
        user = person "Data Scientist / Application" "Sends inference requests to deployed LLM models"

        vllm = softwareSystem "vLLM CUDA" "GPU-accelerated LLM inference server with dual-protocol serving (OpenAI HTTP + TGIS gRPC)" {
            tgisAdapter = container "vllm_tgis_adapter" "Entry point providing TGIS-compatible gRPC interface on port 8033" "Python"
            httpServer = container "vLLM HTTP Server" "OpenAI-compatible REST API on port 8000 (/v1/completions, /v1/chat/completions)" "Python"
            engine = container "vLLM Inference Engine" "High-performance LLM inference with CUDA GPU acceleration" "Python/C++"
        }

        kserve = softwareSystem "KServe" "Deploys and manages InferenceService pods running vLLM image" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar handling TLS termination and authn" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "External ingress for inference traffic via HTTPRoute" "Internal RHOAI"
        s3 = softwareSystem "S3 / Object Storage" "Model weight artifact storage" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Optional model and tokenizer downloads" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        gpu = softwareSystem "NVIDIA GPU" "CUDA-capable GPU hardware for tensor computation" "Infrastructure"

        user -> rhoaiGateway "Sends inference requests" "HTTPS/443, TLS 1.2+, Bearer Token"
        rhoaiGateway -> kubeRbacProxy "Forwards authenticated requests" "HTTPS/8443"
        kubeRbacProxy -> httpServer "Proxies HTTP inference requests" "HTTP/8000 (localhost)"
        kubeRbacProxy -> tgisAdapter "Proxies gRPC inference requests" "gRPC/8033 (localhost)"
        tgisAdapter -> engine "Delegates inference" "in-process Python"
        httpServer -> engine "Delegates inference" "in-process Python"
        engine -> gpu "Executes CUDA kernels" "CUDA"
        engine -> s3 "Downloads model weights at startup" "HTTPS/443, IAM auth"
        engine -> hfHub "Downloads model/tokenizer (optional)" "HTTPS/443, Bearer Token"
        prometheus -> httpServer "Scrapes metrics" "HTTP/8000"
        kserve -> vllm "Manages lifecycle via ServingRuntime/InferenceService CRs"
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
            element "Infrastructure" {
                background #76b900
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
        }
    }
}
