workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs AI/ML pipelines for model training, evaluation, and deployment on RHOAI"
        platformAdmin = person "Platform Admin" "Deploys and manages the RHOAI platform and pipeline infrastructure"

        pipelinesComponents = softwareSystem "pipelines-components" "Centralized library of reusable KFP components and managed pipelines for AI/ML workflows" {
            initContainer = container "odh-pipelines-components" "Compiles managed pipeline definitions to YAML and stages them for KFP API Server" "Python 3.11 Init Container" "UBI9"
            kfpLibrary = container "kfp-components" "Reusable KFP pipeline components: data processing, training, evaluation, deployment" "Python Library"
            automlImage = container "odh-automl" "Runtime image with AutoGluon for tabular/time-series AutoML components" "Container Image" "Runtime"
            autoragImage = container "odh-autorag" "Runtime image with ai4rag, Docling, Llama Stack for RAG optimization components" "Container Image" "Runtime"
        }

        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines server that serves and orchestrates pipeline runs" "Internal RHOAI"
        argoWorkflows = softwareSystem "Argo Workflows" "Workflow engine that executes pipeline steps as Kubernetes pods" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "Kubernetes-native distributed training operator (ClusterTrainingRuntime)" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Model versioning, metadata storage, and provenance tracking" "Internal RHOAI"
        llamaStack = softwareSystem "Llama Stack" "Vector store, embedding, and inference API for RAG workflows" "Internal/External"

        awsS3 = softwareSystem "AWS S3" "Object storage for datasets, documents, and model artifacts" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Public repository for ML datasets and pre-trained models" "External"
        llmEndpoints = softwareSystem "OpenAI-compatible LLM Endpoints" "Chat completion and embedding APIs for RAG optimization and SDG" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for TrainingJob submission, pod monitoring, namespace operations" "Infrastructure"

        rhoaiConnections = softwareSystem "RHOAI Connections" "Credential management for S3, HuggingFace, LLM, and Llama Stack secrets" "Internal RHOAI"

        # Relationships - User to system
        dataScientist -> kfpServer "Submits pipeline runs via UI/SDK"
        platformAdmin -> pipelinesComponents "Deploys init container with platform operator"

        # Relationships - Init container flow
        initContainer -> kfpServer "Stages compiled managed pipeline YAMLs via shared volume" "Filesystem"

        # Relationships - Pipeline execution
        kfpServer -> argoWorkflows "Creates Argo Workflows for pipeline execution"
        argoWorkflows -> kfpLibrary "Runs pipeline step components as pods"
        argoWorkflows -> automlImage "Uses as runtime image for AutoML steps"
        argoWorkflows -> autoragImage "Uses as runtime image for AutoRAG steps"

        # Relationships - External service egress
        kfpLibrary -> awsS3 "Uploads/downloads datasets, documents, model artifacts" "HTTPS/443, TLS 1.2+, AWS IAM"
        kfpLibrary -> huggingFace "Downloads datasets and pre-trained models" "HTTPS/443, TLS 1.2+, HF_TOKEN"
        kfpLibrary -> llmEndpoints "Chat completions and embeddings for RAG/SDG" "HTTPS, TLS 1.2+, API key"
        kfpLibrary -> llamaStack "Vector store CRUD, embeddings, inference for RAG" "HTTP(S), API key"
        kfpLibrary -> kubernetesAPI "Submits TrainingJob CRs, monitors pods" "HTTPS/443, TLS 1.2+, SA token"
        kfpLibrary -> modelRegistry "Registers trained models with metadata" "HTTP/8080, plaintext, no auth"

        # Relationships - Internal platform
        kubeflowTrainer -> kubernetesAPI "Creates and manages training worker pods"
        rhoaiConnections -> kfpLibrary "Injects S3, HF, LLM, Llama Stack credentials as env vars" "Kubernetes Secrets"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal/External" {
                background #b8a042
                color #ffffff
            }
            element "Infrastructure" {
                background #d45d3c
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Runtime" {
                background #f5a623
                color #ffffff
            }
            element "UBI9" {
                background #4a90e2
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
