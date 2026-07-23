workspace {
    model {
        dataScientist = person "Data Scientist" "Creates InferenceService CRs to deploy and query LLMs"
        sre = person "SRE / Platform Operator" "Manages platform infrastructure, monitors serving workloads"

        caikitTgisServing = softwareSystem "Caikit-TGIS Serving" "Container image providing Caikit runtime for LLM inference with TGIS backend, deployed as KServe ServingRuntime" {
            caikitRuntime = container "Caikit Runtime" "Handles HTTP/gRPC API requests for text generation, model management, and health probes" "Python 3.11 (caikit v0.28.1)" "transformer-container"
            tgisBackend = container "TGIS Backend" "Performs actual LLM model inference using text-generation-inference server" "TGIS Container" "kserve-container"
            modelVolume = container "Model Volume" "Shared PVC mount at /mnt/models/ storing model artifacts in Caikit format" "PersistentVolumeClaim" "Storage"
        }

        kserve = softwareSystem "KServe" "Orchestrates model serving lifecycle via ServingRuntime and InferenceService CRDs" "Internal Platform"
        knativeServing = softwareSystem "Knative Serving" "Provides serverless autoscaling, traffic splitting, and revision management" "Internal Platform"
        istio = softwareSystem "Istio / Service Mesh" "Provides mTLS, PeerAuthentication, traffic management, and ingress gateway" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Collects caikit_* runtime metrics via ServiceMonitor from openshift-user-workload-monitoring" "Internal Platform"

        s3Storage = softwareSystem "S3 / MinIO Storage" "Model artifact storage; KServe storage initializer downloads models" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model downloads for development/setup (ALLOW_DOWNLOADS=1)" "External"

        # Relationships
        dataScientist -> caikitTgisServing "Sends inference requests (text generation) via" "HTTPS/443, gRPC"
        dataScientist -> kserve "Creates InferenceService CR via" "kubectl / API"
        sre -> prometheus "Monitors serving metrics via" "Dashboard / Alerts"

        caikitRuntime -> tgisBackend "Delegates inference to" "gRPC/8033 (localhost, plaintext)"
        caikitRuntime -> modelVolume "Reads model artifacts from" "/mnt/models/ filesystem mount"
        tgisBackend -> modelVolume "Loads model weights from" "/mnt/models/ filesystem mount"

        caikitTgisServing -> istio "Network traffic encrypted by" "mTLS STRICT, PeerAuthentication"
        caikitTgisServing -> knativeServing "Scaled and routed by" "Knative Service/Revision CRDs"
        kserve -> caikitTgisServing "Manages lifecycle of" "ServingRuntime + InferenceService CRDs"
        s3Storage -> modelVolume "Models downloaded to PVC by" "KServe storage initializer, S3 API/443"
        caikitRuntime -> huggingFaceHub "Downloads models from (dev only)" "HTTPS/443, API Token optional"
        prometheus -> caikitRuntime "Scrapes metrics from" "HTTP/8086, PERMISSIVE mTLS"
    }

    views {
        systemContext caikitTgisServing "SystemContext" {
            include *
            autoLayout
            description "System context for Caikit-TGIS Serving showing external actors and platform dependencies"
        }

        container caikitTgisServing "Containers" {
            include *
            autoLayout
            description "Container view showing Caikit Runtime, TGIS Backend, and Model Volume within a KServe serving pod"
        }

        styles {
            element "Software System" {
                background #438DD5
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
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Storage" {
                shape Cylinder
                background #f5a623
            }
        }
    }
}
