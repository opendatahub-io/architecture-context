workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for text generation"
        appDeveloper = person "Application Developer" "Integrates LLM inference into applications via HTTP/gRPC APIs"

        caikitTGIS = softwareSystem "Caikit-TGIS-Serving" "Multi-container serving runtime that bridges Caikit AI toolkit with TGIS inference engine for LLM serving" {
            caikitRuntime = container "Caikit Runtime" "Python runtime exposing HTTP (8080) and gRPC (8085) inference APIs with Caikit model management" "Python 3.11 / caikit"
            tgisEngine = container "TGIS Engine" "Text Generation Inference Server — loads models and executes GPU-accelerated inference" "text-generation-launcher"
            convertUtility = container "convert.py" "CLI utility to convert HuggingFace models to Caikit format" "Python CLI"
        }

        kserve = softwareSystem "KServe" "Orchestrates model serving lifecycle via ServingRuntime and InferenceService CRDs" "Internal Platform"
        knativeServing = softwareSystem "Knative Serving" "Provides serverless autoscaling, revision management, and traffic routing" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Enforces mTLS, traffic management, and PeerAuthentication policies" "Internal Platform"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (MinIO, AWS S3)" "External"
        prometheus = softwareSystem "OpenShift User Workload Monitoring" "Prometheus-based metrics collection via ServiceMonitor" "Internal Platform"
        huggingface = softwareSystem "HuggingFace Hub" "Public model repository for downloading pretrained models" "External"

        # User interactions
        dataScientist -> kserve "Creates InferenceService CR specifying model and runtime"
        appDeveloper -> caikitTGIS "Sends inference requests via HTTP/gRPC"

        # Internal flows
        caikitRuntime -> tgisEngine "Delegates inference via gRPC/8033 (localhost)"

        # Platform dependencies
        kserve -> caikitTGIS "Deploys and manages serving pod lifecycle"
        knativeServing -> caikitTGIS "Provides autoscaling and traffic routing"
        istio -> caikitTGIS "Injects sidecar for mTLS and traffic policies"

        # External service access
        caikitTGIS -> s3Storage "Downloads model artifacts (HTTPS/443, TLS 1.2+, IAM auth)"
        prometheus -> caikitTGIS "Scrapes metrics (HTTP/8086, PERMISSIVE mTLS)"
        convertUtility -> huggingface "Downloads models for conversion (HTTPS/443)"
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
        }
    }
}
