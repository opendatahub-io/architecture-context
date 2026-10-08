workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys AutoGluon models via InferenceService CR and sends inference requests"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via KServe v1/v2 inference protocol" {
            modelServer = container "KServe ModelServer" "FastAPI/uvicorn HTTP server and gRPC server implementing KServe inference protocol" "Python (FastAPI)"
            detectedModel = container "AutoGluonDetectedModel" "Auto-detects model type (tabular vs time series) and delegates prediction" "Python (kserve.Model)"
            tabularModel = container "AutoGluonTabularModel" "Handles tabular predictions with v1 and v2 protocol support" "Python (kserve.Model)"
            timeSeriesModel = container "AutoGluonTimeSeriesModel" "Handles time series forecasts via v1 protocol" "Python (kserve.Model)"
            predictorDetect = container "predictor_detect" "Try-load detection of model type from saved artifacts" "Python"
            versionCompat = container "version_compat" "Patch-level version tolerance for model loading" "Python"
            runtimePaths = container "runtime_paths" "Ensures writable filesystem paths in non-root containers" "Python"
        }

        kserveOperator = softwareSystem "KServe Operator" "Manages InferenceService lifecycle, creates pods and services" "Internal RHOAI"
        storageInitializer = softwareSystem "KServe Storage Initializer" "Downloads model artifacts from cloud storage to pod filesystem" "Internal RHOAI"
        cloudStorage = softwareSystem "Cloud Storage" "S3, GCS, or Azure Blob storage for model artifacts" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh providing mTLS, traffic routing, and ingress" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"

        # External relationships
        dataScientist -> autogluonServer "Sends inference requests" "HTTPS/443 via gateway"
        dataScientist -> kserveOperator "Creates InferenceService CR" "kubectl / HTTPS"

        # Internal relationships
        kserveOperator -> autogluonServer "Manages pod lifecycle via ClusterServingRuntime" "Kubernetes API"
        storageInitializer -> cloudStorage "Downloads model artifacts" "HTTPS/443, Cloud IAM"
        storageInitializer -> autogluonServer "Provides model at /mnt/models" "Filesystem (init container)"
        autogluonServer -> cloudStorage "Model storage access (via storage initializer)" "HTTPS/443"
        istio -> autogluonServer "Routes traffic, provides mTLS" "HTTP/8080, mTLS"
        prometheus -> autogluonServer "Scrapes metrics" "HTTP/8080 GET /metrics"
        kserveOperator -> kubernetesAPI "Manages resources" "HTTPS/443"

        # Internal container relationships
        modelServer -> detectedModel "Routes inference requests"
        detectedModel -> predictorDetect "Detects model type at load"
        predictorDetect -> versionCompat "Validates version compatibility"
        detectedModel -> tabularModel "Delegates tabular predictions"
        detectedModel -> timeSeriesModel "Delegates time series predictions"
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
