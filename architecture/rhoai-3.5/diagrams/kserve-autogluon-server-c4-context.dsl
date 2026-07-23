workspace {
    model {
        dataScientist = person "Data Scientist" "Creates InferenceService CRs and sends inference requests to deployed AutoGluon models"
        mlEngineer = person "ML Engineer" "Trains AutoGluon TabularPredictor / TimeSeriesPredictor models and uploads artifacts to cloud storage"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Python inference server that serves AutoGluon TabularPredictor and TimeSeriesPredictor models via KServe v1/v2 inference protocols" {
            serverMain = container "autogluonserver" "Entry point, model type auto-detection (tabular vs time series), version compatibility checks, runtime path resolution" "Python 3.13"
            tabularModel = container "AutoGluonTabularModel" "Handles tabular classification, regression, quantile prediction via v1 REST + v2 Open Inference Protocol" "Python (AutoGluon 1.5.0+rhaiv.3)"
            timeSeriesModel = container "AutoGluonTimeSeriesModel" "Handles time series forecasting via v1 REST JSON protocol only" "Python (AutoGluon 1.5.0+rhaiv.3)"
            kserveSDK = container "KServe SDK" "Model server framework providing REST/gRPC transport, health checks, model repository management, Prometheus metrics" "Python (kserve 0.19.0)"
            kserveStorage = container "kserve-storage" "Downloads model artifacts from cloud storage (S3, GCS, Azure Blob, HuggingFace Hub) to local filesystem" "Python (kserve 0.19.0)"
        }

        kserveController = softwareSystem "KServe Controller" "Kubernetes operator that manages InferenceService lifecycle, creates pods, injects sidecars" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "TLS-terminating auth sidecar injected by KServe Controller for RHOAI platform RBAC enforcement" "Internal RHOAI"
        kubernetes = softwareSystem "Kubernetes API" "Cluster API for pod lifecycle, health probes, resource management" "Platform"

        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, Ceph)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Model artifact storage (GCS buckets)" "External"
        azureBlob = softwareSystem "Azure Blob Storage" "Model artifact storage (Azure containers)" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model artifact repository (public/private repos)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection for inference latency and request counts" "Internal RHOAI"

        # Relationships
        dataScientist -> autogluonServer "Sends inference requests via HTTPS/443 (Bearer Token)" "HTTPS"
        dataScientist -> kserveController "Creates InferenceService CRs via kubectl" "Kubernetes API"
        mlEngineer -> s3 "Uploads trained model artifacts" "HTTPS"
        mlEngineer -> gcs "Uploads trained model artifacts" "HTTPS"

        kserveController -> autogluonServer "Creates pods with autogluon-server image and kube-rbac-proxy sidecar" "Kubernetes API"
        kubeRBACProxy -> autogluonServer "Proxies authenticated requests to server on localhost:8080" "HTTP"

        autogluonServer -> s3 "Downloads model artifacts at startup" "HTTPS/443 TLS 1.2+ IAM"
        autogluonServer -> gcs "Downloads model artifacts at startup" "HTTPS/443 TLS 1.2+ GCP SA"
        autogluonServer -> azureBlob "Downloads model artifacts at startup" "HTTPS/443 TLS 1.2+ Azure Creds"
        autogluonServer -> huggingFace "Downloads model artifacts at startup" "HTTPS/443 TLS 1.2+ HF Token"

        kubernetes -> autogluonServer "Health probes (readiness/liveness)" "HTTP/8080"
        prometheus -> autogluonServer "Scrapes inference metrics" "HTTP/8080"

        # Internal container relationships
        serverMain -> tabularModel "Delegates tabular predictions"
        serverMain -> timeSeriesModel "Delegates time series forecasts"
        serverMain -> kserveSDK "Registers as model server"
        tabularModel -> kserveSDK "Uses REST/gRPC transport"
        timeSeriesModel -> kserveSDK "Uses REST transport"
        kserveStorage -> s3 "Downloads via S3 protocol"
        kserveStorage -> gcs "Downloads via GCS API"
        kserveStorage -> azureBlob "Downloads via Azure API"
        kserveStorage -> huggingFace "Downloads via HF API"
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
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
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
