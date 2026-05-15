workspace {
    model {
        user = person "Data Scientist" "Creates InferenceService resources and sends inference requests to deployed AutoGluon models"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models for inference via REST/gRPC APIs" {
            serverProcess = container "autogluonserver" "Python process running KServe ModelServer with AutoGluon model detection, tabular (v1/v2) and time series (v1) inference" "Python / FastAPI / Uvicorn"
            storageInitializer = container "Storage Initializer" "Init container that downloads model artifacts from cloud storage to local volume before server starts" "Python / kserve-storage"
            modelVolume = container "/mnt/models" "Shared volume holding downloaded model artifacts" "EmptyDir Volume"
        }

        kserveController = softwareSystem "KServe Controller" "Kubernetes operator that manages InferenceService lifecycle, creates pods using ClusterServingRuntime templates" "Internal RHOAI"
        kserveIngress = softwareSystem "KServe Ingress" "Gateway/Route managed by KServe controller for TLS termination and auth enforcement" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection system that scrapes inference server metrics" "Internal Platform"

        s3Storage = softwareSystem "S3-Compatible Storage" "Cloud object storage for ML model artifacts (AWS S3, MinIO, etc.)" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained model artifacts" "External"
        gitRepos = softwareSystem "Git Repositories" "Git-hosted model artifact repositories" "External"

        # Relationships
        user -> kserveIngress "Sends inference requests" "HTTPS/443, TLS 1.2+, Bearer Token"
        kserveIngress -> autogluonServer "Forwards requests after TLS termination and auth" "HTTP/8080"

        kserveController -> autogluonServer "Creates and manages InferenceService pods" "Kubernetes API"

        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443, TLS 1.2+, AWS IAM"
        storageInitializer -> hfHub "Downloads model artifacts" "HTTPS/443, TLS 1.2+, HF Token"
        storageInitializer -> gitRepos "Clones model artifacts" "HTTPS/443, TLS 1.2+, Git creds"
        storageInitializer -> modelVolume "Writes model files"

        serverProcess -> modelVolume "Loads model artifacts at startup"

        prometheus -> autogluonServer "Scrapes metrics" "HTTP/8080, GET /metrics"
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
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
