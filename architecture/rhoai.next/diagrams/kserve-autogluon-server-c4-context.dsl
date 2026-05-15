workspace {
    model {
        user = person "Data Scientist" "Creates InferenceService to serve AutoGluon models"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via KServe v1/v2 inference protocol" {
            mainEntry = container "__main__.py" "Entry point, initializes model server" "Python"
            predictorFactory = container "PredictorFactory" "Auto-detects model type (Tabular vs TimeSeries)" "Python"
            tabularModel = container "AutoGluonTabularModel" "Serves tabular predictions via v1 JSON and v2 tensor protocol" "Python"
            timeseriesModel = container "AutoGluonTimeSeriesModel" "Serves time series predictions via v1 JSON only" "Python"
            kserveSDK = container "KServe SDK (vendored)" "HTTP/gRPC server framework, inference protocol types, model repository" "Python"
            storageLib = container "kserve-storage (vendored)" "Model artifact download from S3, GCS, Azure, HF Hub" "Python"
        }

        kserveController = softwareSystem "KServe Controller" "Manages InferenceService lifecycle, creates pods" "Internal Platform"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Auth enforcement sidecar injected by RHOAI platform" "Internal Platform"
        platformIngress = softwareSystem "Platform Ingress" "Gateway/Route managed by KServe for external access" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        s3 = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage (GCS)" "External"
        azure = softwareSystem "Azure Blob Storage" "Model artifact storage (Azure)" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Model artifact storage (HF Hub)" "External"

        # Relationships
        user -> platformIngress "Sends inference requests" "HTTPS/443"
        platformIngress -> kubeRbacProxy "Forwards to auth sidecar" "HTTPS/8443"
        kubeRbacProxy -> autogluonServer "Forwards after auth" "HTTP/8080 localhost"

        kserveController -> autogluonServer "Creates pods with this image" "Kubernetes API"
        prometheus -> autogluonServer "Scrapes /metrics" "HTTP/8080"

        autogluonServer -> s3 "Downloads model artifacts" "HTTPS/443"
        autogluonServer -> gcs "Downloads model artifacts" "HTTPS/443"
        autogluonServer -> azure "Downloads model artifacts" "HTTPS/443"
        autogluonServer -> hfHub "Downloads model artifacts" "HTTPS/443"

        # Internal relationships
        mainEntry -> predictorFactory "Initializes"
        mainEntry -> kserveSDK "Starts ModelServer"
        mainEntry -> storageLib "Downloads model"
        predictorFactory -> tabularModel "Creates if TabularPredictor"
        predictorFactory -> timeseriesModel "Creates if TimeSeriesPredictor"
        tabularModel -> kserveSDK "Implements Model interface"
        timeseriesModel -> kserveSDK "Implements Model interface"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
