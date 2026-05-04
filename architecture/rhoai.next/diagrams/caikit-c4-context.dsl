workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys AI/ML models via task-specific APIs"
        application = person "Application / Service" "Consumes model inference endpoints for predictions"

        caikit = softwareSystem "Caikit" "AI toolkit and runtime framework providing task-specific gRPC and HTTP APIs for model serving and training" {
            core = container "caikit.core" "Module/Task/DataModel framework with plugin architecture for AI model implementations" "Python Library"
            interfaces = container "caikit.interfaces" "Domain-specific task and data model definitions for NLP, vision, and time series" "Python Library"
            runtime = container "caikit.runtime" "Dual-protocol (gRPC + HTTP) model serving runtime with Model Mesh integration" "Python Service" {
                grpcServer = component "gRPC Server" "Serves dynamic task-specific RPCs on port 8085/TCP" "grpcio"
                httpServer = component "HTTP Server" "Serves REST API on port 8080/TCP with SSE streaming" "FastAPI/Uvicorn"
                metricsEndpoint = component "Metrics Endpoint" "Prometheus metrics on port 8086/TCP" "prometheus_client"
                serviceFactory = component "ServicePackageFactory" "Dynamically generates gRPC and HTTP routes from registered modules" "Python"
                globalPredictServicer = component "GlobalPredictServicer" "Routes inference requests to loaded models" "Python"
                globalTrainServicer = component "GlobalTrainServicer" "Manages async training job execution" "Python"
                modelManager = component "ModelManager" "Manages model lifecycle (load, unload, retrieve)" "Python"
                modelRuntimeServicer = component "ModelRuntimeServicer" "Implements Model Mesh sidecar API" "Python"
            }
            config = container "caikit.config" "Hierarchical YAML-based configuration with environment variable overrides" "Python Library"
            healthProbe = container "caikit_health_probe" "Kubernetes liveness/readiness probe binary with TLS verification" "Python CLI"
        }

        modelMesh = softwareSystem "Model Mesh" "Multi-model serving orchestration framework" "Internal Platform"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection and export" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts and training data" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Kubernetes RBAC-based authentication sidecar" "Internal Platform"
        caikitNLP = softwareSystem "caikit-nlp / caikit-tgis-serving" "Downstream NLP module implementations" "Internal Platform"

        # Relationships
        dataScientist -> caikit "Deploys models and submits training jobs" "HTTP/gRPC"
        application -> caikit "Sends inference requests" "HTTP/gRPC"

        # Internal
        runtime -> core "Uses module/task/datamodel abstractions" "Python import"
        runtime -> interfaces "Uses domain-specific task definitions" "Python import"
        config -> core "Provides configuration to all components" "Python import"
        healthProbe -> runtime "Probes gRPC and HTTP servers for readiness" "gRPC/HTTP with TLS"

        # Runtime internals
        grpcServer -> globalPredictServicer "Routes gRPC inference RPCs" "in-process"
        httpServer -> globalPredictServicer "Routes HTTP inference requests" "in-process"
        httpServer -> globalTrainServicer "Routes HTTP training requests" "in-process"
        globalPredictServicer -> modelManager "Retrieves loaded models" "in-process"
        globalTrainServicer -> modelManager "Retrieves modules for training" "in-process"
        modelRuntimeServicer -> modelManager "Loads/unloads models on Model Mesh request" "in-process"
        serviceFactory -> grpcServer "Generates gRPC service descriptors" "in-process"
        serviceFactory -> httpServer "Generates HTTP routes" "in-process"

        # External integrations
        modelMesh -> caikit "Manages model lifecycle via sidecar API" "gRPC/Unix socket"
        caikit -> otelCollector "Exports distributed traces" "gRPC/4317 or HTTP/4318"
        prometheus -> caikit "Scrapes runtime metrics" "HTTP/8086"
        caikit -> s3Storage "Downloads model artifacts, reads training data" "HTTPS/443"
        kubeRBACProxy -> caikit "Forwards authenticated requests" "HTTP/gRPC"
        kserve -> caikit "Hosts caikit as model server in InferenceService pods" "Container runtime"
        caikitNLP -> caikit "Depends on caikit SDK for module/task framework" "Python dependency"
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
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
