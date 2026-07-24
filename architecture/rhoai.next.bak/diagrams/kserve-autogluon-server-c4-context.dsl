workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys AutoGluon tabular and time series models for inference"
        mlEngineer = person "ML Engineer" "Configures InferenceService CRs and ClusterServingRuntimes"

        autogluonServer = softwareSystem "AutoGluon Model Server" "KServe model server serving AutoGluon TabularPredictor and TimeSeriesPredictor models via REST v1/v2 and gRPC protocols" {
            mainModule = container "__main__.py" "Entry point: parses args, initializes runtime paths, creates model server" "Python"
            predictorFactory = container "predictor_factory.py" "Auto-detects model type (Tabular vs TimeSeries) and loads appropriate predictor" "Python"
            tabularModel = container "tabular_model.py" "Serves AutoGluon TabularPredictor with v1 JSON and v2 tensor protocol support" "Python"
            timeseriesModel = container "timeseries_model.py" "Serves AutoGluon TimeSeriesPredictor with v1 JSON protocol" "Python"
            versionCompat = container "version_compat.py" "Patch-level version tolerance for AutoGluon model loading (handles +rhaiv.N suffixes)" "Python"
            kserveSDK = container "kserve SDK" "Model server framework: HTTP/gRPC serving, protocol handling, metrics" "Python Library (vendored 0.19.0)"
            kserveStorage = container "kserve-storage" "Model artifact download from S3, GCS, Azure Blob, HuggingFace Hub" "Python Library (vendored 0.19.0)"
        }

        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar providing TLS termination and Bearer Token authentication" "Sidecar"
        kserveController = softwareSystem "KServe Controller" "Manages InferenceService lifecycle, creates/updates predictor pods" "Internal RHOAI"
        clusterServingRuntime = softwareSystem "ClusterServingRuntime" "Defines container image, ports, and protocol for autogluon model format" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3)" "External"
        gcsStorage = softwareSystem "Google Cloud Storage" "Model artifact storage (GCS)" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Model artifact storage (Azure)" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model artifact repository" "External"

        # Relationships
        dataScientist -> autogluonServer "Sends inference requests (POST /v1/models/{name}:predict)" "HTTPS/8443 via kube-rbac-proxy"
        mlEngineer -> kserveController "Creates InferenceService CR with modelFormat: autogluon" "kubectl/API"

        kserveController -> autogluonServer "Manages pod lifecycle via InferenceService CR"
        clusterServingRuntime -> autogluonServer "Defines runtime spec (image, ports, args)"
        kubeRBACProxy -> autogluonServer "Proxies authenticated requests" "HTTP/8080 plaintext localhost"

        autogluonServer -> s3Storage "Downloads model artifacts at startup" "HTTPS/443 AWS IAM"
        autogluonServer -> gcsStorage "Downloads model artifacts at startup" "HTTPS/443 GCP SA"
        autogluonServer -> azureStorage "Downloads model artifacts at startup" "HTTPS/443 Azure Identity"
        autogluonServer -> hfHub "Downloads model artifacts at startup" "HTTPS/443 HF Token"

        prometheus -> autogluonServer "Scrapes metrics" "HTTP/8080 /metrics"
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
            element "Sidecar" {
                background #e8a838
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
