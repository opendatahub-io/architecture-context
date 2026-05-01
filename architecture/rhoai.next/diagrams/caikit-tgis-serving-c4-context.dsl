workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys LLM inference services on OpenShift AI"
        sreclient = person "SRE / Platform Engineer" "Monitors and operates the inference platform"
        appclient = person "Application Client" "Sends inference requests to deployed models"

        caikitTgisServing = softwareSystem "Caikit-TGIS-Serving" "Container image packaging Caikit AI runtime with NLP and TGIS backend for LLM inference as a KServe ServingRuntime" {
            caikitRuntime = container "Caikit Runtime" "API layer for inference requests, model management, health probing" "Python (caikit 0.28.1)" "transformer-container"
            tgisEngine = container "TGIS Engine" "Text Generation Inference Server - loads LLM models and performs inference" "Java/Rust" "kserve-container"
            caikitConfig = container "caikit.yml" "Runtime configuration: model directory, TGIS-AUTO finder, backend priority" "YAML Configuration"
        }

        kserve = softwareSystem "KServe" "Orchestrates deployment lifecycle, storage access, and networking for serving pods" "Internal RHOAI"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform with scale-to-zero, traffic splitting, revision management" "Internal RHOAI"
        istioServiceMesh = softwareSystem "Istio Service Mesh" "Provides mTLS encryption, traffic management, and ingress routing via sidecar proxies" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring (openshift-user-workload-monitoring)" "OpenShift Platform"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact storage (e.g., AWS S3, MinIO)" "External"
        rhods = softwareSystem "RHODS Operator" "Platform operator that registers ServingRuntimes and manages platform lifecycle" "Internal RHOAI"
        konflux = softwareSystem "Konflux" "CI/CD pipeline for building multi-arch container images (x86_64, arm64)" "Internal Red Hat"

        # User interactions
        datascientist -> kserve "Creates InferenceService & ServingRuntime via kubectl/UI"
        datascientist -> s3Storage "Uploads model artifacts"
        appclient -> caikitTgisServing "Sends inference requests (HTTP/gRPC)" "HTTPS/443"
        sreclient -> prometheus "Monitors inference service metrics"

        # Internal flows
        caikitRuntime -> tgisEngine "Forwards inference requests" "gRPC/8033 (localhost)"
        caikitRuntime -> caikitConfig "Reads configuration at startup"
        tgisEngine -> s3Storage "Downloads model artifacts at startup" "HTTPS/443, AWS IAM"

        # Platform dependencies
        caikitTgisServing -> istioServiceMesh "All traffic encrypted via mTLS sidecar"
        caikitTgisServing -> knativeServing "Autoscaling and serverless lifecycle"
        kserve -> caikitTgisServing "Manages deployment lifecycle" "CRD: ServingRuntime, InferenceService"
        rhods -> kserve "Registers ServingRuntimes with caikit-tgis-serving image"
        prometheus -> caikitTgisServing "Scrapes metrics" "HTTP/8086 (PERMISSIVE mTLS)"
        konflux -> caikitTgisServing "Builds container images" "Tekton PipelineRun"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Red Hat" {
                background #ee0000
                color #ffffff
            }
            element "OpenShift Platform" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
