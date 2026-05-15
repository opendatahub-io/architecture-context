workspace {
    model {
        # Actors
        datascientist = person "Data Scientist" "Deploys and queries ML models for inference"
        application = person "Application / Client" "Sends inference requests to deployed models"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and model serving infrastructure"

        # Core System
        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference server for AI models via gRPC and REST APIs, optimized for Intel architectures" {
            drogonServer = container "Drogon HTTP Server" "REST API frontend serving TFS v1, KServe v2, and OpenAI v3 endpoints" "C++ / Drogon Framework" "WebBrowser"
            grpcServer = container "gRPC Server" "gRPC frontend for KServe v2 and TFS inference protocols" "C++ / gRPC"
            tfsHandler = container "TFS v1 Handler" "TensorFlow Serving compatible predict and metadata API" "C++"
            kfsHandler = container "KServe v2 Handler" "KServe inference protocol handler (infer, metadata, health)" "C++"
            v3Handler = container "OpenAI v3 Handler" "OpenAI-compatible API for chat completions, embeddings, reranking, image gen, audio" "C++"
            mediapipeEngine = container "MediaPipe Graph Executor" "Graph-based pipeline execution for composing inference workflows" "C++ / MediaPipe"
            servableManager = container "Servable Manager" "Model lifecycle management, loading, versioning" "C++"
            hfPullModule = container "HuggingFace Pull Module" "Downloads models from HuggingFace Hub via libgit2" "C++ / libgit2"
            metricsModule = container "Metrics Module" "Prometheus metrics collection and exposition" "C++ / Prometheus Client"
            pythonBinding = container "Python Binding" "pybind11 module for Jinja2 chat template rendering" "Python 3.12 / pybind11"
        }

        # Platform Dependencies
        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle, deploys OVMS pods" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication proxy sidecar in RHOAI deployments" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Monitoring" "Metrics collection and alerting platform" "Internal Platform"
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration, health probes, pod management" "Internal Platform"

        # Runtime Libraries (linked, not networked)
        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Neural network inference engine optimized for Intel hardware" "Intel Library"
        openvinoGenAI = softwareSystem "OpenVINO GenAI" "LLM/VLM inference pipelines with continuous batching" "Intel Library"

        # External Services
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained models" "External Service"
        s3 = softwareSystem "AWS S3" "Cloud object storage for model artifacts" "External Service"
        azureBlob = softwareSystem "Azure Blob Storage" "Cloud object storage for model artifacts" "External Service"
        gcs = softwareSystem "Google Cloud Storage" "Cloud object storage for model artifacts" "External Service"
        localStorage = softwareSystem "PVC / Local Storage" "Kubernetes persistent volumes for model artifacts" "Internal Storage"

        # Relationships - Actors
        datascientist -> kserve "Creates InferenceService CR" "kubectl / ODH Dashboard"
        application -> ovms "Sends inference requests" "REST/gRPC over HTTPS"
        platformAdmin -> kserve "Configures serving runtimes" "kubectl / RHOAI Dashboard"

        # Relationships - Platform
        kserve -> ovms "Deploys as inference container in InferenceService pods"
        kubeRbacProxy -> ovms "Proxies authenticated requests" "HTTPS/8443 → HTTP/8080,8085"
        application -> kubeRbacProxy "Sends requests through auth proxy" "HTTPS/8443"
        prometheus -> ovms "Scrapes metrics" "HTTP GET /metrics"
        kubernetes -> ovms "Health probes" "HTTP GET /v2/health/*"

        # Relationships - Internal containers
        drogonServer -> tfsHandler "Routes /v1/** requests"
        drogonServer -> kfsHandler "Routes /v2/** requests"
        drogonServer -> v3Handler "Routes /v3/** requests"
        drogonServer -> metricsModule "Routes /metrics requests"
        grpcServer -> kfsHandler "Dispatches KServe v2 RPCs"
        grpcServer -> tfsHandler "Dispatches TFS RPCs"
        v3Handler -> mediapipeEngine "Executes LLM inference graphs"
        tfsHandler -> servableManager "Executes model inference"
        kfsHandler -> servableManager "Executes model inference"
        mediapipeEngine -> openvinoGenAI "LLM/VLM pipeline execution" "C++ API"
        servableManager -> openvinoRuntime "Neural network inference" "C++ API"
        v3Handler -> pythonBinding "Jinja2 chat template rendering" "pybind11"

        # Relationships - External
        hfPullModule -> huggingface "Downloads model artifacts" "HTTPS/443, HF Token"
        servableManager -> s3 "Loads model artifacts" "HTTPS/443, AWS IAM"
        servableManager -> azureBlob "Loads model artifacts" "HTTPS/443, Connection String"
        servableManager -> gcs "Loads model artifacts" "HTTPS/443, GCP Credentials"
        servableManager -> localStorage "Loads model artifacts" "Filesystem"
    }

    views {
        systemContext ovms "SystemContext" "System context diagram for OpenVINO Model Server" {
            include *
            exclude openvinoRuntime openvinoGenAI
            autoLayout
        }

        container ovms "Containers" "Container diagram showing OVMS internal structure" {
            include *
            autoLayout
        }

        styles {
            element "External Service" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90d9
                color #ffffff
            }
            element "Intel Library" {
                background #0071c5
                color #ffffff
            }
            element "Internal Storage" {
                background #e1d5e7
                color #333333
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
