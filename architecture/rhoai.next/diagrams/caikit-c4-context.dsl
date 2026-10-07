workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys ML models via KServe InferenceServices"
        mlEngineer = person "ML Engineer" "Builds Caikit modules implementing task interfaces for model serving"
        sre = person "SRE / Platform Operator" "Manages model serving infrastructure, monitors health and metrics"

        caikit = softwareSystem "Caikit" "Python AI toolkit and runtime framework for serving models through task-specific gRPC and HTTP APIs" {
            core = container "caikit.core" "Module system, data model abstractions, task definitions, model lifecycle management, pluggable backends" "Python Library"
            interfaces = container "caikit.interfaces" "Domain-specific task and data model definitions for NLP, time series, and vision" "Python Library"
            runtime = container "caikit.runtime" "Dual-protocol server (gRPC + HTTP/REST), servicers, health probes, metrics, tracing" "Python Library"
            healthProbe = container "caikit_health_probe" "Standalone health probe binary for Kubernetes liveness/readiness checks" "Python CLI"

            interfaces -> core "Uses module system and data model abstractions"
            runtime -> core "Uses module registry, model management, task definitions"
            runtime -> interfaces "Serves task-specific APIs defined by interfaces"
            healthProbe -> runtime "Checks health via gRPC Health.Check and HTTP /health"
        }

        # Internal RHOAI platform components
        kserve = softwareSystem "KServe" "Standardized model serving platform — Caikit runs as a ServingRuntime backend" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving orchestration — manages model lifecycle via Unix socket IPC" "Internal RHOAI"
        caikitNlp = softwareSystem "caikit-nlp" "NLP module implementations built on Caikit core" "Internal RHOAI"
        caikitTgis = softwareSystem "caikit-tgis-serving" "TGIS integration module for large language model serving" "Internal RHOAI"

        # External dependencies and services
        otelCollector = softwareSystem "OpenTelemetry Collector" "Receives distributed traces via OTLP" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics from Caikit runtime metrics endpoint" "External"
        kubernetesApi = softwareSystem "Kubernetes API" "Container orchestration platform" "External"

        # Relationships
        dataScientist -> kserve "Creates InferenceService via kubectl/dashboard"
        mlEngineer -> caikit "Develops Caikit modules implementing task interfaces"
        sre -> prometheus "Monitors model serving metrics and alerts"

        kserve -> caikit "Deploys Caikit as ServingRuntime container" "Container runtime"
        modelMesh -> caikit "Manages model lifecycle via ModelRuntime service" "gRPC/Unix socket"
        caikitNlp -> caikit "Imports as library dependency, registers NLP modules" "Python import"
        caikitTgis -> caikit "Imports as library dependency, provides TGIS backend" "Python import"

        caikit -> otelCollector "Exports distributed traces" "OTLP gRPC/4317 or HTTP/4318"
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
        }
    }
}
