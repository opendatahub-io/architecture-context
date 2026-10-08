workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models for serving via KServe"
        appDeveloper = person "Application Developer" "Sends inference requests to served models"

        ovms = softwareSystem "OpenVINO Model Server" "High-performance model inference server built on OpenVINO, serving AI models via REST and gRPC with OpenAI-compatible, KServe, and TFS APIs" {
            httpServer = container "HTTP Server" "REST API serving TFS v1, KServe v2, and OpenAI-compatible v3 endpoints" "C++ / Drogon Framework" {
                tags "OVMS"
            }
            grpcServer = container "gRPC Server" "gRPC API serving TFS PredictionService, ModelService, and KServe GRPCInferenceService" "C++ / gRPC" {
                tags "OVMS"
            }
            servableManager = container "Servable Manager" "Model lifecycle management, versioning, and serving configuration" "C++ Module" {
                tags "OVMS"
            }
            mediaPipePipeline = container "MediaPipe Pipeline" "Graph-based inference calculators for LLM, embeddings, image gen, audio" "C++ / MediaPipe" {
                tags "OVMS"
            }
            openvinoRuntime = container "OpenVINO Runtime" "Core inference engine executing models on CPU/GPU" "C++ / OpenVINO 2026.2" {
                tags "Engine"
            }
            metricModule = container "Metric Module" "Prometheus-compatible metrics collection and exposure" "C++ Module" {
                tags "OVMS"
            }
            nginxSidecar = container "nginx-mtls-auth" "Optional sidecar providing mTLS termination" "Nginx" {
                tags "Optional"
            }
        }

        kserve = softwareSystem "KServe" "Manages model serving lifecycle via ServingRuntime CRDs" {
            tags "Platform"
        }
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained models" {
            tags "External"
        }
        s3 = softwareSystem "S3/GCS/Azure Storage" "Cloud object storage for model artifacts" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "Platform"
        }

        # Relationships
        appDeveloper -> ovms "Sends inference requests" "REST/gRPC"
        dataScientist -> kserve "Deploys InferenceService" "kubectl/API"
        kserve -> ovms "Manages via ServingRuntime CRD" "Kubernetes API"

        appDeveloper -> httpServer "POST /v1, /v2, /v3 endpoints" "HTTP/rest_port"
        appDeveloper -> grpcServer "gRPC inference calls" "gRPC/grpc_port"
        appDeveloper -> nginxSidecar "HTTPS with client cert" "mTLS (optional)"
        nginxSidecar -> httpServer "Forwards plaintext" "HTTP"

        httpServer -> servableManager "Inference requests" "In-process"
        httpServer -> mediaPipePipeline "OpenAI-compatible requests" "In-process"
        grpcServer -> servableManager "gRPC inference" "In-process"
        mediaPipePipeline -> openvinoRuntime "Model execution" "In-process"
        servableManager -> openvinoRuntime "Model execution" "In-process"

        servableManager -> huggingface "Downloads models" "HTTPS/443"
        servableManager -> s3 "Loads model artifacts" "HTTPS/443"
        prometheus -> metricModule "Scrapes metrics" "HTTP/rest_port"
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #7ed321
                color #ffffff
            }
            element "OVMS" {
                background #4a90e2
                color #ffffff
            }
            element "Engine" {
                background #f5a623
                color #ffffff
            }
            element "Optional" {
                background #e8e8e8
                color #333333
            }
        }
    }
}
