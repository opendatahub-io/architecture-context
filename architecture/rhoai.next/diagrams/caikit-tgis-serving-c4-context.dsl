workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and queries LLM inference services"
        sre = person "SRE / Platform Admin" "Monitors and manages platform components"

        caikitTgisSrv = softwareSystem "Caikit-TGIS-Serving" "KServe ServingRuntime container image combining Caikit AI toolkit with TGIS backend for LLM inference" {
            caikitRuntime = container "Caikit Runtime" "Runs caikit.runtime, provides HTTP/gRPC inference APIs, manages model lifecycle, proxies to TGIS" "Python 3.11 (caikit 0.28.1, caikit-nlp 0.5.14)" "transformer-container"
            tgisBackend = container "TGIS Backend" "GPU-accelerated text generation inference server, loads model weights" "TGIS Container" "kserve-container"
            convertUtility = container "convert.py" "Converts HuggingFace models to Caikit format" "Python CLI Utility" "Offline Tool"
        }

        kserve = softwareSystem "KServe" "Orchestrates model serving lifecycle via ServingRuntime and InferenceService CRDs" "Internal RHOAI"
        knative = softwareSystem "Knative Serving" "Provides serverless autoscaling, revision management, and traffic routing" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic policies, PeerAuthentication, and ingress gateway" "Internal RHOAI"
        osmesh = softwareSystem "OpenShift Service Mesh (Maistra)" "Manages Istio control plane on OpenShift" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus (User Workload Monitoring)" "Scrapes Caikit runtime metrics via ServiceMonitor" "Internal OpenShift"
        authorino = softwareSystem "Authorino" "Optional token-based authorization for inference endpoints" "Internal RHOAI"

        s3storage = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3 / MinIO)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight downloads (development only)" "External"

        # User interactions
        datascientist -> kserve "Creates InferenceService CR via kubectl/ODH Dashboard"
        datascientist -> caikitTgisSrv "Sends inference requests (HTTP POST / gRPC)"
        sre -> prometheus "Monitors Caikit runtime metrics"

        # Internal container communication
        caikitRuntime -> tgisBackend "Delegates inference via gRPC" "gRPC/8033 (localhost, plaintext)"

        # Platform dependencies
        caikitTgisSrv -> kserve "Consumed as ServingRuntime" "CRD"
        caikitTgisSrv -> knative "Autoscaling and routing" "Platform"
        caikitTgisSrv -> istio "mTLS, ingress, traffic policies" "Sidecar"
        istio -> osmesh "Managed by" "Control Plane"

        # External service dependencies
        tgisBackend -> s3storage "Downloads model artifacts" "HTTPS/443, TLS 1.2+, IAM Auth"
        tgisBackend -> huggingface "Downloads model weights (dev)" "HTTPS/443"

        # Monitoring
        prometheus -> caikitRuntime "Scrapes metrics" "HTTP/8086, PERMISSIVE mTLS"

        # Optional
        authorino -> caikitTgisSrv "Enforces token auth" "Optional"
    }

    views {
        systemContext caikitTgisSrv "SystemContext" {
            include *
            autoLayout
        }

        container caikitTgisSrv "Containers" {
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
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Offline Tool" {
                background #e8e8e8
                color #333333
            }
        }
    }
}
