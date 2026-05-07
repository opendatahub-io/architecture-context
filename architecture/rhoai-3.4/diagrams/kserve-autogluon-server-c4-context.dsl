workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys AutoGluon tabular and time series models as InferenceServices"
        inferenceClient = person "Inference Client" "Application or user sending prediction requests"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Python-based KServe inference server for AutoGluon TabularPredictor and TimeSeriesPredictor models" {
            serverProcess = container "autogluonserver" "KServe model server with auto-detection of tabular vs time series models" "Python / FastAPI / Uvicorn" {
                predictorFactory = component "PredictorFactory" "Auto-detects model type (tabular vs time series)" "Python"
                tabularModel = component "TabularModel" "Handles v1 JSON and v2 tensor inference for tabular models" "Python"
                timeseriesModel = component "TimeSeriesModel" "Handles v1 JSON inference for time series forecasting" "Python"
                modelRepository = component "AutoGluonModelRepository" "Multi-model directory support" "Python"
                runtimePaths = component "RuntimePaths" "Ensures writable CWD for non-root containers" "Python"
            }
            kserveSDK = container "KServe Python SDK" "Provides ModelServer, FastAPI app, inference protocols, storage, metrics" "Python Library"
        }

        kserveController = softwareSystem "KServe Controller" "Watches InferenceService CRs and creates inference pods" "Internal RHOAI"
        storageInitializer = softwareSystem "Storage Initializer" "Init container that downloads model artifacts from cloud storage" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication/authorization sidecar enforcing SubjectAccessReview" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Pre-trained model and tokenizer downloads for Chronos" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"

        # Relationships
        dataScientist -> kserveController "Creates InferenceService CR via kubectl/UI"
        kserveController -> autogluonServer "Creates inference pod with server container"
        kserveController -> storageInitializer "Injects as init container"
        kserveController -> kubeRbacProxy "Injects as sidecar container"

        inferenceClient -> kubeRbacProxy "Sends prediction requests" "HTTPS/8443 TLS 1.2+ Bearer Token"
        kubeRbacProxy -> autogluonServer "Forwards authorized requests" "HTTP/8080 localhost"

        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> gcs "Downloads model artifacts" "HTTPS/443"
        storageInitializer -> azureBlob "Downloads model artifacts" "HTTPS/443"
        autogluonServer -> hfHub "Downloads Chronos models/tokenizers" "HTTPS/443"

        prometheus -> autogluonServer "Scrapes metrics" "HTTP/8080 GET /metrics"

        autogluonServer -> kserveSDK "Uses for ModelServer, protocols, storage" "In-process"
        kserveController -> k8sAPI "Watches CRDs, manages pods" "HTTPS/6443"
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

        component serverProcess "Components" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
