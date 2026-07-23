workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines for fine-tuning, AutoML, AutoRAG, and model deployment"

        pipelinesComponents = softwareSystem "Pipelines Components" "Centralized library of reusable KFP v2 components and managed pipelines for AI/ML workflows" {
            initContainer = container "Init Container" "Compiles Python pipeline definitions to KFP YAML and stages to shared volume" "Python 3.12 Init Container"
            kfpLibrary = container "KFP Components Library" "Reusable @dsl.component functions organized by category: data processing, training, evaluation, deployment" "Python Library"
            automlRuntime = container "AutoML Runtime" "AutoGluon tabular and time series model training components" "Python 3.12 Container (AIPCC CPU base)"
            autoragRuntime = container "AutoRAG Runtime" "Automated RAG pipeline with Docling text extraction and ai4rag optimization" "Python 3.12 Container (AIPCC CPU base)"
            sharedUtils = container "Shared Fine-Tuning Utils" "Common data, training, setup, and output modules for LoRA/OSFT/SFT" "Python modules"
        }

        kfpApiServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server - loads managed pipelines, orchestrates pipeline execution" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI Dashboard - provides UI for one-click pipeline execution" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform - manages InferenceService and ServingRuntime CRDs" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "Training job orchestration for LoRA, OSFT, SFT fine-tuning via TrainJob CRDs" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata and provenance tracking" "Internal RHOAI"
        evalHub = softwareSystem "Eval Hub" "Evaluation job submission and benchmark result collection" "Internal RHOAI"
        rayCodeFlare = softwareSystem "Ray / CodeFlare" "Distributed computing for PDF parsing via RayJob CRDs" "Internal RHOAI"
        milvus = softwareSystem "Milvus" "Vector database for RAG document ingestion" "Internal RHOAI"
        ogx = softwareSystem "OGX" "OpenShift Generative AI - LLM inference for RAG optimization" "Internal RHOAI"

        s3 = softwareSystem "S3/MinIO" "Object storage for training data, model artifacts, and chunk JSONL" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        litellm = softwareSystem "LiteLLM" "LLM API abstraction for synthetic data generation" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container and model image registry" "External"
        kubernetesApi = softwareSystem "Kubernetes API" "Cluster API server for CRD CRUD operations" "Infrastructure"

        # Relationships
        dataScientist -> rhoaiDashboard "Selects and runs managed pipelines via UI"
        rhoaiDashboard -> kfpApiServer "Submits pipeline runs"

        kfpApiServer -> pipelinesComponents "Loads managed pipeline YAMLs from init container, executes KFP task pods"

        pipelinesComponents -> kserve "Creates InferenceService/ServingRuntime CRDs for model deployment" "HTTPS/443"
        pipelinesComponents -> kubeflowTrainer "Submits TrainJob CRs for fine-tuning (LoRA/OSFT/SFT)" "HTTPS/443"
        pipelinesComponents -> modelRegistry "Registers trained model versions with provenance" "HTTP/8080 (insecure)"
        pipelinesComponents -> evalHub "Submits evaluation jobs, retrieves benchmark scores" "HTTPS/443"
        pipelinesComponents -> rayCodeFlare "Submits RayJob CRDs for distributed PDF parsing" "HTTPS/443"
        pipelinesComponents -> milvus "Inserts vectors for RAG ingestion" "gRPC/19530"
        pipelinesComponents -> ogx "LLM inference for RAG template optimization" "HTTPS/443"

        pipelinesComponents -> s3 "Reads training data, writes model artifacts" "HTTPS/443, HTTP/9000"
        pipelinesComponents -> huggingface "Downloads models and datasets" "HTTPS/443"
        pipelinesComponents -> litellm "LLM API for synthetic data generation" "HTTPS/443"
        pipelinesComponents -> ociRegistry "Pulls OCI model images" "HTTPS/443"
        pipelinesComponents -> kubernetesApi "KServe CRD CRUD, RayJob submission, namespace discovery" "HTTPS/443"
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
