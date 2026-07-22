workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Deploys and queries ML models for inference"
        application = person "Application Client" "Sends inference requests via HTTP or gRPC APIs"

        vllm = softwareSystem "vLLM CUDA Inference Server" "GPU-accelerated LLM inference server with TGIS adapter for NVIDIA CUDA hardware" {
            tgisAdapter = container "vllm_tgis_adapter" "Entrypoint process that bridges TGIS gRPC protocol to vLLM engine and exposes OpenAI-compatible HTTP API" "Python"
            vllmEngine = container "vLLM Engine" "Core inference engine with continuous batching, PagedAttention, and CUDA kernel execution" "Python/C++/CUDA"
            httpApi = container "OpenAI-Compatible HTTP API" "REST API serving completions, chat, embeddings, and model listing" "HTTP/8000"
            grpcApi = container "TGIS gRPC API" "gRPC service for backward compatibility with IBM TGIS clients" "gRPC/8033"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving framework that manages ServingRuntime and InferenceService CRs" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Auth enforcement sidecar injected by platform operator (RHOAI 3.x)" "Internal RHOAI"
        rhaiisBase = softwareSystem "RHAIIS Base Image" "Red Hat AI Inference Server base image providing vLLM runtime, Python deps, CUDA libs, and TGIS adapter" "Internal Red Hat"
        konflux = softwareSystem "Konflux Build Pipeline" "Tekton-based CI/CD pipeline for building and validating container images" "Internal Red Hat"

        huggingface = softwareSystem "HuggingFace Hub" "Public model repository for downloading model weights" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for model weights and artifacts" "External"
        nvidiaGpu = softwareSystem "NVIDIA GPU" "CUDA-capable GPU hardware for tensor computation" "External Hardware"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        # User interactions
        datascientist -> kserve "Creates InferenceService CR via kubectl/dashboard"
        application -> kubeRbacProxy "Sends inference requests" "HTTPS/8443"

        # Auth enforcement
        kubeRbacProxy -> vllm "Proxies authenticated requests" "HTTP/8000, gRPC/8033"

        # KServe orchestration
        kserve -> vllm "Deploys and manages vLLM pods via ServingRuntime CR"

        # Internal container relationships
        tgisAdapter -> vllmEngine "Bridges TGIS protocol to vLLM"
        tgisAdapter -> httpApi "Serves HTTP API"
        tgisAdapter -> grpcApi "Serves gRPC API"
        vllmEngine -> nvidiaGpu "Executes inference" "CUDA API"

        # Egress
        vllm -> huggingface "Downloads model weights at startup" "HTTPS/443"
        vllm -> s3 "Downloads model weights (alternative)" "HTTPS/443"

        # Build supply chain
        rhaiisBase -> vllm "Provides base image with all runtime dependencies"
        konflux -> vllm "Builds final container image" "Tekton PipelineRun"

        # Monitoring
        prometheus -> vllm "Scrapes runtime metrics" "HTTP/8000 GET /metrics"
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
            element "External Hardware" {
                background #9b59b6
                color #ffffff
            }
            element "Internal RHOAI" {
                background #f5a623
                color #ffffff
            }
            element "Internal Red Hat" {
                background #d35400
                color #ffffff
            }
            element "Internal Platform" {
                background #3498db
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
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
