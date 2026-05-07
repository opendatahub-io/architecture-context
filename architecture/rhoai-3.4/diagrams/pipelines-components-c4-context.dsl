workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via RHOAI Dashboard"
        mlEngineer = person "ML Engineer" "Develops custom pipeline components and pipelines"

        pipelinesComponents = softwareSystem "Pipelines Components" "Reusable KFP pipeline components and managed pipelines for AI/ML workflows" {
            kfpComponentsLib = container "kfp-components Library" "Python package with @dsl.component and @dsl.pipeline definitions" "Python / KFP SDK"
            initContainer = container "odh-pipelines-components" "Init container that copies compiled managed pipeline YAMLs to shared volume" "Python / UBI9"
            automlRuntime = container "odh-automl Runtime" "Pre-built AutoGluon environment for AutoML pipeline steps" "Python / UBI9"
            autoragRuntime = container "odh-autorag Runtime" "Pre-built docling + ai4rag environment for RAG pipeline steps" "Python / UBI9"
            generateScript = container "generate_managed_pipelines" "Build-time script: discovers, validates, compiles managed pipelines to YAML" "Python Script"
            initScript = container "init_managed_pipelines" "Runtime entry point: copies pipeline YAMLs to /config/managed-pipelines/" "Python Script"
        }

        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server, discovers and exposes managed pipelines" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys KFP API server and init container, manages pipeline infrastructure" "Internal RHOAI"
        argoWorkflows = softwareSystem "Argo Workflows" "Executes compiled KFP pipelines as Argo workflow pods" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata and provenance" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "Orchestrates distributed training via TrainJob CRs" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for submitting and monitoring pipeline runs" "Internal RHOAI"

        s3Storage = softwareSystem "S3/MinIO Object Storage" "Stores training datasets, documents, and model artifacts" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Hosts pre-trained models and ML datasets" "External"
        llamaStack = softwareSystem "Llama Stack API" "Provides embeddings, vector I/O, and RAG responses" "External"
        liteLLM = softwareSystem "LiteLLM API" "Unified LLM gateway for synthetic data generation" "External"
        vllm = softwareSystem "vLLM" "LLM inference backend for model evaluation" "External"
        milvus = softwareSystem "Milvus" "Vector database for document indexing and similarity search" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for TrainJob CR management" "Platform"

        # Relationships
        dataScientist -> rhoaiDashboard "Submits pipeline runs via"
        mlEngineer -> kfpComponentsLib "Develops components using"
        rhoaiDashboard -> kfpServer "Triggers pipeline execution"

        dspo -> initContainer "Deploys as init container alongside KFP API server"
        initContainer -> kfpServer "Provides managed pipeline YAMLs via shared volume" "Filesystem"
        kfpServer -> argoWorkflows "Compiles pipelines to Argo Workflow specs"

        # Pipeline step egress
        pipelinesComponents -> s3Storage "Downloads datasets, documents; uploads artifacts" "HTTPS/443, AWS Sig V4"
        pipelinesComponents -> huggingFaceHub "Downloads pre-trained models and datasets" "HTTPS/443, Bearer Token"
        pipelinesComponents -> llamaStack "Generates embeddings, vector I/O, RAG responses" "HTTPS/443, API Key"
        pipelinesComponents -> liteLLM "Generates synthetic training data" "HTTPS/443, API Key"
        pipelinesComponents -> vllm "Runs LLM evaluation inference" "HTTP/8000"
        pipelinesComponents -> milvus "Indexes documents for similarity search" "gRPC/19530"
        pipelinesComponents -> modelRegistry "Registers trained models with provenance" "HTTP/8080"
        pipelinesComponents -> kubeflowTrainer "Creates TrainJob CRs for distributed training" "HTTPS/443"
        pipelinesComponents -> k8sAPI "Manages TrainJob CRs" "HTTPS/443, SA Token"
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
