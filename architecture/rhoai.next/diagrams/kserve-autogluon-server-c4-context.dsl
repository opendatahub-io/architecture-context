workspace {
    model {
        user = person "Data Scientist" "Deploys and queries AutoGluon models via InferenceService"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via REST v1/v2 and gRPC inference protocols" {
            serverProcess = container "AutoGluon Server" "Python ML inference server with auto-detection of model type (Tabular vs TimeSeries)" "Python 3.11 / uvicorn / grpcio"
            tabularModel = container "Tabular Model Handler" "Handles TabularPredictor inference via v1 JSON, v2 tensor, and gRPC protocols; supports predict_proba" "Python / autogluon.tabular 1.5.0+rhaiv.3"
            timeseriesModel = container "TimeSeries Model Handler" "Handles TimeSeriesPredictor forecasting via v1 JSON protocol with column metadata mapping" "Python / autogluon.timeseries 1.5.0+rhaiv.3"
            kserveSDK = container "KServe Python SDK" "Model server framework providing inference protocol handling, health probes, and Prometheus metrics" "Python / kserve 0.19.0"
            kserveStorage = container "KServe Storage" "Downloads model artifacts from cloud storage backends at startup" "Python / kserve-storage 0.19.0"
        }

        kserveController = softwareSystem "KServe Controller" "Manages InferenceService pod lifecycle and ingress configuration" "Internal RHOAI"
        clusterServingRuntime = softwareSystem "ClusterServingRuntime" "Defines runtime container image, resources, and model format configuration" "Internal RHOAI"
        platformIngress = softwareSystem "Platform Ingress" "Routes external traffic and handles TLS termination and authentication" "Gateway API / Istio"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model repository and artifact storage" "External"

        # User interactions
        user -> autogluonServer "Sends inference requests via HTTPS/443"
        user -> kserveController "Creates InferenceService CR via kubectl"

        # Platform interactions
        kserveController -> autogluonServer "Manages pod lifecycle" "K8s API / mTLS"
        clusterServingRuntime -> kserveController "Defines runtime config" "CRD"
        platformIngress -> autogluonServer "Routes inference traffic" "HTTP/8080, gRPC/8081"
        prometheus -> autogluonServer "Scrapes metrics" "HTTP/8080"

        # External service interactions
        autogluonServer -> s3 "Downloads model artifacts" "HTTPS/443, TLS 1.2+, AWS IAM"
        autogluonServer -> gcs "Downloads model artifacts" "HTTPS/443, TLS 1.2+, GCP SA"
        autogluonServer -> azureBlob "Downloads model artifacts" "HTTPS/443, TLS 1.2+, Azure creds"
        autogluonServer -> huggingfaceHub "Downloads model artifacts" "HTTPS/443, TLS 1.2+, Bearer Token"

        # Internal container relationships
        serverProcess -> kserveSDK "Uses for serving framework"
        serverProcess -> tabularModel "Delegates tabular inference"
        serverProcess -> timeseriesModel "Delegates timeseries inference"
        serverProcess -> kserveStorage "Downloads models at startup"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
