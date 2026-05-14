workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys ML models via task-specific APIs"
        mlApplication = person "ML Application" "Consumes inference APIs for production workloads"

        caikit = softwareSystem "Caikit" "AI toolkit and runtime framework providing task-specific gRPC and HTTP APIs for model serving and training" {
            core = container "caikit.core" "Module/Task/DataModel plugin framework - defines abstractions for AI model implementations" "Python Library"
            runtime = container "caikit.runtime" "Dual-protocol model serving runtime with dynamic service generation" "Python Service" {
                grpcServer = component "gRPC Server" "Serves dynamically-generated task RPCs on port 8085" "grpcio"
                httpServer = component "HTTP Server" "FastAPI-based REST API on port 8080 with SSE streaming" "FastAPI/Uvicorn"
                serviceFactory = component "ServicePackageFactory" "Scans modules at startup, generates gRPC descriptors and HTTP routes" "Python"
                predictServicer = component "GlobalPredictServicer" "Shared inference request handler for both protocols" "Python"
                trainServicer = component "GlobalTrainServicer" "Shared training request handler for both protocols" "Python"
                modelManager = component "ModelManager" "Manages model lifecycle (load, unload, retrieve)" "Python"
                modelRuntimeServicer = component "ModelRuntimeServicer" "Model Mesh sidecar API implementation" "Python"
                metricsEndpoint = component "Metrics Endpoint" "Prometheus metrics on port 8086" "prometheus_client"
            }
            interfaces = container "caikit.interfaces" "Domain-specific task and data model definitions for NLP, vision, time series" "Python Library"
            healthProbe = container "caikit_health_probe" "External health/readiness/liveness probe binary for Kubernetes" "Python CLI"
            config = container "caikit.config" "Hierarchical YAML-based configuration with env var overrides" "Python Library"
        }

        modelMesh = softwareSystem "Model Mesh" "Multi-model serving orchestration (IBM)" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform - hosts caikit as model server" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection and export" "External"
        prometheus = softwareSystem "Prometheus" "Metrics monitoring and alerting" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact and training data storage" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar for RHOAI platform RBAC" "Internal RHOAI"
        caikitNLP = softwareSystem "caikit-nlp" "NLP module implementations (downstream)" "Internal RHOAI"
        caikitTGIS = softwareSystem "caikit-tgis-serving" "TGIS integration for text generation (downstream)" "Internal RHOAI"

        # Relationships
        dataScientist -> caikit "Sends inference and training requests" "HTTP/8080 or gRPC/8085"
        mlApplication -> caikit "Sends inference requests" "HTTP/8080 or gRPC/8085"

        caikit -> modelMesh "Model lifecycle (load/unload)" "gRPC/Unix socket"
        caikit -> s3Storage "Downloads model artifacts, reads training data" "HTTPS/443"
        caikit -> otelCollector "Exports distributed traces" "gRPC/4317 or HTTP/4318"

        kserve -> caikit "Hosts as model server in InferenceService pods"
        kubeRBACProxy -> caikit "Proxies authenticated requests" "HTTP/gRPC"
        prometheus -> caikit "Scrapes runtime metrics" "HTTP/8086"

        caikitNLP -> caikit "Registers NLP modules as Python dependency" "Python import"
        caikitTGIS -> caikit "Registers TGIS modules as Python dependency" "Python import"

        # Internal relationships
        core -> interfaces "Loads task/data model definitions"
        runtime -> core "Uses Module/Task/DataModel framework"
        runtime -> interfaces "Generates services from registered tasks"
        healthProbe -> runtime "Probes gRPC and HTTP servers" "HTTP/8080, gRPC/8085"
        config -> runtime "Provides configuration"
        config -> core "Provides configuration"
    }

    views {
        systemContext caikit "SystemContext" {
            include *
            autoLayout
        }

        container caikit "Containers" {
            include *
            autoLayout
        }

        component runtime "RuntimeComponents" {
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
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
