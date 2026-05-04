workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys AutoGluon ML models for tabular and time series prediction"
        mlEngineer = person "ML Engineer" "Manages KServe InferenceService configurations and serving runtimes"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via REST and gRPC inference APIs" {
            restServer = container "REST Server" "FastAPI/Uvicorn HTTP server exposing v1 and v2 (Open Inference Protocol) endpoints" "Python/FastAPI" "8080/TCP"
            grpcServer = container "gRPC Server" "gRPC inference server for v2 Open Inference Protocol" "Python/grpcio" "8081/TCP"
            autoDetect = container "Predictor Auto-Detection" "Auto-detects model type (TabularPredictor vs TimeSeriesPredictor) from saved model directory" "Python"
            tabularModel = container "Tabular Model" "Wraps AutoGluon TabularPredictor for classification, regression, and quantile prediction" "Python/AutoGluon"
            timeSeriesModel = container "Time Series Model" "Wraps AutoGluon TimeSeriesPredictor for time series forecasting" "Python/AutoGluon"
            modelRepo = container "Model Repository" "Manages model loading/unloading and storage download" "Python/KServe SDK"
        }

        kserveController = softwareSystem "KServe Controller" "Manages InferenceService CRDs and creates serving pods" "Internal RHOAI"
        kserveRouter = softwareSystem "KServe Router" "Routes inference traffic to model server pods" "Internal RHOAI"
        kserveIngress = softwareSystem "KServe Ingress Layer" "TLS termination, auth (Istio Gateway / kube-rbac-proxy / OpenShift Route)" "Internal RHOAI"

        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public/private model repository" "External"
        gcsAzure = softwareSystem "GCS / Azure Blob" "Alternative cloud model storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        # Relationships
        dataScientist -> kserveController "Creates InferenceService CR via kubectl/dashboard"
        mlEngineer -> kserveController "Configures serving runtimes and InferenceService"
        kserveController -> autogluonServer "Creates pod with autogluon-server image"

        dataScientist -> kserveIngress "Sends inference requests"
        kserveIngress -> kserveRouter "Routes after TLS termination and auth" "HTTP/gRPC"
        kserveRouter -> autogluonServer "Forwards inference requests" "HTTP/8080, gRPC/8081"

        autogluonServer -> s3Storage "Downloads model artifacts at startup" "HTTPS/443 AWS IAM"
        autogluonServer -> huggingfaceHub "Downloads model artifacts" "HTTPS/443 Bearer Token"
        autogluonServer -> gcsAzure "Downloads model artifacts (if configured)" "HTTPS/443 SA/SAS"

        prometheus -> autogluonServer "Scrapes /metrics endpoint" "HTTP/8080"

        # Internal container relationships
        restServer -> autoDetect "Delegates inference"
        grpcServer -> autoDetect "Delegates inference"
        autoDetect -> tabularModel "Routes tabular requests"
        autoDetect -> timeSeriesModel "Routes time series requests"
        modelRepo -> s3Storage "Downloads via kserve-storage"
        modelRepo -> huggingfaceHub "Downloads via kserve-storage"
    }

    views {
        systemContext autogluonServer "SystemContext" {
            include *
            autoLayout
            description "System context showing KServe AutoGluon Server in the RHOAI ecosystem"
        }

        container autogluonServer "Containers" {
            include *
            autoLayout
            description "Container view showing internal structure of the AutoGluon Server"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #4a90e2
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
