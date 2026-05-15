workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys AI/ML models"
        mlEngineer = person "ML Engineer" "Integrates models into serving pipelines"

        caikit = softwareSystem "Caikit" "AI toolkit and runtime framework providing modular, task-oriented APIs for loading, serving, training, and managing AI/ML models over gRPC and HTTP" {
            core = container "caikit.core" "Core framework providing module, task, data model, and model management abstractions" "Python Library"
            runtime = container "caikit.runtime" "Dual-protocol (gRPC + HTTP) model serving runtime with dynamic service generation, request batching, and streaming" "Python Service (gRPC + FastAPI)"
            interfacesNlp = container "caikit.interfaces.nlp" "NLP task and data model definitions: text generation, classification, embedding, reranking" "Python Library"
            interfacesTs = container "caikit.interfaces.ts" "Time series task and data model definitions: forecasting, anomaly detection, evaluation" "Python Library"
            interfacesVision = container "caikit.interfaces.vision" "Vision data model definitions with PIL backend" "Python Library"
            interfacesCommon = container "caikit.interfaces.common" "Shared data models: vectors, file handling, remote connection, stream sources" "Python Library"
            healthProbe = container "caikit_health_probe" "Health and readiness probe utility for gRPC and HTTP runtime servers" "Python CLI"
        }

        modelMesh = softwareSystem "ModelMesh" "Intelligent model routing and scaling across serving pods" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        s3 = softwareSystem "S3-compatible Storage" "Model artifact and training data storage" "External"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing infrastructure" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        remoteRuntime = softwareSystem "Remote Caikit Runtime" "Another Caikit instance for remote model proxy" "Internal RHOAI"

        # Relationships - External
        dataScientist -> caikit "Submits inference and training requests via" "gRPC/HTTP"
        mlEngineer -> caikit "Deploys and manages models via" "gRPC/HTTP"

        # Relationships - Internal containers
        runtime -> core "Uses module/task abstractions from"
        interfacesNlp -> core "Registers NLP tasks and data models with"
        interfacesTs -> core "Registers time series tasks and data models with"
        interfacesVision -> core "Registers vision data models with"
        interfacesCommon -> core "Provides shared data models to"
        healthProbe -> runtime "Probes health of" "gRPC/HTTP"

        # Relationships - External systems
        modelMesh -> caikit "Manages model lifecycle via" "gRPC (ModelRuntime sidecar protocol, Unix socket)"
        kserve -> caikit "Hosts as ServingRuntime container" "Container colocation"
        caikit -> s3 "Downloads model artifacts and stores training data via" "HTTPS/443, HMAC/IAM"
        caikit -> otelCollector "Exports traces via" "gRPC/HTTP OTLP, configurable TLS"
        prometheus -> caikit "Scrapes metrics from" "HTTP, plaintext"
        caikit -> remoteRuntime "Proxies requests to remote models via" "gRPC/HTTP, TLS/mTLS"
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
            element "Software System" {
                background #438DD5
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
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
