workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries ML models via KServe"
        appDeveloper = person "Application Developer" "Integrates AI inference into applications"

        caikit = softwareSystem "Caikit" "Python AI toolkit and runtime framework for serving models through task-specific gRPC and HTTP APIs" {
            core = container "caikit.core" "Module system, data model abstractions, task definitions, model lifecycle, pluggable backends" "Python Library"
            interfaces = container "caikit.interfaces" "Domain-specific task and data model definitions for NLP, TimeSeries, Vision" "Python Library"
            runtime = container "caikit.runtime" "Dual-protocol server (gRPC + HTTP), servicers, health probes, metrics, tracing" "Python Library"
            healthProbe = container "caikit_health_probe" "Standalone health probe for Kubernetes liveness/readiness checks" "Python CLI"
        }

        kserve = softwareSystem "KServe" "Standardized model serving platform on Kubernetes" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving orchestration" "Internal RHOAI"
        caikitNlp = softwareSystem "caikit-nlp" "NLP module implementations built on Caikit" "Internal RHOAI"
        caikitTgis = softwareSystem "caikit-tgis-serving" "TGIS integration module built on Caikit" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed trace collection" "Infrastructure"
        localStorage = softwareSystem "Local Filesystem" "Model artifact and training output storage" "Infrastructure"

        # Relationships
        dataScientist -> kserve "Deploys InferenceService" "kubectl / API"
        appDeveloper -> caikit "Sends inference requests" "gRPC/8085, HTTP/8080"

        kserve -> caikit "Runs as ServingRuntime backend" "Container lifecycle"
        modelMesh -> caikit "Model lifecycle management" "gRPC Unix socket"
        caikitNlp -> caikit "Imports module system" "Python import"
        caikitTgis -> caikit "Imports module system" "Python import"

        caikit -> otelCollector "Exports traces" "gRPC/4317 or HTTP/4318"
        caikit -> localStorage "Reads/writes model artifacts" "File I/O"

        prometheus -> caikit "Scrapes metrics" "HTTP/8086"

        # Internal container relationships
        runtime -> core "Uses module system and data model" "Python import"
        runtime -> interfaces "Discovers registered tasks" "Python import"
        interfaces -> core "Extends base types" "Python import"
        healthProbe -> runtime "Health checks" "gRPC + HTTP"
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
            element "Infrastructure" {
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
