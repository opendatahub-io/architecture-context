workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries AI/ML models"
        appdev = person "Application Developer" "Integrates AI capabilities via task-based APIs"

        caikit = softwareSystem "Caikit" "AI toolkit framework providing modular, task-based abstraction for building, serving, and managing AI/ML models through gRPC and HTTP APIs" {
            runtime = container "caikit.runtime" "Dual-protocol model serving runtime with dynamic service generation" "Python (FastAPI + grpcio)"
            core = container "caikit.core" "Module system, task definitions, data model, model management, pluggable backends" "Python Library"
            interfaces = container "caikit.interfaces" "Domain-specific data models and tasks for NLP, Time Series, Vision, and Runtime management" "Python Library"
            config = container "caikit.config" "Hierarchical YAML-based configuration with environment variable overrides" "Python Library"
            healthProbe = container "caikit_health_probe" "Standalone health probe binary for Kubernetes liveness and readiness checks" "Python CLI"
        }

        caikitNlp = softwareSystem "caikit-nlp" "NLP model implementations that register modules with the Caikit framework" "Internal RHOAI"
        caikitTgis = softwareSystem "caikit-tgis-serving" "Text generation serving runtime built on Caikit with TGIS backend" "Internal RHOAI"
        modelMesh = softwareSystem "Model Mesh" "Multi-model serving orchestration via ModelRuntime gRPC interface" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform; serves Caikit-based containers as InferenceServices" "Internal RHOAI"

        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives distributed traces via OTLP" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifacts and training data storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration, health checks, pod scheduling" "External"

        # User interactions
        datascientist -> caikit "Deploys models and runs training via kubectl/KServe"
        appdev -> caikit "Sends inference requests" "HTTP 8080 / gRPC 8085"

        # Internal container relationships
        runtime -> core "Uses module registry and model management"
        runtime -> interfaces "Exposes task-based APIs defined in interfaces"
        interfaces -> core "Defines tasks and data models"
        runtime -> config "Reads runtime configuration"
        healthProbe -> runtime "Checks HTTP /health and gRPC Health.Check()"

        # Consuming runtimes
        caikitNlp -> caikit "Registers NLP modules" "Python import"
        caikitTgis -> caikit "Wraps Caikit with TGIS backend" "Python import"

        # Platform integration
        modelMesh -> caikit "Manages model lifecycle" "gRPC Unix socket"
        kserve -> caikit "Runs as predictor container" "Container runtime"
        kubernetes -> caikit "Performs health checks" "Exec probe"

        # External services
        caikit -> otelCollector "Exports distributed traces" "OTLP gRPC/4317 or HTTP/4318"
        caikit -> s3Storage "Loads training data" "HTTPS/443, AWS IAM"
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
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
