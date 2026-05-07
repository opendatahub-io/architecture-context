workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys and queries AutoGluon ML models for tabular and time series predictions"
        sre = person "SRE / Platform Admin" "Monitors model server health and performance"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "KServe-compatible model server for serving AutoGluon TabularPredictor and TimeSeriesPredictor models via REST and gRPC" {
            restServer = container "FastAPI REST Server" "Serves v1 and v2 (Open Inference Protocol) REST endpoints for inference, health, and metrics" "Python / FastAPI / uvicorn" "Port 8080/TCP"
            grpcServer = container "gRPC Server" "Serves v2 Open Inference Protocol gRPC endpoints for tensor-based inference" "Python / grpcio" "Port 8081/TCP"
            modelLayer = container "AutoGluon Model Layer" "Auto-detects and loads TabularPredictor or TimeSeriesPredictor, handles prediction and result formatting" "Python / AutoGluon"
            storageClient = container "Storage Client" "Downloads model artifacts from remote storage at startup" "Python / kserve-storage / boto3"
        }

        kserveController = softwareSystem "KServe Controller" "Manages InferenceService CRDs and creates model server pods" "Internal RHOAI"
        kserveRouter = softwareSystem "KServe Router" "Routes inference traffic to model server pods" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Stores model artifacts (TabularPredictor / TimeSeriesPredictor)" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public/private model repository" "External"
        gcsAzure = softwareSystem "GCS / Azure Blob" "Alternative cloud model storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        # Relationships
        dataScientist -> autogluonServer "Sends inference requests via REST or gRPC"
        sre -> prometheus "Monitors model server metrics"

        kserveController -> autogluonServer "Creates and manages pods via InferenceService CRD"
        kserveRouter -> autogluonServer "Routes inference traffic" "HTTP/8080, gRPC/8081"

        autogluonServer -> s3Storage "Downloads model artifacts at startup" "HTTPS/443, AWS IAM"
        autogluonServer -> huggingfaceHub "Downloads model artifacts" "HTTPS/443, Bearer Token"
        autogluonServer -> gcsAzure "Downloads model artifacts" "HTTPS/443, SA/SAS token"
        prometheus -> autogluonServer "Scrapes /metrics endpoint" "HTTP/8080"

        # Internal container relationships
        restServer -> modelLayer "Delegates inference requests"
        grpcServer -> modelLayer "Delegates inference requests"
        modelLayer -> storageClient "Triggers model download at startup"
        storageClient -> s3Storage "Downloads model files" "HTTPS/443"
        storageClient -> huggingfaceHub "Downloads model files" "HTTPS/443"
        storageClient -> gcsAzure "Downloads model files" "HTTPS/443"
    }

    views {
        systemContext autogluonServer "SystemContext" {
            include *
            autoLayout
            description "System context for KServe AutoGluon Server showing external actors and systems"
        }

        container autogluonServer "Containers" {
            include *
            autoLayout
            description "Container view showing internal components of the AutoGluon Server"
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
                background #9b59b6
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
