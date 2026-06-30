workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys LLM-based applications, sends inference requests"
        mlEngineer = person "ML Engineer" "Deploys and configures model-serving runtimes on RHOAI"

        vllmCpu = softwareSystem "vLLM CPU" "CPU-optimized LLM inference serving runtime providing OpenAI-compatible APIs" {
            openaiServer = container "vLLM OpenAI API Server" "OpenAI-compatible HTTP API with chat completion, embeddings, scoring, and multimodal endpoints" "Python (FastAPI/uvicorn)" "Port 8000/TCP"
            grpcServer = container "vLLM gRPC Server" "gRPC inference interface with health checking and reflection" "Python (grpcio)" "Port 50051/TCP"
            engineV1 = container "vLLM Engine v1" "Core async inference engine with scheduler, KV cache management, continuous batching, and PagedAttention" "Python"
            cppExtensions = container "C++ Extensions" "CPU-optimized attention kernels and custom ops compiled via CMake" "C++ (CMake)"
            zmqIpc = container "ZeroMQ IPC" "Inter-process communication between API frontend and engine backend" "pyzmq"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Kubernetes-native model serving platform that manages vLLM pod lifecycle, autoscaling, and ingress" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Platform Gateway" "Platform ingress gateway with kube-rbac-proxy for authentication" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection and export" "Internal RHOAI"

        hfHub = softwareSystem "HuggingFace Hub" "Model weight and tokenizer repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts" "External"
        pytorchHub = softwareSystem "PyTorch Model Hub" "Pre-trained model repository" "External"
        mcpServers = softwareSystem "MCP Tool Servers" "External tool servers for Model Context Protocol" "External"

        # User relationships
        dataScientist -> rhoaiGateway "Sends inference requests via" "HTTPS/443"
        mlEngineer -> kserve "Deploys InferenceService via" "kubectl"

        # Platform → vLLM
        rhoaiGateway -> vllmCpu "Routes inference traffic to" "HTTPS/8443 → HTTP/8000"
        kserve -> vllmCpu "Manages pod lifecycle, autoscaling"
        prometheus -> vllmCpu "Scrapes /metrics" "HTTP/8000"

        # vLLM internal
        openaiServer -> zmqIpc "Dispatches requests via" "ZeroMQ IPC"
        grpcServer -> zmqIpc "Dispatches requests via" "ZeroMQ IPC"
        zmqIpc -> engineV1 "Delivers to scheduler"
        engineV1 -> cppExtensions "Invokes CPU-optimized kernels"

        # vLLM → External
        vllmCpu -> hfHub "Downloads model weights and tokenizers" "HTTPS/443, Bearer HF_TOKEN"
        vllmCpu -> s3Storage "Loads model artifacts" "HTTPS/443, AWS credentials"
        vllmCpu -> pytorchHub "Downloads pre-trained models" "HTTPS/443"
        vllmCpu -> otelCollector "Exports distributed traces" "OTLP gRPC/4317"
        vllmCpu -> mcpServers "Invokes external tools" "HTTP SSE"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
            description "vLLM CPU system context showing integration with RHOAI platform and external services"
        }

        container vllmCpu "Containers" {
            include *
            autoLayout
            description "vLLM CPU internal container structure showing API servers, engine, and IPC"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
