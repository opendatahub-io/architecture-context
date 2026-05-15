workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML training, AutoML, AutoRAG, and fine-tuning pipelines"
        mlEngineer = person "ML Engineer" "Configures pipeline parameters, manages model lifecycle"

        pipelinesComponents = softwareSystem "Pipelines Components" "Centralized library of reusable KFP components and pre-built pipelines for AI/ML workflows on RHOAI" {
            initContainer = container "Init Container" "Stages pre-compiled KFP pipeline YAMLs to shared volume for API server registration" "Python 3.11 / UBI9"
            componentLibrary = container "KFP Component Library" "25+ reusable KFP v2 components across AutoML, AutoRAG, finetuning, and utilities" "Python / kfp 2.16.0"
            automlImage = container "odh-automl Runtime" "Container image with AutoGluon and ML dependencies for AutoML pipeline steps" "Python / rhai/base-image-cpu-rhel9"
            autoragImage = container "odh-autorag Runtime" "Container image with ai4rag, docling, and LlamaStack client for RAG pipeline steps" "Python / rhai/base-image-cpu-rhel9"
            managedPipelines = container "Managed Pipelines" "Pre-compiled pipeline definitions (AutoML, AutoRAG, finetuning) as KFP IR YAML" "KFP IR YAML"
            buildSystem = container "Pipeline Compiler" "Discovers metadata.yaml, compiles pipelines using KFP Compiler" "Python / generate_managed_pipelines.py"
        }

        kfpApiServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server - manages pipeline definitions and runs" "Internal RHOAI"
        argoWorkflow = softwareSystem "Argo Workflow Engine" "Orchestrates pipeline step execution as Kubernetes pods" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Dataset and artifact storage (AWS S3 or MinIO)" "External"
        llamaStack = softwareSystem "LlamaStack Server" "Vector store operations, embedding models, and generation for RAG" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Dataset and pre-trained model downloads" "External"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Model metadata registration with provenance tracking" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "Distributed training job orchestration (ClusterTrainingRuntime)" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "Infrastructure"
        liteLLM = softwareSystem "LiteLLM Endpoint" "Model inference for synthetic data generation" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container and model artifact registry" "External"

        # User interactions
        dataScientist -> kfpApiServer "Creates and monitors pipeline runs via KFP UI/SDK"
        mlEngineer -> kfpApiServer "Configures managed pipelines and runtime parameters"

        # Init container flow
        initContainer -> kfpApiServer "Stages pipeline YAMLs via shared volume mount"
        buildSystem -> managedPipelines "Compiles pipeline.py to KFP IR YAML"
        managedPipelines -> initContainer "Bundled into init container image"

        # Component execution flows
        kfpApiServer -> argoWorkflow "Schedules pipeline runs"
        argoWorkflow -> componentLibrary "Executes pipeline steps as pods"
        componentLibrary -> automlImage "AutoML steps use as base_image"
        componentLibrary -> autoragImage "AutoRAG steps use as base_image"

        # External integrations
        componentLibrary -> s3Storage "Read/write datasets and artifacts" "HTTPS/443 - AWS IAM"
        componentLibrary -> llamaStack "Vector store, embedding, generation" "HTTP(S)/8321 - API key"
        componentLibrary -> huggingFace "Download datasets and models" "HTTPS/443 - Bearer token"
        componentLibrary -> modelRegistry "Register trained models" "HTTP/8080 - No auth"
        componentLibrary -> kubeflowTrainer "Submit distributed training jobs" "HTTPS/443 - SA token"
        componentLibrary -> k8sApi "Create TrainJobs, stream logs" "HTTPS/443 - SA token"
        componentLibrary -> liteLLM "Model inference for SDG" "HTTPS - API key"
        componentLibrary -> ociRegistry "Download models via skopeo" "HTTPS/443 - Docker auth"
    }

    views {
        systemContext pipelinesComponents "SystemContext" {
            include *
            autoLayout
            description "System context for pipelines-components showing external integrations"
        }

        container pipelinesComponents "Containers" {
            include *
            autoLayout
            description "Internal structure of pipelines-components"
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
                shape Person
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
