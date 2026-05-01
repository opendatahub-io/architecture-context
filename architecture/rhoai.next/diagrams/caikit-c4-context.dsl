workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys ML models using task-based APIs"
        appDeveloper = person "Application Developer" "Integrates AI capabilities via gRPC/HTTP inference APIs"

        caikit = softwareSystem "Caikit" "Python AI toolkit providing modular framework for building, training, and serving AI models through task-specific APIs over gRPC and HTTP" {
            core = container "caikit.core" "Module framework with task, data model, and model management abstractions" "Python Library" {
                moduleFramework = component "Module Framework" "@module decorator, ModuleBase, MODULE_REGISTRY" "Python"
                taskDefs = component "Task Definitions" "@task decorator, typed input/output contracts" "Python"
                dataModel = component "Data Model" "@dataobject decorator, protobuf-backed data classes" "Python"
                modelManager = component "Model Manager" "Model load/save/find with pluggable backends" "Python"
                backendSystem = component "Backend System" "LocalBackend + extensible module backends" "Python"
            }

            runtime = container "caikit.runtime" "gRPC and HTTP servers that dynamically generate serving endpoints from registered modules" "Python Service" {
                grpcServer = component "gRPC Server" "gRPC/HTTP2 on port 8085, TLS/mTLS configurable" "Python/grpcio"
                httpServer = component "HTTP Server" "FastAPI/Uvicorn on port 8080, TLS/mTLS configurable" "Python/FastAPI"
                metricsServer = component "Metrics Server" "Prometheus exposition on port 8086" "Python/prometheus_client"
                predictServicer = component "GlobalPredictServicer" "Routes inference requests to model modules" "Python"
                trainServicer = component "GlobalTrainServicer" "Routes training requests to model modules" "Python"
                modelRuntimeServicer = component "ModelRuntimeServicer" "ModelMesh sidecar API implementation" "Python"
                serviceFactory = component "ServicePackageFactory" "Dynamic gRPC/HTTP service generation from module registry" "Python"
            }

            interfaces = container "caikit.interfaces" "Domain-specific task and data model definitions" "Python Library" {
                nlp = component "NLP" "TextGeneration, Embedding, Classification, Reranking tasks" "Python"
                timeSeries = component "Time Series" "Forecasting, Anomaly Detection tasks" "Python"
                vision = component "Vision" "Image Classification tasks" "Python"
            }

            healthProbe = container "caikit_health_probe" "Kubernetes health probe for liveness and readiness checks" "Python CLI"

            clientLib = container "caikit.runtime.client" "Remote model discovery and proxy module for distributed inference" "Python Library"
        }

        modelMesh = softwareSystem "ModelMesh" "Multi-model serving controller for Kubernetes" "External"
        kserve = softwareSystem "KServe" "Serverless inference platform for Kubernetes" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collection" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts and training data" "External"
        caikitNLP = softwareSystem "caikit-nlp / caikit-tgis-serving" "Downstream libraries that register AI modules" "Internal RHOAI"
        remoteCaikit = softwareSystem "Remote Caikit Runtime" "Another Caikit instance for distributed inference" "Internal RHOAI"

        # User interactions
        dataScientist -> caikit "Submits training jobs and queries model info" "gRPC/8085, HTTP/8080"
        appDeveloper -> caikit "Sends inference requests" "gRPC/8085, HTTP/8080"

        # External system interactions
        modelMesh -> caikit "Model lifecycle management (load/unload/size)" "gRPC/unix socket"
        kserve -> caikit "Container orchestration" "Container Runtime"
        caikit -> s3Storage "Fetches model artifacts, training data" "HTTPS/443"
        caikit -> otelCollector "Exports trace spans" "gRPC/4317, HTTP/4318"
        prometheus -> caikit "Scrapes metrics" "HTTP/8086"
        caikitNLP -> caikit "Registers modules via @module decorator" "Python import"
        caikit -> remoteCaikit "Distributed inference" "gRPC/8085, HTTP/8080"

        # Internal container interactions
        runtime -> core "Uses module framework for model operations"
        interfaces -> core "Registers tasks and data models"
        healthProbe -> runtime "Checks gRPC and HTTP server health"
        clientLib -> runtime "Proxies requests to remote runtimes"
        serviceFactory -> moduleFramework "Introspects registry to generate services"
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

        component core "CoreComponents" {
            include *
            autoLayout
        }

        component runtime "RuntimeComponents" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
