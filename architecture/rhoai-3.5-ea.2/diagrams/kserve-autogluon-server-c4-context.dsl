workspace {
    model {
        user = person "Data Scientist" "Creates and deploys AutoGluon ML models for tabular and time series inference"
        client = person "Inference Client" "Sends prediction requests to deployed models"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via KServe REST v1/v2 and gRPC inference protocols" {
            serverProcess = container "AutoGluon Server" "Main inference server with auto-detection of predictor type" "Python / FastAPI / uvicorn"
            tabularModel = container "TabularPredictor" "Classification and regression on structured/tabular data (v1+v2)" "AutoGluon 1.5.0"
            timeSeriesModel = container "TimeSeriesPredictor" "Time series forecasting with mean and quantile predictions (v1 only)" "AutoGluon 1.5.0"
            kserveSDK = container "KServe SDK" "HTTP/gRPC server, protocol handling, model lifecycle" "Python Library 0.19.0"
            storageModule = container "KServe Storage" "Model artifact download from cloud/local storage" "Python Library 0.19.0"
        }

        kserveController = softwareSystem "KServe Controller" "Manages InferenceService lifecycle and creates serving pods" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic routing, and authentication" "External"
        objectStorage = softwareSystem "Object Storage" "S3, GCS, Azure Blob, Hugging Face Hub for model artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        # User relationships
        user -> kserveController "Creates InferenceService CR with modelFormat: autogluon"
        client -> autogluonServer "POST /v1/models/{name}:predict, /v2/models/{name}/infer" "HTTPS/443"
        kserveController -> autogluonServer "Creates and manages pods running the server"

        # Internal container relationships
        serverProcess -> tabularModel "Delegates tabular predictions"
        serverProcess -> timeSeriesModel "Delegates time series predictions"
        serverProcess -> kserveSDK "Uses for HTTP/gRPC serving"
        storageModule -> objectStorage "Downloads model artifacts at startup" "HTTPS/443 TLS 1.2+"

        # External relationships
        autogluonServer -> istio "Sidecar-injected for mTLS and traffic routing" "HTTP/2 15006/TCP"
        autogluonServer -> objectStorage "Downloads model artifacts" "HTTPS/443 TLS 1.2+"
        prometheus -> autogluonServer "Scrapes metrics" "HTTP/8080"
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
                background #4a90e2
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
                shape Person
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
