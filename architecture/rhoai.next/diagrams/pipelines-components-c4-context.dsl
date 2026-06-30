workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines for fine-tuning, AutoML, and RAG optimization"
        mlEngineer = person "ML Engineer" "Deploys trained models and manages pipeline infrastructure"
        admin = person "Platform Admin" "Manages DSPO, secrets, and cluster configuration"

        pipelinesComponents = softwareSystem "Pipelines Components" "Reusable KFP component library and managed pipelines for ML workflows on RHOAI" {
            kfpLibrary = container "kfp-components" "Python wheel with reusable KFP v2 component and pipeline definitions" "Python Library"
            initContainer = container "odh-pipelines-components" "Init container that compiles managed pipeline YAMLs and stages them for KFP API server" "Init Container (UBI9 Python 3.12)"
            automlImage = container "odh-automl" "Runtime image with AutoGluon for tabular/timeseries ML tasks" "Container Image (AIPCC CPU)"
            autoragImage = container "odh-autorag" "Runtime image with AI4RAG, Docling, OGX client for RAG optimization" "Container Image (AIPCC CPU)"
            managedPipelinesGen = container "Managed Pipelines Generator" "Discovers and compiles managed pipeline definitions to YAML" "Python Script"
        }

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Deploys and manages KFP API server, consumes managed pipeline manifests" "Internal RHOAI"
        kfpAPI = softwareSystem "KFP API Server" "Kubeflow Pipelines API for pipeline registration and execution" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Kubeflow Model Registry for trained model metadata and provenance" "Internal RHOAI"
        rayOperator = softwareSystem "Ray Operator" "Distributed computing operator for PDF processing via RayJob CRDs" "Internal RHOAI"
        evalHub = softwareSystem "Eval Hub" "External evaluation service for KServe-deployed model benchmarking" "Internal RHOAI"
        milvus = softwareSystem "Milvus" "Vector database for RAG document embedding storage" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "Training job orchestrator via ClusterTrainingRuntime CRDs" "Internal RHOAI"

        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for training data, model artifacts, documents (MinIO/AWS)" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model and dataset repository" "External"
        ogxAPI = softwareSystem "OGX API" "Foundation model, embedding, and vector store API service" "External"
        liteLLM = softwareSystem "LLM Endpoint (LiteLLM)" "LLM API for synthetic data generation" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD CRUD operations" "Infrastructure"
        rhelAIPyPI = softwareSystem "RHEL AI PyPI" "Red Hat managed Python package index for secure builds" "External"

        # User interactions
        dataScientist -> pipelinesComponents "Creates and runs ML pipelines via KFP SDK"
        mlEngineer -> pipelinesComponents "Configures model deployment components"
        admin -> dspo "Deploys and configures pipeline infrastructure"

        # Init container flow
        initContainer -> kfpAPI "Provides compiled pipeline YAML via shared volume" "Filesystem (emptyDir)"
        dspo -> kfpAPI "Deploys and manages"
        dspo -> initContainer "Runs as init container for KFP API pod"

        # Component library interactions
        kfpLibrary -> kserve "Creates InferenceService & ServingRuntime CRDs" "HTTPS/443"
        kfpLibrary -> modelRegistry "Registers trained models with provenance" "HTTP/80 (plaintext)"
        kfpLibrary -> rayOperator "Submits RayJob CRDs for distributed processing" "HTTPS/443"
        kfpLibrary -> evalHub "Submits evaluation jobs, polls results" "HTTPS/443"
        kfpLibrary -> milvus "Inserts vector embeddings for RAG search" "gRPC/19530"
        kfpLibrary -> kubeflowTrainer "Submits training jobs via TrainerClient" "HTTPS/443"

        # External data dependencies
        pipelinesComponents -> s3Storage "Reads/writes training data, model artifacts" "HTTPS/443 (AWS IAM)"
        pipelinesComponents -> huggingFaceHub "Downloads pre-trained models and datasets" "HTTPS/443 (Bearer)"
        pipelinesComponents -> ogxAPI "Embedding generation, vector store, LLM inference" "HTTPS/443 (API Key)"
        pipelinesComponents -> liteLLM "Synthetic data generation" "HTTPS/443 (API Key)"
        pipelinesComponents -> k8sAPI "CRD CRUD, namespace lookups" "HTTPS/443 (SA Token)"

        # Build-time dependency
        automlImage -> rhelAIPyPI "Installs Python packages during build" "HTTPS/443"
        autoragImage -> rhelAIPyPI "Installs Python packages during build" "HTTPS/443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}
