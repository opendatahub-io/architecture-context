workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys AI models and sends inference requests via REST/gRPC"
        sre = person "SRE / Platform Admin" "Monitors inference performance and manages deployments"

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "High-performance AI model inference server supporting KServe v2, TFS, OpenAI-compatible, and Cohere-compatible APIs" {
            restServer = container "REST Server" "HTTP/REST API server exposing KServe v2, TFS, OpenAI, Cohere endpoints" "C++ / Drogon Framework"
            grpcServer = container "gRPC Server" "gRPC API server for TFS and KServe v2 inference protocols" "C++ / gRPC"
            modelManager = container "Model Manager" "Manages model lifecycle: loading, versioning, hot-reload" "C++ Singleton"
            mediaPipeEngine = container "MediaPipe Graph Engine" "Graph-based processing for LLM, embeddings, rerank, audio, image gen" "C++ / MediaPipe"
            dagScheduler = container "DAG Pipeline Scheduler" "Multi-model chaining with custom compute nodes" "C++ Framework"
            openvinoRuntime = container "OpenVINO Runtime" "AI model compilation and inference on CPU/GPU/NPU" "C++ Library (2026.1)"
            openvinoGenAI = container "OpenVINO GenAI" "LLM pipelines with continuous batching, speculative decoding" "C++ Library (2026.1)"
            openvinoTokenizers = container "OpenVINO Tokenizers" "Tokenization for LLM and embedding models" "C++ Library (2026.1)"
            storageLayer = container "Storage Layer" "FileSystem abstraction for S3, GCS, Azure, local storage" "C++ (multiple backends)"
            hfPullModule = container "HuggingFace Pull Module" "Downloads models from HuggingFace Hub via git-lfs" "C++ / libgit2"
            pythonInterpreter = container "Python Interpreter" "Embedded Python for custom compute nodes in MediaPipe graphs" "Python / pybind11"
            capiLib = container "libovms_shared.so" "C API shared library for embedding OVMS in external applications" "C++ Shared Library"
        }

        kserve = softwareSystem "KServe" "Manages ServingRuntime CR that deploys OVMS containers" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar providing TLS termination and Kubernetes RBAC enforcement" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection from /metrics endpoint" "Internal Platform"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration, liveness/readiness probes" "Internal Platform"

        s3 = softwareSystem "Amazon S3" "Model artifact storage" "External Cloud"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External Cloud"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage" "External Cloud"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository hosting and GGUF model downloads" "External Cloud"
        pvcStorage = softwareSystem "PVC / NFS Storage" "Local or network-attached model storage" "Internal Platform"

        # User interactions
        dataScientist -> ovms "Sends inference requests" "HTTPS/8443 (via kube-rbac-proxy)"
        sre -> prometheus "Monitors OVMS metrics" "HTTPS"

        # Platform integrations
        kserve -> ovms "Deploys and manages OVMS container" "Container lifecycle"
        kubeRbacProxy -> ovms "Proxies requests with TLS + AuthN/AuthZ" "HTTP (plaintext, pod-internal)"
        kubernetes -> ovms "Health checks" "HTTP GET /v2/health/*"
        prometheus -> ovms "Scrapes metrics" "HTTP GET /metrics"

        # Egress
        ovms -> s3 "Downloads model artifacts" "HTTPS/443, AWS IAM"
        ovms -> gcs "Downloads model artifacts" "HTTPS/443, OAuth 2.0"
        ovms -> azure "Downloads model artifacts" "HTTPS/443, SAS/MI"
        ovms -> huggingface "Clones model repositories" "HTTPS/443, Bearer Token"
        ovms -> pvcStorage "Reads model files" "Filesystem mount"

        # Internal container relationships
        restServer -> modelManager "Routes inference requests"
        grpcServer -> modelManager "Routes inference requests"
        modelManager -> openvinoRuntime "Executes model inference"
        modelManager -> storageLayer "Loads models from storage"
        modelManager -> hfPullModule "Downloads from HuggingFace"
        modelManager -> dagScheduler "Executes multi-model DAGs"
        modelManager -> mediaPipeEngine "Executes MediaPipe graphs"
        mediaPipeEngine -> openvinoGenAI "LLM continuous batching"
        mediaPipeEngine -> openvinoRuntime "Model inference"
        mediaPipeEngine -> openvinoTokenizers "Tokenization"
        mediaPipeEngine -> pythonInterpreter "Custom Python nodes"
        openvinoGenAI -> openvinoRuntime "Underlying inference"
        storageLayer -> s3 "S3 model download" "HTTPS/443"
        storageLayer -> gcs "GCS model download" "HTTPS/443"
        storageLayer -> azure "Azure model download" "HTTPS/443"
        hfPullModule -> huggingface "Git clone + LFS" "HTTPS/443"
    }

    views {
        systemContext ovms "SystemContext" {
            include *
            autoLayout
        }

        container ovms "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External Cloud" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #f5a623
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
