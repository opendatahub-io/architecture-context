workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML models using caikit modules"
        appdev = person "Application Developer" "Sends inference requests via gRPC/HTTP APIs"

        caikit = softwareSystem "Caikit" "Python AI toolkit providing modular framework for building, training, and serving AI models through task-specific gRPC and HTTP APIs" {
            core = container "caikit.core" "Module framework with task, data model, and model management abstractions. Decorator-driven registration (@module, @task, @dataobject)" "Python Library"
            interfaces = container "caikit.interfaces" "Domain-specific task and data model definitions for NLP, time series, and vision use cases" "Python Library"
            runtime = container "caikit.runtime" "Dual-protocol servers (gRPC + HTTP/FastAPI) that dynamically generate serving endpoints from registered modules via ServicePackageFactory" "Python Service" {
                grpcServer = component "gRPC Server" "Port 8085/TCP - Inference, Training, ModelRuntime, Health services" "gRPC/HTTP2"
                httpServer = component "HTTP Server" "Port 8080/TCP - FastAPI/Uvicorn REST endpoints for inference, training, management" "HTTP/HTTPS"
                metricsServer = component "Metrics Server" "Port 8086/TCP - Prometheus metrics exposition" "HTTP"
                serviceFactory = component "ServicePackageFactory" "Dynamically builds service packages by introspecting registered modules and tasks" "Python"
                predictServicer = component "GlobalPredictServicer" "Handles unary and streaming inference requests" "Python"
                trainServicer = component "GlobalTrainServicer" "Handles training job submission and management" "Python"
                modelRuntimeServicer = component "ModelRuntimeServicer" "Implements ModelMesh sidecar protocol (loadModel, unloadModel, predictModelSize)" "gRPC"
            }
            healthProbe = container "caikit-health-probe" "Kubernetes liveness/readiness probe CLI - separate process that validates runtime health via gRPC/HTTP" "Python CLI"
            clientModule = container "caikit.runtime.client" "Remote model discovery and proxy module (RemoteModuleBase) for distributed inference" "Python Library"
        }

        modelmesh = softwareSystem "ModelMesh" "Model lifecycle management via sidecar protocol" "External Platform"
        kserve = softwareSystem "KServe" "Container orchestration for model serving" "External Platform"
        istio = softwareSystem "Istio / Service Mesh" "Traffic management, mTLS, and ingress routing" "External Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing infrastructure" "External Platform"
        s3 = softwareSystem "S3-compatible Storage" "Model artifact and training data storage" "External Service"
        caikitNLP = softwareSystem "caikit-nlp / caikit-tgis-serving" "Downstream libraries that register AI modules using @module decorator" "Internal RHOAI"
        remoteCaikit = softwareSystem "Remote Caikit Runtime" "Remote runtime instance for distributed inference" "Internal RHOAI"

        # Person interactions
        datascientist -> caikit "Develops and registers AI modules using @module/@task decorators"
        appdev -> caikit "Sends inference/training requests via gRPC (8085) or HTTP (8080)"

        # Internal relationships
        interfaces -> core "Registers tasks and data models"
        runtime -> core "Uses model management, module registry"
        serviceFactory -> core "Introspects MODULE_REGISTRY to generate endpoints"
        grpcServer -> predictServicer "Routes inference RPCs"
        grpcServer -> trainServicer "Routes training RPCs"
        grpcServer -> modelRuntimeServicer "Routes ModelMesh sidecar RPCs"
        httpServer -> predictServicer "Routes REST inference requests"
        httpServer -> trainServicer "Routes REST training requests"
        predictServicer -> metricsServer "Records RPC metrics"
        healthProbe -> grpcServer "Health check via grpc.health.v1 (8085/TCP)"
        healthProbe -> httpServer "Health check via GET /health (8080/TCP)"

        # External relationships
        modelmesh -> caikit "loadModel/unloadModel via unix:///tmp/mmesh/grpc.sock" "gRPC/plaintext"
        kserve -> caikit "Container orchestration" "N/A"
        istio -> caikit "Ingress routing and mTLS" "HTTPS/mTLS"
        caikit -> prometheus "Metrics exposition" "HTTP/8086"
        caikit -> otelCollector "Trace span export" "OTLP gRPC/4317 or HTTP/4318"
        caikit -> s3 "Model artifact retrieval and training data" "HTTPS/443 TLS 1.2+ AWS IAM"
        caikitNLP -> caikit "Registers modules via @module decorator" "Python import"
        clientModule -> remoteCaikit "Distributed inference via RemoteModuleBase" "gRPC/HTTP TLS/mTLS"
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
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
