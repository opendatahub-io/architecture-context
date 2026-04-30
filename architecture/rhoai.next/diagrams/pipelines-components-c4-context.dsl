workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs AI/ML pipelines for training, evaluation, and deployment"

        pipelinesComponents = softwareSystem "Pipelines Components" "Centralized library of reusable KFP v2 components and pre-composed pipelines for AI/ML workflows" {
            componentLibrary = container "KFP Component Library" "Reusable pipeline steps for data processing, training, evaluation, and deployment" "Python (KFP v2)"
            pipelineDefinitions = container "Pipeline Definitions" "Pre-composed multi-step pipelines for AutoML, AutoRAG, and fine-tuning" "Python (KFP v2)"
            initContainer = container "Managed Pipeline Init Container" "Compiles and stages managed pipelines for KFP API server discovery" "Python Init Container"
            automlRuntime = container "AutoML Runtime Image" "Pre-built environment with AutoGluon, PyTorch for AutoML execution" "Container Image"
            autoragRuntime = container "AutoRAG Runtime Image" "Pre-built environment with Docling, LangChain, ChromaDB for RAG optimization" "Container Image"
        }

        dspa = softwareSystem "Data Science Pipelines Application (DSPA)" "Pipeline execution runtime on RHOAI clusters" "Internal RHOAI"
        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server for pipeline management" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Stores model metadata and provenance" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Dataset and model artifact storage (MinIO/Ceph/AWS)" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Model and dataset repository" "External"
        llamaStack = softwareSystem "Llama Stack API" "Embedding generation and LLM inference service" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API for secrets, PVCs, and scheduling" "Infrastructure"
        ociRegistry = softwareSystem "OCI Container Registry" "Container and model artifact registry" "External"
        konflux = softwareSystem "Konflux Build System" "Multi-arch container image builds with hermetic dependency prefetch" "Infrastructure"

        # Relationships
        dataScientist -> pipelinesComponents "Imports components and composes custom pipelines"
        dataScientist -> dspa "Submits pipeline runs via KFP API"

        pipelinesComponents -> kfpServer "Init container copies managed pipeline YAMLs" "Filesystem (shared volume)"
        pipelinesComponents -> dspa "Pipeline execution runtime" "HTTPS/443"
        pipelinesComponents -> s3Storage "Dataset download/upload, model artifacts" "HTTPS/443, AWS IAM"
        pipelinesComponents -> hfHub "Model and dataset downloads" "HTTPS/443, Bearer Token"
        pipelinesComponents -> modelRegistry "Model registration with provenance" "HTTPS/443, Bearer Token"
        pipelinesComponents -> llamaStack "Embeddings, vector I/O, inference" "HTTPS/443, API Key"
        pipelinesComponents -> k8sApi "Secret reads, PVC provisioning" "HTTPS/6443, SA Token"
        pipelinesComponents -> ociRegistry "Model artifact download" "HTTPS/443, Registry creds"

        kfpServer -> dspa "Pipeline execution management"

        # Internal container relationships
        componentLibrary -> pipelineDefinitions "Components composed into pipelines"
        pipelineDefinitions -> initContainer "Managed pipelines compiled at build time"
        initContainer -> kfpServer "Copies compiled YAMLs to shared volume"
        pipelineDefinitions -> automlRuntime "AutoML pipelines execute on this image"
        pipelineDefinitions -> autoragRuntime "AutoRAG pipelines execute on this image"

        konflux -> pipelinesComponents "Builds container images" "Tekton Pipeline"
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
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
