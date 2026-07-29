workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference and training"
        mlEngineer = person "ML Engineer" "Builds and integrates AI algorithms using caikit modules"

        caikit = softwareSystem "Caikit" "AI toolkit providing stable task-specific model APIs for inference and training via gRPC and HTTP" {
            grpcServer = container "RuntimeGRPCServer" "Main gRPC server exposing inference, training, and ModelMesh sidecar APIs" "Python gRPC"
            httpServer = container "HTTP Server" "Optional FastAPI-based HTTP server for REST API access" "Python FastAPI"
            modelManager = container "ModelManager" "Manages model lifecycle: load, train, find, cache with singleton pattern" "Python"
            serverWrapper = container "CaikitRuntimeServerWrapper" "Request interception layer for inference and training services" "Python"
            metricsServer = container "Prometheus Metrics Server" "Collects and exposes gRPC metrics via PromServerInterceptor" "Python prometheus-client"

            grpcServer -> serverWrapper "Intercepts requests via"
            serverWrapper -> modelManager "Delegates model operations to"
            grpcServer -> metricsServer "Reports metrics to"
        }

        modelMesh = softwareSystem "ModelMesh" "Intelligent model routing and lifecycle management" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "External"
        modelStorage = softwareSystem "Model Storage" "Stores model artifacts (directories, ZIP archives, byte streams)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        dataScientist -> caikit "Sends inference/training requests via gRPC/HTTP"
        mlEngineer -> caikit "Develops caikit modules and algorithms"

        modelMesh -> caikit "Manages model lifecycle via mmesh.ModelRuntime (unix socket)" "gRPC/Unix Socket"
        caikit -> modelMesh "Communicates via mmesh.ModelMesh API" "gRPC/Unix Socket"
        kserve -> caikit "Routes inference traffic" "gRPC"
        istio -> caikit "Manages TLS/mTLS and traffic routing"
        caikit -> modelStorage "Loads model artifacts" "File I/O"
        prometheus -> caikit "Scrapes metrics" "HTTP"
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

        styles {
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
