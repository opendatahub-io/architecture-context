workspace {
    model {
        datascientist = person "Data Scientist" "Creates, trains, and deploys ML models"
        appdev = person "Application Developer" "Consumes AI model predictions via API"

        caikit = softwareSystem "Caikit" "Python AI toolkit and runtime framework for managing, serving, and training AI models through task-specific gRPC and HTTP APIs" {
            core = container "caikit.core" "Module system, task framework, data model, pluggable model management (finders, initializers, trainers)" "Python Framework"
            runtime = container "caikit.runtime" "Dual-protocol model serving runtime with ModelMesh integration" "Python Runtime (gRPC + FastAPI)" {
                grpcServer = component "gRPC Server" "Serves inference, training, model management, and info RPCs" "grpcio, 8085/TCP"
                httpServer = component "HTTP Server" "REST API with SSE streaming, translates to shared servicer layer" "FastAPI/Uvicorn, 8080/TCP"
                servicerLayer = component "Servicer Layer" "GlobalPredict, GlobalTrain, Info, ModelManagement, TrainingManagement servicers" "Python"
                modelManager = component "ModelManager" "Model lifecycle: load, unload, retrieve, train" "Python"
                modelRuntimeServicer = component "ModelRuntimeServicer" "ModelMesh sidecar API (mmesh.ModelRuntime)" "gRPC Unix socket"
                metricsEndpoint = component "Prometheus Metrics" "predict_rpc_count, duration, loaded_models" "HTTP, 8086/TCP"
            }
            interfaces = container "caikit.interfaces" "Domain-specific typed data models and task definitions" "Python Data Models" {
                nlp = component "NLP" "Classification, TextGeneration, Embedding, Reranking, Summarization" "Python"
                timeseries = component "Time Series" "Forecasting, Evaluation with Pandas/PySpark backends" "Python"
                vision = component "Vision" "Image processing with PIL backend" "Python"
                common = component "Common" "Vectors, Streams, Files, Remote types" "Python"
            }
            healthProbe = container "caikit_health_probe" "Standalone health/readiness probe for gRPC and HTTP servers with TLS/mTLS support" "Python CLI Utility"
            clientLib = container "caikit.runtime.client" "Remote model proxy for connecting to and consuming remote caikit runtimes" "Python Client Library"
        }

        kserve = softwareSystem "KServe" "Model serving platform — caikit runs as the serving container in InferenceService pods" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh" "Model lifecycle management — load, unload, size models via gRPC sidecar" "Internal RHOAI"
        caikitNlp = softwareSystem "caikit-nlp" "NLP-specific module implementations extending caikit's task/module framework" "Internal RHOAI"
        caikitTgis = softwareSystem "caikit-tgis-serving" "Text generation serving using caikit runtime with TGIS backend" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and observability" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        modelStorage = softwareSystem "Model Storage" "Filesystem or mounted volume for model artifacts" "External"
        modelTrainDwf = softwareSystem "Model-Train DWF" "Dynamic workflow for training process execution" "Internal RHOAI"

        # User interactions
        datascientist -> caikit "Trains and deploys models via gRPC/HTTP APIs"
        appdev -> caikit "Sends inference requests via gRPC/HTTP"

        # Internal container relationships
        runtime -> core "Uses module/task framework, data models"
        interfaces -> core "Defines tasks and data models using core framework"
        healthProbe -> runtime "Probes gRPC (8085) and HTTP (8080) health endpoints"
        clientLib -> runtime "Connects to remote caikit runtimes"

        # External dependencies
        kserve -> caikit "Hosts caikit as serving container in InferenceService pods"
        modelmesh -> caikit "Manages model lifecycle via Unix socket gRPC (mmesh.ModelRuntime)"
        caikitNlp -> caikit "Imports and extends caikit core/interfaces" "Python import"
        caikitTgis -> caikit "Uses caikit runtime with TGIS backend" "Python import + runtime"
        modelTrainDwf -> caikit "Executes training via processproto.Process RPC" "gRPC/8085"
        caikit -> otelCollector "Exports distributed traces" "OTLP gRPC/4317 or HTTP/4318"
        caikit -> modelStorage "Loads and saves model artifacts" "File I/O"
        prometheus -> caikit "Scrapes metrics" "HTTP/8086"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #5b9bd5
                color #ffffff
            }
            element "Component" {
                background #85C1E9
                color #333333
            }
            element "Person" {
                background #f5a623
                shape Person
                color #ffffff
            }
        }
    }
}
