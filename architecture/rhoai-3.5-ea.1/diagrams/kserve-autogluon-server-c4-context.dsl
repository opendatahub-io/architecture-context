workspace {
    model {
        user = person "Data Scientist" "Creates InferenceService CRs with modelFormat: autogluon to deploy and serve AutoGluon models"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via KServe v1/v2 REST and gRPC inference protocols" {
            serverContainer = container "autogluonserver" "Python ML model server serving AutoGluon models via FastAPI REST (8080) and gRPC (8081)" "Python / FastAPI / gRPC"
            kserveSDK = container "KServe SDK" "Provides model serving framework: REST endpoints, gRPC server, model repository, health checks, Prometheus metrics" "Python Library"
            kserveStorage = container "KServe Storage" "Downloads model artifacts from remote storage (S3, GCS, Azure, HuggingFace) to local filesystem" "Python Library"
        }

        kserveController = softwareSystem "KServe Controller" "Manages InferenceService lifecycle, creates pods with serving runtime containers" "Internal RHOAI"
        platformGateway = softwareSystem "Platform Gateway" "Istio Gateway / Gateway API providing HTTPS ingress with TLS termination and auth" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        s3 = softwareSystem "S3-Compatible Storage" "Object storage for ML model artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for ML model artifacts" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Object storage for ML model artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for ML model artifacts" "External"

        # Relationships
        user -> kserveController "Creates InferenceService CR" "kubectl / RHOAI Dashboard"
        kserveController -> autogluonServer "Deploys pods using ClusterServingRuntime spec" "Kubernetes API"

        user -> platformGateway "Sends inference requests" "HTTPS/443, TLS 1.2+"
        platformGateway -> autogluonServer "Routes inference traffic" "HTTP/8080"

        autogluonServer -> s3 "Downloads model artifacts" "HTTPS/443, AWS IAM"
        autogluonServer -> gcs "Downloads model artifacts" "HTTPS/443, GCP SA"
        autogluonServer -> azureBlob "Downloads model artifacts" "HTTPS/443, Azure creds"
        autogluonServer -> huggingface "Downloads model artifacts" "HTTPS/443, HF token"

        prometheus -> autogluonServer "Scrapes metrics" "HTTP/8080 /metrics"

        # Internal relationships
        serverContainer -> kserveSDK "Uses for REST/gRPC serving"
        serverContainer -> kserveStorage "Uses for model download"
    }

    views {
        systemContext autogluonServer "SystemContext" {
            include *
            autoLayout
        }

        container autogluonServer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                shape RoundedBox
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
