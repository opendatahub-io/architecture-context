workspace {
    model {
        dataScientist = person "Data Scientist" "Creates InferenceService CRs and sends inference requests to deployed models"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Python inference runtime serving AutoGluon TabularPredictor and TimeSeriesPredictor models via KServe REST v1/v2 protocol" {
            serverMain = container "AutoGluon Server" "Entry point, model loading, request routing" "Python / uvicorn + fastapi"
            detectedModel = container "AutoGluonDetectedModel" "Strategy facade that auto-detects predictor type (tabular vs time series)" "Python"
            tabularModel = container "AutoGluonTabularModel" "Serves tabular predictions via v1 JSON and v2 tensor protocol, supports predict_proba" "Python / AutoGluon"
            timeseriesModel = container "AutoGluonTimeSeriesModel" "Serves time series forecasts via v1 JSON protocol" "Python / AutoGluon"
            versionCompat = container "Version Compatibility" "Handles version mismatch between upstream and downstream AutoGluon builds" "Python"
        }

        kserveSDK = softwareSystem "KServe SDK" "Model serving framework providing ModelServer, Model base class, and inference protocol handling" "Vendored Library"
        kserveStorage = softwareSystem "KServe Storage" "Model download handler supporting S3, GCS, Azure Blob, HuggingFace Hub" "Vendored Library"
        kserveController = softwareSystem "KServe Controller" "Kubernetes operator managing InferenceService lifecycle, pod creation, and sidecar injection" "Internal Platform"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Auth enforcement sidecar (TLS termination + Bearer Token validation) injected by KServe Controller" "Internal Platform"

        s3 = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts (AWS S3, MinIO, etc.)" "External"
        gcs = softwareSystem "Google Cloud Storage" "GCP object storage for model artifacts" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Azure object storage for model artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for downloading pretrained models" "External"
        rhelPyPI = softwareSystem "RHEL AI Python Package Index" "Red Hat secure Python package index for build-time dependency resolution" "External"

        dataScientist -> autogluonServer "Sends inference requests (POST /v1/models/{name}:predict, /v2/models/{name}/infer)" "HTTPS/8443 via kube-rbac-proxy"
        dataScientist -> kserveController "Creates InferenceService CR with modelFormat: autogluon" "kubectl / API"

        autogluonServer -> kserveSDK "Uses for HTTP serving, inference protocol, and model lifecycle" "In-process"
        autogluonServer -> kserveStorage "Uses for model download from remote storage at startup" "In-process"
        autogluonServer -> s3 "Downloads model artifacts" "HTTPS/443, TLS 1.2+, AWS IAM"
        autogluonServer -> gcs "Downloads model artifacts" "HTTPS/443, TLS 1.2+, GCP SA"
        autogluonServer -> azureBlob "Downloads model artifacts" "HTTPS/443, TLS 1.2+, Azure creds"
        autogluonServer -> huggingface "Downloads model artifacts" "HTTPS/443, TLS 1.2+, HF Token"

        kserveController -> autogluonServer "Creates pods, injects kube-rbac-proxy sidecar, sets storage env vars"
        kubeRbacProxy -> autogluonServer "Proxies authenticated requests" "HTTP/8080 (pod-internal, plaintext)"
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
                background #4a90e2
                color #ffffff
            }
            element "Vendored Library" {
                background #9c27b0
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
