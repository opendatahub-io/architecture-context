workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and manages ML/LLM models for inference"
        appDeveloper = person "Application Developer" "Integrates model inference into applications via REST/gRPC APIs"

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "High-performance AI model inference server supporting TFS v1, KServe v2, and OpenAI-compatible APIs with LLM continuous batching" {
            drogonHTTP = container "Drogon HTTP Server" "REST API frontend handling TFS v1, KServe v2, and OpenAI v3 protocol requests" "C++ / Drogon Framework"
            grpcServer = container "gRPC Server" "gRPC frontend for KServe v2 inference and TFS prediction services" "C++ / gRPC"
            modelManager = container "Model Manager" "Manages model lifecycle: loading, versioning, hot reload, config polling, and instance routing" "C++"
            llmPipeline = container "LLM Pipeline" "Continuous batching engine for text generation, embeddings, reranking, speech, and image generation" "C++ / MediaPipe / OpenVINO GenAI"
            dagScheduler = container "DAG Pipeline Scheduler" "Chains multiple models and custom processing nodes in directed acyclic graphs" "C++"
            modelLoader = container "Model Loader" "Downloads model artifacts from cloud storage and HuggingFace Hub" "C++ / libcurl / libgit2"
            metricsModule = container "Metrics Module" "Exposes Prometheus-format metrics for inference latency, throughput, and model status" "C++"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform that manages OVMS pod lifecycle via InferenceService CRDs" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar injected by RHOAI platform for Kubernetes token-based access control" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS encryption, traffic management, and service identity for mesh-enabled deployments" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes OVMS metrics endpoint" "Internal RHOAI"
        grafana = softwareSystem "Grafana" "Dashboard visualization for OVMS metrics" "Internal RHOAI"

        s3 = softwareSystem "Amazon S3" "Object storage for ML model artifacts (s3:// paths)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for ML model artifacts (gs:// paths)" "External"
        azure = softwareSystem "Azure Blob Storage" "Object storage for ML model artifacts (az:// paths)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for auto-downloading models via git/HTTPS" "External"
        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Intel inference engine for compiling and executing models on CPU/GPU/NPU" "External Library"
        openvinoGenAI = softwareSystem "OpenVINO GenAI" "LLM continuous batching, Whisper, TTS, and image generation pipelines" "External Library"

        # User interactions
        dataScientist -> kserve "Deploys InferenceService CR via kubectl"
        appDeveloper -> ovms "Sends inference requests" "REST/gRPC"

        # Platform interactions
        kserve -> ovms "Manages pod lifecycle" "InferenceService CR"
        kubeRBACProxy -> ovms "Proxies authenticated requests" "HTTPS/8443 → HTTP"
        istio -> ovms "Provides mTLS envelope" "Envoy sidecar"
        prometheus -> ovms "Scrapes /metrics" "HTTP"
        grafana -> prometheus "Queries metrics" "PromQL"

        # Internal container interactions
        drogonHTTP -> modelManager "Routes TFS v1 and KServe v2 requests"
        drogonHTTP -> llmPipeline "Routes OpenAI v3 requests"
        grpcServer -> modelManager "Routes gRPC inference requests"
        modelManager -> dagScheduler "Executes multi-model pipelines"
        llmPipeline -> openvinoGenAI "Executes LLM/audio/image generation" "In-process"
        modelManager -> openvinoRuntime "Compiles and executes models" "In-process"
        modelLoader -> s3 "Downloads model artifacts" "HTTPS/443 AWS IAM"
        modelLoader -> gcs "Downloads model artifacts" "HTTPS/443 GCP SA"
        modelLoader -> azure "Downloads model artifacts" "HTTPS/443 Connection String"
        modelLoader -> huggingface "Downloads models" "HTTPS/443 HF_TOKEN"
        metricsModule -> prometheus "Exposes Prometheus metrics" "HTTP"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External Library" {
                background #ff9800
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
