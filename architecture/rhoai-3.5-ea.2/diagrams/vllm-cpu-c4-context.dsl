workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Deploys and queries LLM models for inference"

        vllmCpu = softwareSystem "vllm-cpu" "CPU-only LLM inference server providing OpenAI-compatible API" {
            apiServer = container "HTTP API Server" "OpenAI-compatible REST API for chat completions, embeddings, scoring, tokenization" "FastAPI + Uvicorn, Port 8000/TCP"
            authMiddleware = container "Auth Middleware" "Optional API key authentication for /v1/* endpoints" "FastAPI AuthenticationMiddleware"
            inferenceEngine = container "vLLM Inference Engine" "High-throughput LLM inference with CPU-optimized kernels" "Python + C++ Extensions, PyTorch CPU"
            grpcServer = container "gRPC Server" "Alternative inference interface (optional)" "smg-grpc-servicer, Port 50051/TCP"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Manages ServingRuntime containers and inference routing" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        modelStorage = softwareSystem "Model Storage" "Persistent model weight storage (PVC or S3)" "Internal"
        gatewayAPI = softwareSystem "Gateway API / Envoy" "Ingress traffic routing and TLS termination" "Internal RHOAI"

        # External relationships
        user -> gatewayAPI "Sends inference requests" "HTTPS/443"
        gatewayAPI -> vllmCpu "Routes to inference pod" "HTTP/8000"
        kserve -> vllmCpu "Manages as ServingRuntime container"
        prometheus -> vllmCpu "Scrapes /metrics endpoint" "HTTP/8000"

        # Internal container relationships
        apiServer -> authMiddleware "Validates API key"
        authMiddleware -> inferenceEngine "Forwards authorized requests"
        grpcServer -> inferenceEngine "Forwards gRPC requests"

        # Egress relationships
        inferenceEngine -> modelStorage "Reads model weights" "Filesystem I/O"
        inferenceEngine -> huggingfaceHub "Downloads model artifacts (when online)" "HTTPS/443, HF_TOKEN Bearer"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
            description "vllm-cpu system context showing external dependencies and platform integration"
        }

        container vllmCpu "Containers" {
            include *
            autoLayout
            description "Internal structure of the vllm-cpu inference server"
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
            element "Internal" {
                background #85bbf0
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
