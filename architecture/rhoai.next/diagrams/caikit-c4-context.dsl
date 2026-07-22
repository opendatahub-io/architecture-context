workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys AI models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and integrations"

        caikit = softwareSystem "Caikit" "Python AI toolkit and runtime framework providing modular, task-oriented architecture for building, serving, and managing AI models through stable gRPC and HTTP APIs" {
            caikitCore = container "caikit.core" "Core framework with decorator-driven task/module registration, model lifecycle management, and pluggable backend system" "Python"
            caikitRuntime = container "caikit.runtime" "Dual-protocol server (gRPC 8085 + HTTP/FastAPI 8080) with dynamic service generation from task/module definitions" "Python (grpcio + FastAPI)"
            caikitInterfaces = container "caikit.interfaces" "Pre-defined task interfaces and protobuf-backed data models for NLP (11 tasks), time-series (4 tasks), and vision domains" "Python (protobuf)"
            healthProbe = container "caikit_health_probe" "Standalone health probe supporting gRPC and HTTP readiness/liveness checks with TLS/mTLS" "Python CLI"
            clientLib = container "caikit.runtime.client" "Remote model discovery and invocation client supporting gRPC and HTTP protocols" "Python"
        }

        caikitNlp = softwareSystem "caikit-nlp" "Downstream library providing NLP module implementations (text generation, embeddings, reranking)" "Internal RHOAI"
        caikitTgisSvg = softwareSystem "caikit-tgis-serving" "Downstream library integrating with TGIS for LLM serving" "Internal RHOAI"

        modelMesh = softwareSystem "ModelMesh" "Multi-model serving orchestration platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, and auth" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        otlpCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing data collection" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for training data and model artifacts" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Container orchestration platform" "External"

        # User interactions
        dataScientist -> caikit "Submits inference requests and training jobs" "gRPC/8085 or HTTP/8080"
        mlEngineer -> caikit "Manages model deployment and monitoring" "HTTP/8080 management API"

        # Caikit internal relationships
        caikitRuntime -> caikitCore "Uses for model lifecycle, task/module registry" "Python import"
        caikitRuntime -> caikitInterfaces "Generates services from task definitions" "Python import"
        healthProbe -> caikitRuntime "Health checks" "gRPC/8085 or HTTP/8080"
        clientLib -> caikitRuntime "Remote model discovery" "gRPC or HTTP"

        # Downstream consumers
        caikitNlp -> caikit "Registers NLP modules at import time" "Python pip dependency"
        caikitTgisSvg -> caikit "Registers TGIS modules at import time" "Python pip dependency"

        # Platform integrations
        modelMesh -> caikit "Calls loadModel/unloadModel/runtimeStatus via sidecar" "gRPC unix:/tmp/mmesh/grpc.sock"
        kserve -> caikit "Hosts caikit containers as InferenceService pods" "Deployment platform"
        caikit -> istio "Traffic managed and mTLS enforced by service mesh" "Sidecar proxy"

        # Observability
        caikit -> otlpCollector "Exports distributed traces" "OTLP gRPC/4317 or HTTP/4318"
        prometheus -> caikit "Scrapes metrics" "HTTP/8086"

        # External services
        caikit -> s3Storage "Reads training data, writes trained models" "HTTPS/443 AWS IAM"
    }

    views {
        systemContext caikit "SystemContext" {
            include *
            autoLayout
            description "Caikit in the RHOAI ecosystem - a Python AI runtime framework"
        }

        container caikit "Containers" {
            include *
            autoLayout
            description "Internal structure of the Caikit framework"
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
