workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines for training, evaluation, and deployment"
        platformOp = person "Platform Operator" "Deploys and configures RHOAI platform components"

        pipelinesComponents = softwareSystem "Pipelines Components" "Reusable KFP pipeline components and managed pipeline definitions for AI/ML workflows" {
            initContainer = container "pipelines-components Init Container" "Pre-compiles managed pipelines at build time, stages them for KFP API Server at pod startup" "Python 3.12, UBI9"
            kfpComponentsLib = container "kfp-components Library" "Reusable KFP component definitions: data processing, training, evaluation, deployment" "Python Package"
            automlImage = container "odh-automl Runtime" "AutoGluon-based AutoML training environment for tabular and time-series pipelines" "Python 3.12, AIPCC CPU"
            autoragImage = container "odh-autorag Runtime" "RAG optimization environment with Docling, LangChain, ai4rag" "Python 3.12, AIPCC CPU"
            buildToolchain = container "Build & Validation Toolchain" "Compilation checks, metadata validation, base image validation, skeleton scaffolding" "Python CLI Scripts"
        }

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Manages deployment of KFP control plane including init containers" "Internal RHOAI"
        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server that reads and serves managed pipelines" "Internal RHOAI"
        kfpOrchestrator = softwareSystem "KFP Orchestrator" "Orchestrates pipeline step execution as Kubernetes pods" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform for model serving" "Internal RHOAI"
        trainingHub = softwareSystem "Training Hub" "Distributed training via ClusterTrainingRuntime CRDs" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores trained model metadata" "Internal RHOAI"
        evalHub = softwareSystem "Eval Hub" "External model evaluation benchmarking service" "Internal RHOAI"

        s3 = softwareSystem "S3-compatible Storage" "Object storage for datasets and model artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        ogxApi = softwareSystem "OGX API" "Embedding generation and indexing service" "External"
        milvus = softwareSystem "Milvus" "Vector database for RAG pipelines" "External"
        litellm = softwareSystem "LiteLLM / SDG Hub" "LLM provider for synthetic data generation" "External"

        # Relationships
        platformOp -> dspo "Configures DSPO deployment"
        dataScientist -> kfpServer "Submits pipeline runs via UI/CLI"

        dspo -> initContainer "Deploys as init container in KFP API server pod"
        initContainer -> kfpServer "Stages compiled pipeline YAMLs via shared volume" "Filesystem"
        kfpOrchestrator -> kfpComponentsLib "Executes pipeline steps using component definitions"

        kfpComponentsLib -> automlImage "Uses as base_image for AutoML pipeline steps"
        kfpComponentsLib -> autoragImage "Uses as base_image for AutoRAG pipeline steps"

        automlImage -> s3 "Downloads training data, uploads model artifacts" "HTTPS/443"
        automlImage -> modelRegistry "Registers trained models (optional)" "HTTP/8080"

        autoragImage -> s3 "Loads documents and test data" "HTTPS/443"
        autoragImage -> ogxApi "Generates embeddings, performs indexing" "HTTPS/443"
        autoragImage -> milvus "Stores and queries vector embeddings" "gRPC/19530"

        kfpComponentsLib -> kserve "Creates/queries InferenceService for evaluation and RAG" "HTTP/80, HTTPS/443"
        kfpComponentsLib -> trainingHub "Submits distributed training jobs via ClusterTrainingRuntime" "K8s API"
        kfpComponentsLib -> modelRegistry "Registers trained models" "HTTP/8080"
        kfpComponentsLib -> evalHub "Evaluates models via benchmarking service" "HTTPS/443"
        kfpComponentsLib -> s3 "Downloads datasets, uploads model artifacts" "HTTPS/443"
        kfpComponentsLib -> huggingface "Downloads models and datasets" "HTTPS/443"
        kfpComponentsLib -> litellm "Generates synthetic data via LLM" "HTTPS/443"
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
