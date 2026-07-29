workspace {
    model {
        user = person "Data Scientist" "Creates and deploys text generation models for inference"

        caikitTgisServing = softwareSystem "caikit-tgis-serving" "Caikit-TGIS serving runtime for deploying text generation models via KServe InferenceService on RHOAI" {
            runtime = container "caikit-tgis-serving Runtime" "Packages Caikit AI runtime with TGIS gRPC backend for text generation inference" "Python 3.11"
            convertUtil = container "convert.py" "Converts HuggingFace models to Caikit format" "Python CLI Utility"
            metricsService = container "Metrics Service" "Exposes Prometheus-compatible inference metrics on port 8086" "ClusterIP Service"
        }

        kserve = softwareSystem "KServe" "Manages InferenceService lifecycle and ServingRuntime definitions" "Internal RHOAI"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling and request routing" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh providing ingress gateway and traffic management" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        minioS3 = softwareSystem "MinIO / S3 Storage" "S3-compatible object storage for model artifacts" "External"

        # Relationships
        user -> caikitTgisServing "Sends inference requests (HTTP/gRPC)"
        user -> convertUtil "Converts models from HuggingFace format"

        caikitTgisServing -> minioS3 "Downloads model artifacts" "S3 API/9000 HTTP"
        caikitTgisServing -> kserve "Deployed and managed via InferenceService CR"
        caikitTgisServing -> knativeServing "Serverless scaling and routing"

        istio -> caikitTgisServing "Routes external traffic via Gateway" "HTTPS/443 TLS SIMPLE"
        knativeServing -> caikitTgisServing "Routes internal traffic" "HTTP/8081"
        prometheus -> caikitTgisServing "Scrapes inference metrics" "TCP/8086"

        kserve -> knativeServing "Creates Knative Services for autoscaling"
        kserve -> istio "Configures traffic routing"
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
            element "Person" {
                shape person
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
