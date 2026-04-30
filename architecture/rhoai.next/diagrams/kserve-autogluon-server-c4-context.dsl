workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys AutoGluon ML models for tabular prediction and time series forecasting"
        mlEngineer = person "ML Engineer" "Deploys and manages InferenceService CRs for model serving"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "KServe-compatible model serving runtime for AutoGluon TabularPredictor and TimeSeriesPredictor models via REST and gRPC inference APIs" {
            serverProcess = container "AutoGluon Server" "FastAPI-based HTTP/gRPC model server with auto-detection of TabularPredictor and TimeSeriesPredictor models" "Python / KServe SDK / uvicorn"
            tabularPredictor = container "TabularPredictor" "Classification, regression, and quantile regression inference with v1+v2 protocol support" "AutoGluon 1.5.0+rhaiv.2"
            timeSeriesPredictor = container "TimeSeriesPredictor" "Time series forecasting inference with v1 REST protocol" "AutoGluon 1.5.0+rhaiv.2"
            predictorFactory = container "Predictor Factory" "Auto-detects model type (tabular vs time series) and instantiates correct predictor" "Python"
            storageClient = container "Storage Client" "Downloads model artifacts from remote storage backends" "kserve-storage / boto3"
        }

        kserveController = softwareSystem "KServe Controller" "Manages InferenceService lifecycle, deploys predictor pods" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Traffic management, mTLS enforcement, and authorization" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling and revision management" "External"
        storageInitializer = softwareSystem "Storage Initializer" "Init container that downloads model artifacts to /mnt/models" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO)" "External"
        gcs = softwareSystem "GCS Storage" "Model artifact storage (Google Cloud Storage)" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Pre-trained model and tokenizer downloads" "External"

        # User relationships
        dataScientist -> autogluonServer "Sends inference requests" "HTTPS/443 via Gateway"
        mlEngineer -> kserveController "Creates InferenceService CR" "kubectl / K8s API"

        # Internal container relationships
        serverProcess -> tabularPredictor "Delegates tabular inference" "In-process"
        serverProcess -> timeSeriesPredictor "Delegates time series inference" "In-process"
        serverProcess -> predictorFactory "Creates predictors via" "In-process"
        predictorFactory -> tabularPredictor "Instantiates" "In-process"
        predictorFactory -> timeSeriesPredictor "Instantiates" "In-process"
        storageClient -> s3 "Downloads model artifacts" "HTTPS/443 AWS IAM"
        storageClient -> gcs "Downloads model artifacts" "HTTPS/443 GCP SA"

        # Platform relationships
        kserveController -> autogluonServer "Deploys as predictor pod" "K8s API / CRD"
        storageInitializer -> autogluonServer "Provides model artifacts" "Shared volume /mnt/models"
        istio -> autogluonServer "Enforces mTLS, routes traffic" "Sidecar proxy"
        knativeServing -> autogluonServer "Manages autoscaling" "Pod lifecycle"
        prometheus -> autogluonServer "Scrapes metrics" "HTTP/8080"

        # External service relationships
        autogluonServer -> s3 "Downloads models" "HTTPS/443"
        autogluonServer -> gcs "Downloads models" "HTTPS/443"
        autogluonServer -> huggingFace "Downloads tokenizers/models" "HTTPS/443"
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
        }
    }
}
