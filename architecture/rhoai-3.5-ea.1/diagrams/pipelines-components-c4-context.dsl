workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines for fine-tuning, AutoML, AutoRAG, and synthetic data generation"
        mlEngineer = person "ML Engineer" "Develops and maintains reusable KFP pipeline components"

        pipelinesComponents = softwareSystem "Pipelines Components" "Reusable KFP pipeline components and managed pipeline library for AI/ML workflows" {
            initContainer = container "odh-pipelines-components" "Init container that compiles and stages managed pipeline YAMLs into KFP API server shared volume" "Python 3.11 / Init Container"
            componentLibrary = container "KFP Component Library" "Reusable @dsl.component Python functions for data processing, training, evaluation, and deployment" "Python / KFP SDK v2"
            automlImage = container "odh-automl" "Pre-built runtime with AutoGluon 1.5.0 for tabular and time-series AutoML tasks" "Python / Container Image"
            autoragImage = container "odh-autorag" "Pre-built runtime with Docling, ai4rag, OGX client, LangChain for RAG optimization" "Python / Container Image"
            genManagedPipelines = container "generate_managed_pipelines" "Build-time script: discovers managed pipelines, validates metadata, compiles to YAML" "Python / Build Script"
        }

        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server that discovers and runs managed pipelines" "Internal RHOAI"
        trainingHub = softwareSystem "Kubeflow Training Hub" "Manages distributed training jobs via ClusterTrainingRuntime (Unsloth, mini-trainer, instructlab-training)" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores registered models with provenance metadata and training/evaluation metrics" "Internal RHOAI"
        ogx = softwareSystem "OGX (OpenShift Generative eXperience)" "Foundation model inference, embedding models, Responses API for RAG optimization" "Internal RHOAI"
        rhoaiConnections = softwareSystem "RHOAI Connections API" "Credential and configuration management via Kubernetes Secrets" "Internal RHOAI"

        s3 = softwareSystem "AWS S3" "Object storage for datasets, documents, and model artifacts" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model and dataset repository with gated access support" "External"
        milvus = softwareSystem "Milvus" "Vector database for RAG pattern indexing and retrieval" "External"
        litellm = softwareSystem "LiteLLM / LLM Provider" "Multi-provider LLM client abstraction for synthetic data generation" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Container and model artifact registry accessed via skopeo" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for training job submission and resource management" "Infrastructure"

        # User relationships
        dataScientist -> kfpServer "Submits pipeline runs" "kubectl / UI"
        mlEngineer -> componentLibrary "Develops pipeline components" "Python / KFP SDK"

        # Init container flow
        initContainer -> kfpServer "Stages compiled pipeline YAMLs to /config/managed-pipelines/" "Filesystem (shared volume)"
        genManagedPipelines -> initContainer "Compiles pipeline.py to pipeline.yaml" "Build-time"

        # Component library interactions
        componentLibrary -> s3 "Downloads datasets and documents" "HTTPS/443, AWS IAM"
        componentLibrary -> hfHub "Downloads models and datasets" "HTTPS/443, Bearer HF_TOKEN"
        componentLibrary -> k8sAPI "Submits training jobs via TrainerClient" "HTTPS/6443, Bearer Token"
        componentLibrary -> modelRegistry "Registers trained models with provenance" "HTTP/8080, No Auth"
        componentLibrary -> ogx "LLM inference, embeddings, RAG optimization" "HTTPS/443, Bearer Token"
        componentLibrary -> milvus "Vector indexing and retrieval" "HTTP/gRPC, Configurable"
        componentLibrary -> litellm "LLM access for synthetic data generation" "HTTPS/443, API Key"
        componentLibrary -> ociRegistry "Downloads pre-trained models via skopeo" "HTTPS/443, Docker config"
        componentLibrary -> rhoaiConnections "Retrieves credentials via Kubernetes Secrets" "K8s API"

        # Runtime images
        automlImage -> componentLibrary "Provides base_image for AutoML components" "Container Runtime"
        autoragImage -> componentLibrary "Provides base_image for AutoRAG components" "Container Runtime"

        # Platform interactions
        k8sAPI -> trainingHub "Manages ClusterTrainingRuntime jobs" "Internal"
        kfpServer -> componentLibrary "Executes pipeline components as task pods" "KFP Runtime"
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
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
