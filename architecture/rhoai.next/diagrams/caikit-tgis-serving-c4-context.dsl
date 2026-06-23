workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries LLM models for text generation inference"
        mlEngineer = person "ML Engineer" "Configures ServingRuntimes and manages model deployment"

        caikitTgisSvc = softwareSystem "Caikit-TGIS-Serving" "Container image providing Caikit AI runtime for LLM inference, acting as transformer layer between clients and TGIS backend" {
            caikitRuntime = container "Caikit Runtime" "Runs python -m caikit.runtime; exposes HTTP/gRPC APIs for NLP tasks" "Python 3.11 (caikit 0.28.1)"
            caikitNlp = container "caikit-nlp" "NLP module providing text generation task definitions and HuggingFace integration" "Python Library v0.5.14"
            caikitTgisBackend = container "caikit-tgis-backend" "Backend connector that delegates model inference to TGIS over gRPC" "Python Library v0.1.39"
            caikitConfig = container "caikit.yml" "Configuration: model directory, TGIS backend connection (localhost:8033), library modules" "YAML Config"
        }

        tgis = softwareSystem "TGIS" "Text Generation Inference Server - GPU-accelerated LLM inference engine" "Internal Platform"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform managing ServingRuntime and InferenceService CRDs" "Internal Platform"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling, revision management, and traffic splitting" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and authorization policies" "Internal Platform"
        prometheus = softwareSystem "Prometheus UWM" "OpenShift User Workload Monitoring for metrics collection" "Internal Platform"
        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, Ceph, MinIO)" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Public model repository for downloading base models (dev/test only)" "External Service"

        # User interactions
        dataScientist -> caikitTgisSvc "Sends inference requests via HTTP POST or gRPC" "HTTPS/443, gRPC"
        mlEngineer -> kserve "Creates InferenceService and ServingRuntime CRs" "kubectl / OpenShift Console"

        # Internal container relationships
        caikitRuntime -> caikitNlp "Loads NLP task modules"
        caikitRuntime -> caikitTgisBackend "Uses for TGIS communication"
        caikitRuntime -> caikitConfig "Reads configuration"

        # External relationships
        caikitTgisSvc -> tgis "Delegates model inference" "gRPC/8033 (localhost, plaintext)"
        caikitTgisSvc -> s3 "Model artifacts downloaded by KServe storage initializer" "HTTPS/443 (TLS 1.2+, AWS IAM)"
        kserve -> caikitTgisSvc "Deploys and manages serving pods" "Kubernetes API"
        knative -> caikitTgisSvc "Provides serverless scaling and traffic routing" "Kubernetes API"
        istio -> caikitTgisSvc "Provides mTLS, AuthZ, traffic management" "Envoy sidecar"
        prometheus -> caikitTgisSvc "Scrapes runtime metrics" "HTTP/8086 (PERMISSIVE mTLS)"
        caikitTgisSvc -> huggingface "Downloads models for conversion (dev/test)" "HTTPS/443"
    }

    views {
        systemContext caikitTgisSvc "SystemContext" {
            include *
            autoLayout
        }

        container caikitTgisSvc "Containers" {
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
            element "Internal Platform" {
                background #438dd5
                color #ffffff
            }
            element "External Service" {
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
