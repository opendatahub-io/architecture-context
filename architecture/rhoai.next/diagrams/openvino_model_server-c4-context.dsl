workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, deploys, and queries ML/LLM models for inference"
        mlEngineer = person "ML Engineer" "Configures serving runtimes and manages model deployments"
        sre = person "SRE / Platform Admin" "Monitors inference services and manages platform components"

        ovms = softwareSystem "OpenVINO Model Server (OVMS)" "High-performance AI model inference server supporting KServe v2, TFS v1, and OpenAI-compatible APIs with LLM continuous batching" {
            restServer = container "REST Server" "HTTP/1.1 server handling TFS v1, KServe v2, and OpenAI v3 API requests" "C++ / Drogon Framework"
            grpcServer = container "gRPC Server" "gRPC (HTTP/2) server for KServe v2 and TFS inference RPCs" "C++ / gRPC Framework"
            modelManager = container "Model Manager" "Manages model lifecycle: loading, versioning, hot reload, config watching" "C++"
            modelInstance = container "Model Instance" "Per-model inference execution context with batching support" "C++"
            dagScheduler = container "DAG Pipeline Scheduler" "Chains models and custom processing nodes in directed acyclic graphs" "C++"
            mediaPipeExecutor = container "MediaPipe Graph Executor" "Executes complex inference pipelines for LLM, embeddings, rerank, audio, image gen" "C++ / MediaPipe"
            continuousBatching = container "Continuous Batching Pipeline" "LLM text generation with overlapped prompt processing and token generation" "C++ / OpenVINO GenAI"
            embeddingsServable = container "Embeddings Servable" "Text embeddings computation via OpenAI-compatible API" "C++"
            rerankServable = container "Rerank Servable" "Document reranking via Cohere-compatible API" "C++"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus-format metrics for inference latency, throughput, model status" "C++"
            capiLibrary = container "libovms_shared.so" "C API library for embedding OVMS inference in external applications" "C/C++ Shared Library"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform — manages InferenceService CRs and deploys OVMS pods" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization proxy sidecar injected by RHOAI platform operator" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh providing mTLS encryption and traffic management" "External"
        openvinoRuntime = softwareSystem "OpenVINO Runtime 2026.0" "Core inference engine — compiles and executes AI models on CPU/GPU/NPU" "External"
        openvinoGenAI = softwareSystem "OpenVINO GenAI 2026.0" "LLM continuous batching, Whisper, TTS, and image generation pipelines" "External"
        s3 = softwareSystem "Amazon S3" "Cloud object storage for model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Cloud object storage for model artifacts" "External"
        azure = softwareSystem "Azure Blob Storage" "Cloud object storage for model artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained models" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External"
        grafana = softwareSystem "Grafana" "Dashboard visualization for OVMS metrics" "External"

        # User interactions
        dataScientist -> ovms "Sends inference requests (REST/gRPC)" "HTTPS/8443 via kube-rbac-proxy"
        mlEngineer -> kserve "Creates InferenceService CRs with OVMS ServingRuntime" "kubectl / YAML"
        sre -> prometheus "Monitors inference metrics" "HTTP"
        sre -> grafana "Views dashboards" "HTTPS"

        # Platform interactions
        kserve -> ovms "Deploys OVMS as inference container in InferenceService pods" "Container runtime"
        kubeRbacProxy -> ovms "Proxies authenticated requests to OVMS" "HTTP localhost"
        istio -> ovms "Provides mTLS encryption for pod-to-pod traffic" "mTLS"

        # Internal container interactions
        restServer -> modelManager "Routes v1/v2 requests to model manager" "In-process"
        restServer -> mediaPipeExecutor "Routes v3 requests to MediaPipe graphs" "In-process"
        grpcServer -> modelManager "Routes gRPC RPCs to model manager" "In-process"
        modelManager -> modelInstance "Dispatches inference to model instances" "In-process"
        mediaPipeExecutor -> continuousBatching "Executes LLM generation pipeline" "In-process"
        mediaPipeExecutor -> embeddingsServable "Executes embeddings pipeline" "In-process"
        mediaPipeExecutor -> rerankServable "Executes reranking pipeline" "In-process"
        modelInstance -> openvinoRuntime "Executes model inference" "In-process library"
        continuousBatching -> openvinoGenAI "Runs LLM continuous batching" "In-process library"

        # External service interactions
        ovms -> s3 "Downloads model artifacts" "HTTPS/443, AWS IAM"
        ovms -> gcs "Downloads model artifacts" "HTTPS/443, GCP SA"
        ovms -> azure "Downloads model artifacts" "HTTPS/443, Connection String"
        ovms -> huggingface "Downloads pre-trained models" "HTTPS/443, HF_TOKEN"
        prometheus -> ovms "Scrapes /metrics endpoint" "HTTP"
        grafana -> prometheus "Queries metrics" "HTTP"
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
