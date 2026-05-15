workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries AI models for inference"
        mlEngineer = person "ML Engineer" "Configures model serving pipelines and monitors performance"

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "High-performance C++ inference server serving AI models via gRPC, REST (TFS v1, KServe v2), and OpenAI-compatible APIs using OpenVINO runtime" {
            grpcServer = container "gRPC Server Module" "Hosts TFS PredictionService, ModelService, and KServe GRPCInferenceService" "C++ (grpc++)"
            httpServer = container "Drogon HTTP Server" "REST API server for TFS v1, KServe v2, OpenAI v3, and metrics endpoints" "C++ (Drogon Framework)"
            servableManager = container "Servable Manager" "Model lifecycle management: loading, versioning, unloading from storage backends" "C++ Module"
            mediapipeExecutor = container "MediaPipe Graph Executor" "Executes multi-model serving pipelines (DAG scheduling, custom nodes)" "C++ (MediaPipe)"
            genaiServable = container "GenAI Servable" "LLM serving with continuous batching, streaming SSE, chat templates (Jinja2)" "C++ (OpenVINO GenAI)"
            modelInstance = container "Model Instance" "Classical ML model execution via OpenVINO Runtime" "C++ Component"
            hfPullModule = container "HuggingFace Pull Module" "Downloads models from HuggingFace Hub via libgit2/curl" "C++ Module"
            metricModule = container "Metric Module" "Prometheus-compatible metrics collection and /metrics endpoint" "C++ Module"
            pythonInterpreter = container "Python Interpreter Module" "Embedded Python 3.12 for custom node execution" "C++ + Python"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform that deploys OVMS as a serving runtime" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar injected by platform operator" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Transparent mTLS and traffic management between services" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Core inference engine for model execution on Intel architectures" "External Library"
        openvinoGenAI = softwareSystem "OpenVINO GenAI" "Generative AI pipeline support (LLM, image generation, audio)" "External Library"
        s3 = softwareSystem "S3 Storage" "S3-compatible object storage for model artifacts" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Azure cloud storage for model artifacts" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "GCS for model artifacts" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Open ML model repository" "External"

        # Person relationships
        dataScientist -> ovms "Sends inference requests via REST/gRPC"
        dataScientist -> kserve "Creates InferenceService CR to deploy models"
        mlEngineer -> ovms "Configures model serving and monitors metrics"

        # Platform relationships
        kserve -> ovms "Deploys as serving runtime container"
        kubeRbacProxy -> ovms "Proxies authenticated requests" "HTTPS/8443 → HTTP"
        istio -> ovms "Provides transparent mTLS" "Sidecar injection"
        prometheus -> ovms "Scrapes inference and system metrics" "HTTP /metrics"

        # Internal container relationships
        httpServer -> servableManager "Routes inference requests"
        grpcServer -> servableManager "Routes gRPC inference requests"
        servableManager -> modelInstance "Manages classical model lifecycle"
        servableManager -> mediapipeExecutor "Manages pipeline lifecycle"
        mediapipeExecutor -> genaiServable "Executes LLM inference calculators"
        modelInstance -> openvinoRuntime "Executes inference" "In-process"
        genaiServable -> openvinoGenAI "Continuous batching execution" "In-process"
        hfPullModule -> huggingfaceHub "Downloads models" "HTTPS/443"

        # Egress
        ovms -> s3 "Downloads model artifacts" "HTTPS/443, AWS IAM"
        ovms -> azureStorage "Downloads model artifacts" "HTTPS/443, Connection String"
        ovms -> gcsStorage "Downloads model artifacts" "HTTPS/443, Google Creds"
        ovms -> huggingfaceHub "Downloads models via libgit2/curl" "HTTPS/443, HF Token"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Library" {
                background #ff8a65
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
