workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys AutoGluon models via InferenceService CRs and sends inference requests"
        mlEngineer = person "ML Engineer" "Trains AutoGluon TabularPredictor / TimeSeriesPredictor models and uploads to storage"

        autogluonServer = softwareSystem "kserve-autogluon-server" "KServe-compatible model server for serving AutoGluon TabularPredictor and TimeSeriesPredictor models via REST (v1/v2) and gRPC" {
            restServer = container "FastAPI REST Server" "Serves v1 and v2 (Open Inference Protocol) REST endpoints for model inference, health checks, and metrics" "Python / FastAPI / uvicorn" "8080/TCP"
            grpcServer = container "gRPC Inference Server" "Serves v2 tensor-based inference via gRPC" "Python / grpcio" "8081/TCP"
            predictorFactory = container "Predictor Factory" "Auto-detects model type (tabular vs time series) and delegates to appropriate predictor implementation" "Python"
            tabularModel = container "Tabular Model" "Wraps AutoGluon TabularPredictor for classification, regression, and quantile prediction with v1/v2 format translation" "Python / autogluon.tabular"
            timeSeriesModel = container "Time Series Model" "Wraps AutoGluon TimeSeriesPredictor for forecasting with v1 JSON support" "Python / autogluon.timeseries"
            storageClient = container "Storage Client" "Downloads model artifacts from remote storage at startup" "Python / kserve-storage / boto3"
        }

        kserveController = softwareSystem "KServe Controller" "Manages InferenceService lifecycle, creates pods with serving runtime images" "Internal RHOAI"
        kserveRouter = softwareSystem "KServe Router" "Routes inference traffic to model server pods" "Internal RHOAI"
        ingressLayer = softwareSystem "KServe Ingress Layer" "Handles TLS termination, authentication, and authorization (kube-rbac-proxy / Istio / OpenShift Route)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Scrapes metrics from model server for monitoring" "Internal Platform"
        s3Storage = softwareSystem "S3-compatible Storage" "Stores model artifacts (trained AutoGluon models)" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Hosts pretrained models for download" "External"
        gcsAzure = softwareSystem "GCS / Azure Blob" "Alternative model artifact storage" "External"

        # Relationships
        dataScientist -> ingressLayer "Sends inference requests via" "HTTPS/443"
        dataScientist -> kserveController "Creates InferenceService CR via" "kubectl / API"
        mlEngineer -> s3Storage "Uploads trained models to" "HTTPS/443"

        ingressLayer -> autogluonServer "Forwards requests to" "HTTP/8080, gRPC/8081"
        kserveController -> autogluonServer "Creates pods with serving runtime image" "Kubernetes API"
        kserveRouter -> autogluonServer "Routes inference traffic to" "HTTP/8080, gRPC/8081"
        prometheus -> autogluonServer "Scrapes /metrics from" "HTTP/8080"

        autogluonServer -> s3Storage "Downloads model artifacts from" "HTTPS/443, AWS IAM"
        autogluonServer -> huggingFaceHub "Downloads models from" "HTTPS/443, Bearer Token"
        autogluonServer -> gcsAzure "Downloads models from" "HTTPS/443, SA/SAS Token"

        # Internal container relationships
        restServer -> predictorFactory "Delegates inference to"
        grpcServer -> predictorFactory "Delegates inference to"
        predictorFactory -> tabularModel "Routes tabular requests to"
        predictorFactory -> timeSeriesModel "Routes time series requests to"
        storageClient -> predictorFactory "Provides downloaded model to"
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
                background #438dd5
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
                background #85bbf0
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
