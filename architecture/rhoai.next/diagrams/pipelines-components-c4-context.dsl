workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines for training, evaluation, and deployment"
        mlEngineer = person "ML Engineer" "Builds reusable pipeline components and manages pipeline images"

        pipelinesComponents = softwareSystem "Pipelines Components" "Centralized library of reusable KFP v2 components and pre-composed ML pipelines for RHOAI" {
            kfpLibrary = container "kfp-components" "Installable Python package providing reusable KFP v2 components and pipelines" "Python Library"
            initContainer = container "odh-pipelines-components" "Compiles managed pipeline YAMLs at build time, stages them to shared volume at runtime" "Init Container"
            automlImage = container "odh-automl" "Runtime image with AutoGluon for tabular/timeseries AutoML pipeline steps" "Container Image"
            autoragImage = container "odh-autorag" "Runtime image with ai4rag, docling, OGX for RAG optimization pipeline steps" "Container Image"
            genManagedPipelines = container "generate_managed_pipelines" "Discovers managed pipelines, compiles via KFP compiler, generates manifest" "Build Script"
            initManagedPipelines = container "init_managed_pipelines" "Copies pre-compiled pipeline YAMLs and manifest to shared volume" "Init Script"
        }

        kfpApiServer = softwareSystem "Kubeflow Pipelines API Server" "Orchestrates pipeline execution, reads managed pipeline specs" "Internal RHOAI"
        kfpSdk = softwareSystem "Kubeflow Pipelines SDK (kfp)" "Pipeline compilation, component decorator, artifact management" "External Library"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "Orchestrates distributed fine-tuning jobs on GPU nodes via TrainJob CRD" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata and provenance" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for training data, model artifacts, documents (MinIO / Ceph / AWS S3)" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Pre-trained models and datasets repository" "External"
        ogxApi = softwareSystem "OGX API (RHOAI)" "OpenShift GenAI eXtensions for embedding, vector store, and generation" "External"
        milvus = softwareSystem "Milvus" "Vector database for document embedding storage and retrieval" "External"
        llmProvider = softwareSystem "LLM Provider (via LiteLLM)" "Language model API for synthetic data generation and evaluation" "External"
        kubernetesApi = softwareSystem "Kubernetes API" "Manages Secrets, ConfigMaps, PVCs, and workload scheduling" "Infrastructure"

        # User interactions
        dataScientist -> pipelinesComponents "Runs ML pipelines (fine-tuning, AutoML, AutoRAG, SDG) via KFP UI or SDK"
        mlEngineer -> pipelinesComponents "Develops and packages reusable KFP components"

        # Init container delivers to KFP API Server
        pipelinesComponents -> kfpApiServer "Delivers compiled pipeline YAMLs via init container shared volume" "Filesystem"
        pipelinesComponents -> kfpSdk "Uses for pipeline/component definition and compilation" "Python Import"

        # Training and deployment
        pipelinesComponents -> kubeflowTrainer "Creates TrainJob CRDs for distributed fine-tuning" "Kubernetes API"
        pipelinesComponents -> modelRegistry "Registers trained models with provenance metadata" "HTTP/8080"

        # External data sources
        pipelinesComponents -> s3Storage "Loads/stores training data, model artifacts, documents" "HTTPS/443"
        pipelinesComponents -> huggingfaceHub "Downloads pre-trained models and datasets" "HTTPS/443"

        # RAG-specific
        pipelinesComponents -> ogxApi "Accesses embedding models, vector stores, generation models" "HTTPS/443"
        ogxApi -> milvus "Persists and queries document embeddings" "gRPC/19530"

        # SDG
        pipelinesComponents -> llmProvider "Generates synthetic data and evaluates RAG patterns" "HTTPS/443"

        # Infrastructure
        pipelinesComponents -> kubernetesApi "Reads Secrets, ConfigMaps, mounts PVCs" "HTTPS/6443"
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
            element "External Library" {
                background #bbbbbb
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #e8a820
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Container Image" {
                background #f5a623
                color #333333
            }
            element "Init Container" {
                background #4a90e2
                color #ffffff
            }
            element "Build Script" {
                background #82b366
                color #ffffff
            }
            element "Init Script" {
                background #82b366
                color #ffffff
            }
            element "Python Library" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
