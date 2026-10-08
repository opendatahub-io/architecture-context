workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs AI/ML pipelines for fine-tuning, AutoML, and AutoRAG workflows"

        pipelinesComponents = softwareSystem "Pipelines Components" "Centralized library of reusable KFP components and managed pipeline definitions for AI/ML workflows in RHOAI" {
            kfpComponents = container "kfp-components" "Installable Python library of reusable KFP components and pipeline definitions (v1.11.0)" "Python Package"
            initContainer = container "init_managed_pipelines" "Stages pre-compiled managed pipeline YAMLs to shared volume for KFP API server; recompiles for air-gap when RELATED_IMAGE_* present" "Init Container"
            generatePipelines = container "generate_managed_pipelines" "Discovers, validates, and compiles managed pipelines into YAML + manifest JSON at build time" "Build-time CLI"
            automlImage = container "odh-automl" "Runtime image for AutoGluon tabular and time series training pipeline tasks" "AIPCC Container"
            autoragImage = container "odh-autorag" "Runtime image for document processing with embedded Docling OGX and Whisper modelcars" "AIPCC Container"
            autoragInfImage = container "odh-autorag-inference" "Placeholder image for deploying AutoRAG-generated agents for inference" "AIPCC Container"
        }

        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines backend that orchestrates pipeline execution" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages KFP deployment and injects RELATED_IMAGE_* env vars" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Manages model serving via ServingRuntime and InferenceService CRs" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata and provenance information" "Internal RHOAI"
        evalHub = softwareSystem "Eval Hub" "Evaluation service for submitting and polling AI model evaluation jobs" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "UI for managing data science projects and pipelines" "Internal RHOAI"
        hardwareProfile = softwareSystem "HardwareProfile CRD" "GPU/CPU hardware resource configuration" "Internal RHOAI"

        huggingface = softwareSystem "HuggingFace Hub" "Public/private model and dataset repository" "External"
        s3 = softwareSystem "S3 / MinIO" "Object storage for datasets, models, and artifacts" "External"
        milvus = softwareSystem "Milvus" "Vector database for RAG document indexing" "External"
        litellm = softwareSystem "LiteLLM" "LLM inference proxy for synthetic data generation" "External"
        rhoaiPyPI = softwareSystem "RHOAI PyPI Index" "Private Python package index for RHOAI dependencies" "External"

        dataScientist -> pipelinesComponents "Defines and runs AI/ML pipelines"
        dataScientist -> kfpServer "Submits pipeline runs via UI/CLI"

        pipelinesComponents -> kfpServer "Stages managed pipeline YAMLs via shared volume"
        dspo -> pipelinesComponents "Injects RELATED_IMAGE_* for air-gap support"
        pipelinesComponents -> kserve "Creates ServingRuntime + InferenceService CRs" "HTTPS/443"
        pipelinesComponents -> modelRegistry "Registers trained models" "HTTP/8080"
        pipelinesComponents -> evalHub "Submits evaluation jobs" "HTTPS"
        pipelinesComponents -> hardwareProfile "Reads GPU config" "HTTPS/443"
        dashboard -> pipelinesComponents "Matches opendatahub.io/* annotations"

        pipelinesComponents -> huggingface "Downloads datasets and models" "HTTPS/443"
        pipelinesComponents -> s3 "Uploads/downloads artifacts" "HTTPS/443"
        pipelinesComponents -> milvus "Indexes documents for RAG" "gRPC/REST"
        pipelinesComponents -> litellm "LLM inference for SDG" "HTTPS"
        pipelinesComponents -> rhoaiPyPI "Installs Python packages" "HTTPS/443"
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
        }
    }
}
