workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs AI/ML pipelines for training, evaluation, and deployment"
        platformAdmin = person "Platform Admin" "Deploys and manages RHOAI platform"

        pipelinesComponents = softwareSystem "pipelines-components" "Reusable KFP component library and managed pipelines for AI/ML workflows on RHOAI" {
            initContainer = container "odh-pipelines-components" "Compiles managed pipeline definitions to YAML and stages to shared volume at startup" "Python Init Container"
            kfpLibrary = container "kfp-components" "Installable Python package of 25+ reusable KFP components organized by category" "Python Library"
            automlImage = container "odh-automl" "Runtime image with AutoGluon for tabular and time-series AutoML" "Container Image"
            autoragImage = container "odh-autorag" "Runtime image with ai4rag, Docling, and Llama Stack for RAG optimization" "Container Image"
            scripts = container "scripts" "Validation, scaffolding, and generation utilities for component/pipeline development" "Python Scripts"
        }

        kfpApiServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server that serves managed pipelines and orchestrates Argo Workflows" "Internal RHOAI"
        kubeflowModelRegistry = softwareSystem "Kubeflow Model Registry" "Model versioning, metadata storage, and provenance tracking" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native distributed training job submission and monitoring (ClusterTrainingRuntime)" "Internal RHOAI"
        rhoaiConnections = softwareSystem "RHOAI Connections API" "Platform-managed Kubernetes Secrets for service credentials" "Internal RHOAI"
        llamaStack = softwareSystem "Llama Stack" "Vector store indexing and inference API for RAG workflows" "Internal RHOAI"

        awsS3 = softwareSystem "AWS S3" "Data lake for datasets (CSV, JSON, documents) and model artifacts" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Public/gated dataset and model repository" "External"
        llmApi = softwareSystem "LLM API Endpoint" "OpenAI-compatible inference endpoints for chat and embeddings" "External"
        kubernetesApi = softwareSystem "Kubernetes API" "Cluster API for TrainingJob submission and pod management" "External"

        # Relationships - User interactions
        dataScientist -> kfpApiServer "Submits pipelines via KFP UI/SDK"
        platformAdmin -> pipelinesComponents "Deploys as part of RHOAI platform"

        # Relationships - Init container
        initContainer -> kfpApiServer "Stages compiled managed pipeline YAMLs to shared volume" "Filesystem"

        # Relationships - Component library interactions
        kfpLibrary -> awsS3 "Downloads/uploads datasets and model artifacts" "HTTPS/443"
        kfpLibrary -> huggingFaceHub "Downloads public/gated datasets and models" "HTTPS/443"
        kfpLibrary -> llamaStack "Vector store CRUD, embeddings, RAG inference" "HTTP/HTTPS"
        kfpLibrary -> llmApi "Chat completions and embeddings for SDG and RAG" "HTTPS"
        kfpLibrary -> kubeflowModelRegistry "Registers models with metadata and provenance" "HTTP/8080"
        kfpLibrary -> kubeflowTrainer "Submits distributed training jobs (LoRA/OSFT/SFT)" "HTTPS/443"
        kfpLibrary -> kubernetesApi "Training job submission, pod monitoring" "HTTPS/443"
        kfpLibrary -> rhoaiConnections "Reads service credentials from Kubernetes Secrets" "Kubernetes API"

        # Relationships - Runtime images
        automlImage -> awsS3 "Loads tabular/time-series data" "HTTPS/443"
        autoragImage -> awsS3 "Loads documents for RAG" "HTTPS/443"
        autoragImage -> llamaStack "Vector store and inference for RAG optimization" "HTTP/HTTPS"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
