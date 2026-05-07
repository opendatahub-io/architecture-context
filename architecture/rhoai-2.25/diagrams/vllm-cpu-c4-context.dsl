workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for inference"
        mlEngineer = person "ML Engineer" "Configures model serving runtimes and monitors performance"

        vllmCpu = softwareSystem "vllm-cpu" "CPU-only LLM inference server providing OpenAI-compatible REST and TGIS gRPC APIs for Red Hat OpenShift AI" {
            openaiServer = container "vllm-openai" "OpenAI-compatible HTTP API server for LLM inference (chat, completions, embeddings, scoring, reranking)" "Python (FastAPI + Uvicorn)" "Service"
            grpcAdapter = container "vllm-grpc-adapter" "TGIS-compatible gRPC adapter wrapping vLLM engine for KServe integration" "Python (vllm-tgis-adapter)" "Service"
            vllmEngine = container "vLLM Engine" "Core inference engine with PagedAttention, continuous batching, async execution (V0/V1)" "Python Library"
            cpuKernels = container "C/C++ CPU Kernels" "CPU-optimized attention, cache, layernorm, quantization, and MoE kernels" "C/C++ (CMake)" "Library"

            openaiServer -> vllmEngine "Inference requests" "In-process async"
            grpcAdapter -> vllmEngine "Inference requests" "In-process"
            vllmEngine -> cpuKernels "Model execution" "Native extension calls"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform that manages ServingRuntime and InferenceService CRs" "Internal RHOAI"
        rhoaiModelServing = softwareSystem "RHOAI Model Serving" "Model serving stack referencing vllm-cpu container image in ServingRuntime CRs" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model weights and tokenizer repository" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Optional model artifact storage (AWS S3, MinIO, etc.)" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Internal Platform"
        pytorch = softwareSystem "PyTorch" "Deep learning framework for CPU inference (2.6.0+cpu / 2.7.0)" "External"
        ipex = softwareSystem "Intel Extension for PyTorch" "CPU-optimized inference acceleration on x86_64" "External"

        # User interactions
        dataScientist -> vllmCpu "Sends inference requests (chat, completions, embeddings)" "HTTPS/443 via KServe Route"
        mlEngineer -> kserve "Creates InferenceService CRs referencing vllm-cpu" "kubectl / RHOAI Dashboard"

        # System interactions
        kserve -> vllmCpu "Deploys as ServingRuntime container; routes inference traffic" "HTTP/8000, gRPC/8033"
        rhoaiModelServing -> vllmCpu "References container image in ServingRuntime/ClusterServingRuntime CRs"
        vllmCpu -> huggingfaceHub "Downloads model weights and tokenizer at startup" "HTTPS/443, Bearer Token"
        vllmCpu -> s3Storage "Downloads model artifacts (optional)" "HTTPS/443, AWS IAM"
        prometheus -> vllmCpu "Scrapes metrics" "HTTP/8000 GET /metrics"
        vllmCpu -> pytorch "CPU model inference" "In-process"
        vllmCpu -> ipex "Intel CPU acceleration (x86_64)" "In-process"
    }

    views {
        systemContext vllmCpu "SystemContext" {
            include *
            autoLayout
        }

        container vllmCpu "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #50b8e7
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Service" {
                shape RoundedBox
            }
            element "Library" {
                shape Hexagon
            }
        }
    }
}
