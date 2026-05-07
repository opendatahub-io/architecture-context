workspace {
    model {
        user = person "Data Scientist" "Deploys and queries LLM models via KServe InferenceService"

        caikitTgisServing = softwareSystem "Caikit-TGIS-Serving" "Caikit runtime frontend for LLM inference backed by TGIS" {
            caikitRuntime = container "Caikit Runtime" "Python runtime exposing HTTP/gRPC inference APIs, model management, and health probes" "Python 3.12 / FastAPI / gRPC" "transformer-container"
            caikitConfig = container "caikit.yml" "Runtime configuration: TGIS backend, model finder, library modules" "YAML Configuration"
            tgisBackend = container "TGIS Backend" "Text Generation Inference Server providing GPU-accelerated model execution" "Container" "kserve-container"
            modelStorage = container "Model Storage (/mnt/models)" "Local model artifacts downloaded by KServe storage initializer" "Volume Mount"
        }

        kserve = softwareSystem "KServe" "ML model serving platform managing ServingRuntime and InferenceService CRDs" "Internal Platform"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling, revision management, and traffic routing" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "mTLS, traffic management, ingress gateway, sidecar injection" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "User workload monitoring and metrics collection" "Internal Platform"
        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage (s3://, pvc://)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloads and conversion (dev only)" "External"

        # User interactions
        user -> caikitTgisServing "Sends inference requests via HTTP/gRPC" "HTTPS/443"
        user -> kserve "Creates InferenceService CRs" "kubectl"

        # Internal container interactions
        caikitRuntime -> caikitConfig "Reads configuration"
        caikitRuntime -> tgisBackend "Sends inference requests" "gRPC/8033 localhost"
        caikitRuntime -> modelStorage "Reads model artifacts"
        tgisBackend -> modelStorage "Loads model weights"

        # Platform dependencies
        caikitTgisServing -> istio "mTLS, traffic routing, ingress" "mTLS STRICT"
        caikitTgisServing -> knative "Serverless scaling, revision mgmt"
        kserve -> caikitTgisServing "Orchestrates deployment lifecycle" "CRD"
        prometheus -> caikitTgisServing "Scrapes metrics" "HTTP/8086 PERMISSIVE"

        # External dependencies
        caikitTgisServing -> s3 "Downloads model artifacts (via KServe init)" "HTTPS/443"
        caikitTgisServing -> huggingface "Downloads models (dev/conversion)" "HTTPS/443"
    }

    views {
        systemContext caikitTgisServing "SystemContext" {
            include *
            autoLayout
        }

        container caikitTgisServing "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
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
