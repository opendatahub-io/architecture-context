workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries ML models for inference"
        application = person "Application" "Sends inference requests via REST/gRPC APIs"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance C++ inference server exposing OpenAI-compatible, KServe v2, and TFS REST/gRPC APIs" {
            httpServer = container "HTTPServerModule" "REST API server handling TFS v1, KServe v2, and OpenAI v3 endpoints" "C++ / Drogon"
            grpcServer = container "GRPCServerModule" "gRPC server for TFS and KServe v2 inference protocols" "C++ / gRPC"
            servableManager = container "ServableManagerModule" "Model lifecycle management — loading, versioning, hot-reload, DAG pipelines" "C++"
            llmServable = container "LLM Servable" "Text generation with continuous batching via OpenVINO GenAI" "C++"
            vlmServable = container "VLM Servable" "Visual language model serving with image+text input" "C++"
            embeddingsServable = container "Embeddings Servable" "Text embeddings computation" "C++"
            rerankServable = container "Rerank Servable" "Document reranking" "C++"
            imageGenServable = container "Image Generation Servable" "Image generation" "C++"
            audioServable = container "Audio Servable" "Speech-to-text and text-to-speech" "C++"
            hfPullModule = container "HfPullModelModule" "Downloads models from HuggingFace Hub with optional optimum-intel conversion" "C++ / libgit2 / curl"
            metricModule = container "MetricModule" "Prometheus-compatible metrics collection" "C++"
            nginxSidecar = container "nginx-mtls-auth" "Optional mTLS termination sidecar" "nginx" "Optional"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform that deploys OVMS via ServingRuntime CRDs" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh providing traffic management, mTLS, and ingress gateway" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        openvinoRuntime = softwareSystem "OpenVINO Runtime" "Intel inference engine for model execution on CPU/GPU/NPU" "Embedded"

        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained models" "External"

        # Relationships
        application -> ovms "Sends inference requests" "REST/gRPC"
        datascientist -> kserve "Creates InferenceService via kubectl"
        kserve -> ovms "Deploys as ServingRuntime container"
        istio -> ovms "Routes traffic, provides mTLS"
        prometheus -> ovms "Scrapes /metrics" "HTTP"

        ovms -> openvinoRuntime "Executes model inference" "in-process"
        ovms -> s3 "Downloads model artifacts" "HTTPS/443"
        ovms -> gcs "Downloads model artifacts" "HTTPS/443"
        ovms -> azureBlob "Downloads model artifacts" "HTTPS/443"
        ovms -> huggingface "Downloads models" "HTTPS/443"

        # Internal container relationships
        httpServer -> servableManager "Routes inference requests"
        grpcServer -> servableManager "Routes inference requests"
        servableManager -> llmServable "Manages"
        servableManager -> vlmServable "Manages"
        servableManager -> embeddingsServable "Manages"
        servableManager -> rerankServable "Manages"
        servableManager -> imageGenServable "Manages"
        servableManager -> audioServable "Manages"
        hfPullModule -> huggingface "Downloads models" "HTTPS"
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
            }
            element "Embedded" {
                background #f5a623
            }
            element "Optional" {
                background #e1d5e7
                shape RoundedBox
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
