workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys LLM inference services using Caikit model format"
        mlEngineer = person "ML Engineer" "Manages serving runtimes and model deployments"

        caikitTgisSvg = softwareSystem "Caikit-TGIS-Serving" "Multi-container KServe ServingRuntime combining Caikit AI toolkit with TGIS backend for LLM inference" {
            caikitRuntime = container "Caikit Runtime" "Translates HTTP/gRPC inference requests into TGIS backend calls, manages model lifecycle" "Python (caikit 0.28.1)" "transformer-container"
            tgisBackend = container "TGIS Backend" "GPU-accelerated text generation inference server, loads and serves model weights" "Java/Python" "kserve-container"
            convertUtil = container "convert.py" "CLI utility to convert HuggingFace models to Caikit format" "Python CLI"
        }

        kserve = softwareSystem "KServe" "Orchestrates model serving lifecycle via ServingRuntime and InferenceService CRDs" "Internal RHOAI"
        knative = softwareSystem "Knative Serving" "Provides serverless autoscaling, revision management, and traffic routing" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, ingress gateway, and PeerAuthentication" "Internal RHOAI"
        serviceMesh = softwareSystem "OpenShift Service Mesh (Maistra)" "Manages Istio control plane on OpenShift" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Scrapes Caikit runtime metrics from port 8086" "Internal OpenShift"
        authorino = softwareSystem "Authorino" "Optional token-based authorization for inference endpoints" "Internal RHOAI"

        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (MinIO / AWS S3)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight repository (development only)" "External"

        // Relationships
        dataScientist -> kserve "Creates InferenceService via kubectl/dashboard"
        mlEngineer -> kserve "Configures ServingRuntime definitions"

        kserve -> caikitTgisSvg "Manages lifecycle via CRDs"
        knative -> caikitTgisSvg "Provides autoscaling and routing"
        istio -> caikitTgisSvg "Injects mTLS sidecars"

        caikitRuntime -> tgisBackend "Delegates inference" "gRPC/8033 (localhost)"
        tgisBackend -> s3Storage "Downloads model artifacts" "HTTPS/443, TLS 1.2+, IAM"
        tgisBackend -> huggingface "Downloads model weights (dev)" "HTTPS/443"

        prometheus -> caikitRuntime "Scrapes metrics" "HTTP/8086, PERMISSIVE mTLS"
    }

    views {
        systemContext caikitTgisSvg "SystemContext" {
            include *
            autoLayout
        }

        container caikitTgisSvg "Containers" {
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
            element "Internal OpenShift" {
                background #5b9bd5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
