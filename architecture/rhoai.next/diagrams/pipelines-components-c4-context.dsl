workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs AI/ML pipelines for training, evaluation, and deployment"

        pipelinesComponents = softwareSystem "Pipelines Components" "Reusable KFP component library and managed pipeline staging for RHOAI" {
            initContainer = container "odh-pipelines-components" "Compiles managed pipeline definitions to YAML and stages to shared volume at startup" "Python Init Container (UBI9/python-311)"
            kfpLibrary = container "kfp-components" "Python package of 25+ reusable KFP components organized by category" "Python Library"
            automlImage = container "odh-automl" "Runtime image with AutoGluon for tabular/timeseries ML training" "Container Image (base-image-cpu-rhel9)"
            autoragImage = container "odh-autorag" "Runtime image with ai4rag, Docling, Llama Stack for RAG optimization" "Container Image (base-image-cpu-rhel9)"
        }

        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines orchestration server" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Model versioning and metadata storage" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "ClusterTrainingRuntime for distributed training jobs" "Internal RHOAI"
        rhoaiConnections = softwareSystem "RHOAI Connections API" "Kubernetes Secrets for credential injection" "Internal RHOAI"
        llamaStack = softwareSystem "Llama Stack" "Vector store and inference API for RAG workflows" "Internal RHOAI"

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Platform"
        s3 = softwareSystem "AWS S3" "Object storage for datasets and model artifacts" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Public model and dataset repository" "External"
        llmAPI = softwareSystem "LLM API Endpoint" "OpenAI-compatible LLM inference service" "External"
        openaiCompat = softwareSystem "OpenAI-compatible Endpoints" "Chat and embedding model services for RAG" "External"

        # Relationships - User
        dataScientist -> kfpServer "Submits pipelines via UI/SDK"
        dataScientist -> pipelinesComponents "Uses KFP component library"

        # Relationships - Init Container
        initContainer -> kfpServer "Stages compiled YAML to /config/managed-pipelines" "Filesystem (shared volume)"

        # Relationships - KFP Library → Internal
        kfpLibrary -> modelRegistry "Registers models with metadata, provenance" "HTTP/8080 (plaintext, no auth)"
        kfpLibrary -> kubeflowTrainer "Submits TrainingJob CRs for LoRA/OSFT/SFT" "Kubernetes API"
        kfpLibrary -> k8sAPI "Training job submission, pod monitoring" "HTTPS/443 (SA Token)"
        kfpLibrary -> rhoaiConnections "Reads S3, HF, LLM credentials" "Kubernetes Secrets"
        kfpLibrary -> llamaStack "Vector store, embeddings, RAG inference" "HTTP/HTTPS (API key)"

        # Relationships - KFP Library → External
        kfpLibrary -> s3 "Dataset upload/download, document storage" "HTTPS/443 (AWS IAM)"
        kfpLibrary -> hfHub "Dataset and model downloads" "HTTPS/443 (Bearer Token)"
        kfpLibrary -> llmAPI "LLM inference for SDG" "HTTPS (API key)"
        kfpLibrary -> openaiCompat "Chat completions, embeddings for RAG" "HTTPS (Bearer Token)"

        # Relationships - Runtime Images
        automlImage -> s3 "Stream CSV data for tabular training" "HTTPS/443 (AWS IAM)"
        autoragImage -> llamaStack "Vector store indexing and inference" "HTTP/HTTPS (API key)"
        autoragImage -> s3 "Document discovery and download" "HTTPS/443 (AWS IAM)"
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
