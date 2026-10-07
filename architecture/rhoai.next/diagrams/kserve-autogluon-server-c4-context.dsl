workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, trains, and deploys AutoGluon ML models for tabular and time series prediction"

        autogluonServer = softwareSystem "KServe AutoGluon Server" "Serves AutoGluon TabularPredictor and TimeSeriesPredictor models via KServe v1/v2 inference protocols" {
            mainEntrypoint = container "Entrypoint (__main__.py)" "Parses args, ensures runtime paths, starts ModelServer" "Python"
            predictorFactory = container "Predictor Factory" "Auto-detects TabularPredictor vs TimeSeriesPredictor at load time" "Python"
            tabularModel = container "AutoGluonTabularModel" "v1 JSON + v2 tensor inference for classification, regression, quantile" "Python (kserve.Model)"
            timeSeriesModel = container "AutoGluonTimeSeriesModel" "v1 JSON inference for time series forecasting" "Python (kserve.Model)"
            modelRepository = container "AutoGluonModelRepository" "Multi-model directory scanner for shared mount" "Python (ModelRepository)"
            versionCompat = container "version_compat" "Tolerates patch-level AutoGluon version mismatches" "Python"
            runtimePaths = container "runtime_paths" "Ensures writable cwd and matplotlib config in containers" "Python"
        }

        kserveOperator = softwareSystem "KServe Operator" "Manages InferenceService CRDs and provisions serving pods" "Internal RHOAI"
        kserveStorageInit = softwareSystem "KServe Storage Initializer" "Downloads model artifacts from storage backends" "Internal RHOAI"
        kserveDataPlane = softwareSystem "KServe Data Plane" "Istio/Knative/Gateway for ingress, TLS, auth" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        modelStorage = softwareSystem "Model Storage" "S3, GCS, Azure Blob, or PVC for model artifacts" "External"

        dataScientist -> autogluonServer "Sends inference requests via KServe data plane" "HTTP REST / gRPC"
        dataScientist -> kserveOperator "Creates InferenceService CR" "kubectl / API"

        kserveOperator -> autogluonServer "Provisions InferenceService pod with autogluon container" "Kubernetes API"
        kserveStorageInit -> modelStorage "Downloads model artifacts" "HTTPS/443"
        kserveStorageInit -> autogluonServer "Provides models via shared volume /mnt/models" "Filesystem"
        kserveDataPlane -> autogluonServer "Routes inference requests" "HTTP/8080, gRPC/8081"
        prometheus -> autogluonServer "Scrapes metrics" "HTTP/8080 GET /metrics"
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
                shape person
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
