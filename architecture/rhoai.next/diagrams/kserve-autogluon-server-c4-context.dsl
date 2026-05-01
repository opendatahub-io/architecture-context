workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and runtimes"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via REST (v1/v2) and gRPC inference APIs" {
            httpServer = container "HTTP Server" "FastAPI/Uvicorn HTTP server exposing v1 REST and v2 Open Inference Protocol endpoints" "Python (FastAPI)" "Service"
            grpcServer = container "gRPC Server" "gRPC inference endpoint implementing v2 Open Inference Protocol" "Python (grpcio)" "Service"
            predictorFactory = container "Predictor Factory" "Auto-detects model type (Tabular vs TimeSeries) and delegates inference" "Python" "Component"
            tabularPredictor = container "Tabular Predictor" "AutoGluon TabularPredictor for classification, regression, and quantile regression" "Python (autogluon.tabular 1.5.0+rhaiv.2)" "Component"
            timeSeriesPredictor = container "TimeSeries Predictor" "AutoGluon TimeSeriesPredictor for time series forecasting" "Python (autogluon.timeseries 1.5.0+rhaiv.2)" "Component"
            modelRepository = container "Model Repository" "Manages multiple models loaded from /mnt/models directory" "Python" "Component"
            storageLib = container "kserve-storage" "Downloads model artifacts from S3, GCS, PVC, or generic URI" "Python (boto3, google-cloud-storage)" "Library"
        }

        kserveController = softwareSystem "KServe Controller" "Manages InferenceService lifecycle and deploys model serving pods" "Internal RHOAI"
        storageInitializer = softwareSystem "Storage Initializer" "Init container that downloads model artifacts to /mnt/models before server starts" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS enforcement, traffic routing, and service identity" "External"
        knative = softwareSystem "Knative Serving" "Provides serverless autoscaling and revision management" "External"
        prometheus = softwareSystem "Prometheus" "Collects metrics from model serving pods" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Stores ML model artifacts" "External"
        gcsStorage = softwareSystem "GCS Storage" "Stores ML model artifacts" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Hosts pre-trained models and tokenizers" "External"

        # Relationships - External users
        dataScientist -> autogluonServer "Sends inference requests via" "HTTPS/443"
        mlEngineer -> kserveController "Creates InferenceService CR via" "kubectl"

        # Relationships - Internal
        httpServer -> predictorFactory "Routes inference requests to"
        grpcServer -> predictorFactory "Routes gRPC inference to"
        predictorFactory -> tabularPredictor "Delegates tabular inference to"
        predictorFactory -> timeSeriesPredictor "Delegates time series inference to"
        modelRepository -> predictorFactory "Provides loaded models to"
        storageLib -> s3Storage "Downloads model artifacts from" "HTTPS/443"
        storageLib -> gcsStorage "Downloads model artifacts from" "HTTPS/443"

        # Relationships - Platform
        kserveController -> autogluonServer "Deploys and manages pods for" "CRD (InferenceService)"
        storageInitializer -> autogluonServer "Downloads model artifacts to /mnt/models" "Shared Volume"
        istio -> autogluonServer "Enforces mTLS and routes traffic" "mTLS/15006"
        knative -> autogluonServer "Provides autoscaling for" "Knative Service"
        prometheus -> autogluonServer "Scrapes metrics from" "HTTP/8080"

        # Relationships - External services
        autogluonServer -> s3Storage "Downloads model artifacts" "HTTPS/443"
        autogluonServer -> gcsStorage "Downloads model artifacts" "HTTPS/443"
        autogluonServer -> huggingfaceHub "Downloads models and tokenizers" "HTTPS/443"
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
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
            element "Service" {
                shape hexagon
            }
            element "Library" {
                shape component
            }
        }
    }
}
