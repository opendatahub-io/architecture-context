workspace {
    model {
        user = person "Data Scientist" "Deploys AutoGluon models as InferenceServices (modelFormat: autogluon)"
        client = person "Inference Client" "Sends tabular predictions and time-series forecast requests"

        autogluonServer = softwareSystem "kserve-autogluon-server" "KServe model-serving runtime for AutoGluon TabularPredictor and TimeSeriesPredictor models (quay.io/rhoai/odh-kserve-autogluon-server-rhel9)" {
            entrypoint = container "autogluonserver entrypoint" "Parses args, prepares writable runtime paths, loads the model, starts ModelServer" "Python 3.12"
            detector = container "AutoGluonDetectedModel" "Detects time-series vs tabular by trying to load each; checks AutoGluon version compatibility" "Python"
            tabular = container "AutoGluonTabularModel" "REST v1/v2 and gRPC v2 tabular inference; predict or predict_proba" "Python / AutoGluon"
            timeseries = container "AutoGluonTimeSeriesModel" "REST v1 JSON forecasts (mean plus quantiles)" "Python / AutoGluon"
            repository = container "AutoGluonModelRepository" "Multi-model fallback, one model per subdirectory of --model_dir" "Python"
            sdk = container "KServe Python SDK" "FastAPI/uvicorn REST on 8080, gRPC v2 on 8081, Prometheus metrics" "Python library"
            storage = container "kserve-storage" "Downloads models from S3, GCS, Azure, HDFS, HTTP(S), Git" "Python library"
        }

        kserve = softwareSystem "KServe Controller" "Reconciles InferenceServices into predictor pods; ships CRDs (separate RHOAI kserve component)" "Internal RHOAI"
        storageInit = softwareSystem "KServe storage-initializer" "Init container that populates /mnt/models from storageUri" "Internal RHOAI"
        odhModelController = softwareSystem "odh-model-controller / Gateway" "Exposes predictors and applies platform auth (inferred)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "User-workload monitoring" "Internal RHOAI"
        aipcc = softwareSystem "AIPCC base-image-cpu-rhel9" "Python 3.12 / RHEL 9.8 base image and RHEL AI PyPI" "Internal RHOAI"
        konflux = softwareSystem "Konflux (konflux-central)" "Multi-arch hermetic image build" "Internal RHOAI"
        objectStorage = softwareSystem "Object Storage" "S3-compatible, GCS, Azure Blob/File model artifact storage" "External"

        user -> kserve "Creates InferenceService" "kubectl / Dashboard"
        kserve -> autogluonServer "Selects ClusterServingRuntime kserve-autogluonserver and creates predictor pods" "Kubernetes API"
        storageInit -> objectStorage "Downloads model artifacts" "HTTPS/443 TLS"
        storageInit -> autogluonServer "Provides model files via /mnt/models" "Shared volume"
        client -> odhModelController "Sends inference requests" "HTTPS/443"
        odhModelController -> autogluonServer "Forwards inference requests" "HTTP/8080"
        prometheus -> autogluonServer "Scrapes /metrics" "HTTP/8080"
        autogluonServer -> objectStorage "Downloads model directly when model_dir is remote (optional)" "HTTPS/443 TLS"
        autogluonServer -> aipcc "Built on" "Container base image"
        konflux -> autogluonServer "Builds image (x86_64, ppc64le, s390x, arm64)" "Tekton"

        entrypoint -> detector "Loads model"
        entrypoint -> repository "Falls back to on ModelMissingError"
        entrypoint -> sdk "Starts ModelServer"
        detector -> storage "Storage.download"
        detector -> timeseries "Tries TimeSeriesPredictor.load first"
        detector -> tabular "Falls back to TabularPredictor.load"
        sdk -> detector "Dispatches predict and metadata calls"
        storage -> objectStorage "Remote download" "HTTPS/443"
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
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                shape Person
            }
        }
    }
}
