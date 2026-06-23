workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines for training, evaluation, and deployment"
        mlops = person "MLOps Engineer" "Manages pipeline configurations and deployment strategies"

        pipelinesComponents = softwareSystem "Pipelines Components" "Reusable KFP v2 component library and managed pipeline init containers for AI/ML workflows on RHOAI" {
            initContainer = container "odh-pipelines-components" "Stages compiled managed pipeline YAMLs to shared volume at pod startup" "Python 3.12 / UBI9 Init Container"
            automlImage = container "odh-automl" "Runtime image with AutoGluon, PyTorch, scikit-learn for AutoML training" "Python 3.12 / AIPCC CPU Base"
            autoragImage = container "odh-autorag" "Runtime image with Docling, ai4rag, OGX for RAG optimization" "Python 3.12 / AIPCC CPU Base"
            kfpLibrary = container "kfp-components" "30+ reusable KFP v2 components for data processing, training, evaluation, deployment" "Python Library"
            dataProcessing = container "Data Processing Components" "dataset_download, download_model, parse_and_chunk, documents_discovery, text_extraction, ingest_to_milvus, sdg" "KFP Components"
            trainingComponents = container "Training Components" "LoRA, OSFT, SFT fine-tuning, AutoGluon tabular/timeseries, RAG optimization" "KFP Components"
            evaluationComponents = container "Evaluation Components" "lm-eval, Eval Hub evaluator, leaderboard evaluation" "KFP Components"
            deploymentComponents = container "Deployment Components" "model_deployment, deploy_embedding_model, kubeflow_model_registry" "KFP Components"
        }

        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server that executes pipeline workflows" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform (ServingRuntime, InferenceService)" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Kubeflow Model Registry for model metadata and provenance" "Internal RHOAI"
        evalHub = softwareSystem "Eval Hub" "Benchmark evaluation submission and result retrieval" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay Operator" "Ray cluster management for distributed processing" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "Distributed training runtime management" "Internal RHOAI"
        hardwareProfile = softwareSystem "HardwareProfile CRD" "GPU resource profile definitions" "Internal RHOAI"

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for CRD operations" "Infrastructure"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for mTLS and traffic management" "Infrastructure"

        s3 = softwareSystem "S3-Compatible Storage" "Object storage for datasets, documents, and model artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        ogx = softwareSystem "OGX API" "Vector store operations and embedding generation" "External"
        milvus = softwareSystem "Milvus" "Vector database for document ingestion" "External"
        llmApi = softwareSystem "LLM API" "OpenAI-compatible LLM backend for synthetic data generation" "External"
        wandb = softwareSystem "Weights & Biases" "Optional training metrics logging" "External"

        # User interactions
        datascientist -> pipelinesComponents "Defines and runs ML pipelines via KFP SDK"
        mlops -> pipelinesComponents "Configures managed pipelines and RELATED_IMAGE overrides"

        # Init container flow
        initContainer -> kfpServer "Stages pipeline YAMLs to shared volume" "Filesystem"

        # Runtime image usage
        automlImage -> trainingComponents "Provides base runtime for AutoML components" "Container Image"
        autoragImage -> dataProcessing "Provides base runtime for RAG components" "Container Image"

        # Internal RHOAI integrations
        pipelinesComponents -> kfpServer "Pipeline YAMLs staged at init" "Filesystem / Volume Mount"
        pipelinesComponents -> kserve "Creates/manages ServingRuntime and InferenceService CRDs" "HTTPS/6443 mTLS"
        pipelinesComponents -> modelRegistry "Registers models with training provenance" "HTTP/8080"
        pipelinesComponents -> evalHub "Submits evaluation benchmarks and retrieves results" "HTTPS/443"
        pipelinesComponents -> kuberay "Creates RayJob CRDs for distributed doc processing" "HTTPS/6443 mTLS"
        pipelinesComponents -> trainingOperator "Reads ClusterTrainingRuntime CRDs" "HTTPS/6443 mTLS"
        pipelinesComponents -> hardwareProfile "Reads GPU resource profiles" "HTTPS/6443 mTLS"

        # Infrastructure
        pipelinesComponents -> k8sApi "CRD CRUD operations" "HTTPS/6443 mTLS"

        # External egress
        pipelinesComponents -> s3 "Downloads/uploads datasets, documents, model artifacts" "HTTPS/443 TLS 1.2+"
        pipelinesComponents -> huggingface "Downloads models and datasets" "HTTPS/443 TLS 1.2+"
        pipelinesComponents -> ogx "Vector store operations and embedding generation" "HTTPS/443 TLS 1.2+"
        pipelinesComponents -> milvus "Ingests vectors for RAG document processing" "gRPC/19530 plaintext"
        pipelinesComponents -> llmApi "Synthetic data generation via LiteLLM" "HTTPS/443 TLS 1.2+"
        pipelinesComponents -> wandb "Optional training metrics logging" "HTTPS/443 TLS 1.2+"
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
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
