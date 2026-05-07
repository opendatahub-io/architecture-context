workspace {
    model {
        datascientist = person "Data Scientist" "Creates, trains, and deploys AI/ML models using task-specific APIs"
        mlops = person "MLOps Engineer" "Deploys and manages AI model serving infrastructure"

        caikit = softwareSystem "Caikit" "AI toolkit and runtime framework providing task-specific gRPC and HTTP APIs for model serving and training" {
            core = container "caikit.core" "Module/Task/DataModel framework: defines the plugin architecture for AI model implementations" "Python Library"
            interfaces = container "caikit.interfaces" "Domain-specific task and data model definitions for NLP, vision, and time series" "Python Library"
            runtime = container "caikit.runtime" "Dual-protocol (gRPC + HTTP) model serving runtime with Model Mesh integration" "Python Service" {
                grpcServer = component "gRPC Server" "grpcio-based server with dynamic service generation" "grpcio, Python"
                httpServer = component "HTTP Server" "FastAPI-based server with pydantic validation and SSE streaming" "FastAPI, uvicorn"
                serviceFactory = component "ServicePackageFactory" "Dynamically generates gRPC descriptors and HTTP routes from registered modules/tasks" "Python"
                predictServicer = component "GlobalPredictServicer" "Routes inference requests to the appropriate loaded model" "Python"
                trainServicer = component "GlobalTrainServicer" "Routes training requests to the appropriate module" "Python"
                modelManager = component "ModelManager" "Manages model lifecycle: load, unload, retrieve" "Python"
                modelRuntimeServicer = component "ModelRuntimeServicer" "Implements mmesh.ModelRuntime gRPC API for Model Mesh integration" "Python"
            }
            config = container "caikit.config" "Hierarchical YAML-based configuration system with environment variable override" "Python Library"
            healthProbe = container "caikit_health_probe" "Dedicated health/readiness/liveness probe binary for Kubernetes deployments" "Python CLI"
        }

        modelmesh = softwareSystem "Model Mesh" "Multi-model serving orchestration framework" "External"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection and export" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts and training data" "External"
        caikitNlp = softwareSystem "caikit-nlp / caikit-tgis-serving" "NLP module implementations that depend on caikit as SDK" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Kubernetes RBAC-based authentication/authorization proxy" "Internal RHOAI"

        # Person relationships
        datascientist -> caikit "Sends inference and training requests via" "HTTP/gRPC"
        mlops -> caikit "Deploys and manages models via" "HTTP/gRPC"

        # System-level relationships
        caikit -> modelmesh "Implements ModelRuntime sidecar API" "gRPC (Unix socket or 8085/TCP)"
        caikit -> otelCollector "Exports distributed traces" "gRPC/4317 or HTTP/4318"
        caikit -> s3 "Loads model artifacts, reads training data" "HTTPS/443"
        caikit -> prometheus "Exposes runtime metrics" "HTTP/8086"
        kserve -> caikit "Runs caikit as model server container" "Container runtime"
        caikitNlp -> caikit "Imports as Python SDK dependency" "Python import"
        kubeRbacProxy -> caikit "Proxies authenticated requests" "HTTP/gRPC"

        # Container relationships
        core -> interfaces "Provides base abstractions for" "Python import"
        runtime -> core "Uses Module/Task/DataModel from" "Python import"
        runtime -> interfaces "Loads domain task definitions from" "Python import"
        runtime -> config "Reads configuration from" "Python import"
        healthProbe -> runtime "Probes gRPC and HTTP servers" "gRPC/8085, HTTP/8080"

        # Component relationships
        serviceFactory -> grpcServer "Generates gRPC service descriptors for"
        serviceFactory -> httpServer "Generates HTTP routes for"
        grpcServer -> predictServicer "Routes inference RPCs to"
        grpcServer -> trainServicer "Routes training RPCs to"
        httpServer -> predictServicer "Routes HTTP requests to"
        httpServer -> trainServicer "Routes HTTP training to"
        predictServicer -> modelManager "Retrieves loaded models from"
        trainServicer -> modelManager "Accesses modules via"
        modelRuntimeServicer -> modelManager "Manages model lifecycle through"
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
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
