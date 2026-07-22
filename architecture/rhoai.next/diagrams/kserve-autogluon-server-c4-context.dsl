workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys AutoGluon ML models for tabular and time series prediction"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via KServe REST v1/v2 and gRPC inference protocols" {
            serverContainer = container "autogluonserver" "Auto-detects model type (tabular vs time series), translates between KServe inference protocols and AutoGluon pandas API" "Python 3.12, FastAPI, uvicorn"
            kserveSDK = container "kserve SDK" "Model server framework providing REST v1/v2 endpoints, gRPC server, health checks, model repository management" "Python Library (0.19.0)"
            kserveStorage = container "kserve-storage" "Downloads model artifacts from cloud object storage (S3, GCS, Azure, HF Hub)" "Python Library (0.19.0)"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar, terminates TLS, validates Bearer tokens" "Go Sidecar (injected by platform)"
        }

        kserveOperator = softwareSystem "KServe Operator" "Manages InferenceService lifecycle, deploys model serving pods, injects sidecars" "Internal RHOAI"
        clusterServingRuntime = softwareSystem "ClusterServingRuntime" "Defines runtime container spec (image, ports, model format) for autogluon" "Internal RHOAI"
        s3 = softwareSystem "S3 Object Storage" "Model artifact storage (AWS S3 or compatible)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage (GCP)" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage (Azure)" "External"
        hfHub = softwareSystem "Hugging Face Hub" "ML model repository" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        # Relationships - System Context
        dataScientist -> autogluonServer "Sends inference requests (tabular/time series)" "HTTPS/8443, Bearer Token"
        dataScientist -> kserveOperator "Creates InferenceService CR" "kubectl / API"
        kserveOperator -> autogluonServer "Deploys and manages pod" "InferenceService CRD"
        clusterServingRuntime -> kserveOperator "Defines autogluon runtime spec" "CRD reference"
        autogluonServer -> s3 "Downloads model artifacts at startup" "HTTPS/443, AWS IAM"
        autogluonServer -> gcs "Downloads model artifacts at startup" "HTTPS/443, GCP SA"
        autogluonServer -> azureBlob "Downloads model artifacts at startup" "HTTPS/443, Azure Identity"
        autogluonServer -> hfHub "Downloads model artifacts" "HTTPS/443, HF Token"
        prometheus -> autogluonServer "Scrapes inference metrics" "HTTP/8080"

        # Relationships - Container level
        dataScientist -> kubeRBACProxy "Inference request" "HTTPS/8443, TLS 1.3, Bearer Token"
        kubeRBACProxy -> serverContainer "Proxied request" "HTTP/8080, plaintext localhost"
        serverContainer -> kserveSDK "Protocol handling" "in-process"
        serverContainer -> kserveStorage "Model download" "in-process"
        kserveStorage -> s3 "Download artifacts" "HTTPS/443, boto3"
        kserveStorage -> gcs "Download artifacts" "HTTPS/443, google-cloud-storage"
        kserveStorage -> azureBlob "Download artifacts" "HTTPS/443, azure-storage-blob"
        kserveStorage -> hfHub "Download models" "HTTPS/443, huggingface-hub"
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
                shape RoundedBox
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
                background #4a90e2
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
