workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys LLM models for inference"
        mlEngineer = person "ML Engineer" "Configures ServingRuntimes and manages model deployments"

        caikitTGIS = softwareSystem "Caikit-TGIS-Serving" "Packages Caikit AI runtime with caikit-nlp and caikit-tgis-backend for LLM inference via KServe ServingRuntimes" {
            caikitRuntime = container "Caikit Runtime" "HTTP/gRPC API server for text generation and NLP tasks" "Python 3.11, caikit 0.28.1" {
                httpApi = component "HTTP API" "REST endpoints for text generation and streaming" "caikit.runtime (port 8080)"
                grpcApi = component "gRPC API" "NlpService for text generation, embeddings, NLP tasks" "caikit.runtime (port 8085)"
                metricsEndpoint = component "Metrics Endpoint" "Prometheus metrics export" "caikit.runtime (port 8086)"
                tgisBackend = component "TGIS Backend Connector" "gRPC client to co-located TGIS server" "caikit-tgis-backend 0.1.39"
                nlpModule = component "NLP Module" "Text generation, embeddings, NLP task handlers" "caikit-nlp 0.5.14"
            }
            tgisServer = container "TGIS Server" "Text Generation Inference Server - loads LLM models and performs inference" "TGIS (port 8033 gRPC)" "kserve-container"
        }

        kserve = softwareSystem "KServe" "Orchestrates model serving lifecycle via ServingRuntime and InferenceService CRDs" "Internal Platform"
        knative = softwareSystem "Knative Serving" "Provides serverless autoscaling including scale-to-zero" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and ingress routing" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection via User Workload Monitoring" "Internal Platform"

        s3Storage = softwareSystem "S3-Compatible Storage" "Stores serialized LLM model artifacts" "External"
        konflux = softwareSystem "Konflux" "CI/CD pipeline for multi-arch container image builds" "External"

        # User interactions
        dataScientist -> caikitTGIS "Sends inference requests via HTTP/gRPC" "HTTPS/443"
        mlEngineer -> kserve "Creates InferenceService and ServingRuntime" "kubectl/oc"

        # Internal interactions
        caikitRuntime -> tgisServer "Forwards inference calls" "gRPC/8033 (localhost)"
        caikitTGIS -> kserve "Deployed and managed as ServingRuntime" "CRD lifecycle"
        caikitTGIS -> knative "Autoscaled by Knative" "Pod lifecycle"
        caikitTGIS -> istio "Traffic encrypted via sidecar" "mTLS STRICT"
        prometheus -> caikitTGIS "Scrapes metrics" "HTTP/8086 (PERMISSIVE)"

        # External service interactions
        caikitTGIS -> s3Storage "Downloads model artifacts at startup" "HTTPS/443, AWS IAM"
        konflux -> caikitTGIS "Builds multi-arch container images" "Tekton PipelineRun"

        # Component relationships
        httpApi -> tgisBackend "Routes inference to TGIS"
        grpcApi -> tgisBackend "Routes inference to TGIS"
        tgisBackend -> nlpModule "Uses NLP task handlers"
    }

    views {
        systemContext caikitTGIS "SystemContext" {
            include *
            autoLayout
        }

        container caikitTGIS "Containers" {
            include *
            autoLayout
        }

        component caikitRuntime "Components" {
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
            element "Internal Platform" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
