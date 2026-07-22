workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs AI/ML pipelines for training, evaluation, and deployment"
        platformAdmin = person "Platform Admin" "Configures DSPO and manages pipeline infrastructure"

        pipelinesComponents = softwareSystem "pipelines-components" "Reusable KFP v2 pipeline components and pre-composed pipelines for AI/ML workflows" {
            kfpLibrary = container "kfp-components" "Python library of KFP v2 components covering training, evaluation, data processing, and deployment" "Python Library"
            initContainer = container "odh-pipelines-components" "Init container that compiles and stages managed pipeline YAMLs for KFP API server registration" "Init Container (UBI9 Python 3.12)"
            automlImage = container "odh-automl" "Runtime image with AutoGluon for tabular and timeseries AutoML training" "Runtime Container (AIPCC CPU)"
            autoragImage = container "odh-autorag" "Runtime image with ai4rag and Docling for AutoRAG optimization and document processing" "Runtime Container (AIPCC CPU)"
        }

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys and manages KFP infrastructure" "Internal RHOAI"
        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server for pipeline management" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        trainingHub = softwareSystem "Training Hub" "Distributed training job management" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata and lineage storage" "Internal RHOAI"
        milvus = softwareSystem "Milvus" "Vector database for RAG embedding storage" "Internal RHOAI"
        ray = softwareSystem "Ray / CodeFlare" "Distributed computing framework for data processing" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Resource queue management for workloads" "Internal RHOAI"
        evalHub = softwareSystem "Eval Hub" "External model evaluation and benchmarking service" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "ML experiment tracking" "Internal RHOAI"

        s3 = softwareSystem "S3 / MinIO" "Object storage for datasets, models, and artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        ogx = softwareSystem "OGX API" "OpenDataHub Extension for vector store and RAG operations" "External"
        rhelPyPI = softwareSystem "RHEL AI PyPI" "Python package index for RHOAI builds" "External Build-Time"
        modelcarRegistry = softwareSystem "RHAI Modelcar Images" "OCI registry for Docling model artifacts" "External Build-Time"

        # Relationships - User interactions
        dataScientist -> pipelinesComponents "Triggers AI/ML pipelines via KFP UI/SDK"
        platformAdmin -> dspo "Configures pipeline infrastructure"

        # Relationships - Internal platform
        dspo -> initContainer "Deploys as init container sidecar"
        initContainer -> kfpServer "Stages compiled pipeline YAMLs via shared PVC" "Filesystem"
        kfpLibrary -> kserve "Creates InferenceServices for model deployment/evaluation" "HTTPS/6443 via K8s API"
        kfpLibrary -> trainingHub "Submits distributed training jobs" "HTTPS/6443 via K8s API"
        kfpLibrary -> modelRegistry "Registers models with lineage metadata" "HTTP/8080"
        kfpLibrary -> milvus "Ingests vector embeddings" "gRPC/19530"
        kfpLibrary -> ray "Submits distributed processing jobs" "HTTPS/6443 via K8s API"
        kfpLibrary -> kueue "Resource queue management" "HTTPS/6443 via K8s API"
        kfpLibrary -> evalHub "Submits evaluation benchmarks" "HTTPS/443"
        kfpLibrary -> mlflow "Tracks experiment results (optional)" "HTTP/5000"

        # Relationships - External services
        kfpLibrary -> s3 "Reads/writes datasets, models, artifacts" "HTTPS/443 AWS SigV4"
        kfpLibrary -> huggingface "Downloads models and datasets" "HTTPS/443 Bearer"
        kfpLibrary -> ogx "Vector store and RAG optimization" "HTTPS/443 API Key"

        # Build-time relationships
        automlImage -> rhelPyPI "Installs Python dependencies (build-time)" "HTTPS/443"
        autoragImage -> rhelPyPI "Installs Python dependencies (build-time)" "HTTPS/443"
        autoragImage -> modelcarRegistry "Copies Docling model artifacts (build-time)" "HTTPS/443 OCI"

        # Runtime image usage
        kfpLibrary -> automlImage "Uses as base_image for AutoML components"
        kfpLibrary -> autoragImage "Uses as base_image for AutoRAG components"
    }

    views {
        systemContext pipelinesComponents "SystemContext" {
            include *
            autoLayout
        }

        container pipelinesComponents "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Build-Time" {
                background #cccccc
                color #333333
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
