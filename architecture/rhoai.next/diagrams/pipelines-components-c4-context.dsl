workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs AI/ML pipelines for training, fine-tuning, and evaluation"
        mlEngineer = person "ML Engineer" "Configures pipeline parameters, manages model lifecycle"
        platformAdmin = person "Platform Admin" "Deploys DSPA, manages secrets and storage"

        pipelinesComponents = softwareSystem "Pipelines Components" "Reusable KFP v2 component library and pre-composed pipelines for AI/ML workflows" {
            componentLibrary = container "KFP Component Library" "Reusable pipeline steps: data processing, training, evaluation, deployment" "Python / KFP v2"
            pipelineDefinitions = container "Pre-Composed Pipelines" "Multi-step workflows: AutoML, AutoRAG, LoRA/OSFT/SFT fine-tuning" "Python / KFP v2"
            initContainer = container "Managed Pipeline Init Container" "Compiles and stages managed pipelines for KFP API server discovery" "Python Init Container"
            automlRuntime = container "AutoML Runtime Image" "Pre-built environment with AutoGluon, PyTorch for AutoML execution" "Container Image (odh-automl)"
            autoragRuntime = container "AutoRAG Runtime Image" "Pre-built environment with Docling, LangChain, ChromaDB for RAG optimization" "Container Image (odh-autorag)"
            cicdTooling = container "CI/CD Tooling" "Validation, compilation, base image governance, metadata enforcement" "Python Scripts"
        }

        dspa = softwareSystem "Data Science Pipelines Application" "KFP runtime environment on RHOAI clusters" "Internal RHOAI"
        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server for pipeline execution" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Model metadata storage with version and provenance tracking" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Object Storage" "Dataset storage, training data, model artifacts (MinIO/Ceph/AWS)" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Model and dataset repository for ML community" "External"
        llamaStack = softwareSystem "Llama Stack API" "Embedding generation, vector I/O, and LLM inference" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for secrets, PVCs, pod scheduling" "Infrastructure"
        ociRegistry = softwareSystem "OCI Container Registry" "Container and model artifact registry" "External"
        konflux = softwareSystem "Konflux Build System" "Multi-arch container image builds with hermetic dependency prefetch" "Internal Red Hat"
        pypiMirror = softwareSystem "Red Hat PyPI Mirror" "Curated Python package mirror for RHOAI builds" "Internal Red Hat"

        # User interactions
        dataScientist -> pipelinesComponents "Imports components, submits pipelines" "Python / KFP SDK"
        mlEngineer -> pipelinesComponents "Configures pipeline parameters, reviews results" "Python / KFP SDK"
        platformAdmin -> dspa "Deploys and configures DSPA" "kubectl / Operator"

        # Internal component relationships
        pipelineDefinitions -> componentLibrary "Composes components into workflows"
        initContainer -> kfpServer "Copies compiled pipeline YAMLs" "Filesystem (shared volume)"
        cicdTooling -> componentLibrary "Validates, compiles, governs" "Python Scripts"
        cicdTooling -> pipelineDefinitions "Validates metadata, compiles" "Python Scripts"

        # External system interactions
        pipelinesComponents -> dspa "Runs pipelines on" "KFP API / HTTPS/443"
        pipelinesComponents -> s3Storage "Downloads/uploads datasets and models" "HTTPS/443 / AWS IAM"
        pipelinesComponents -> hfHub "Downloads models and datasets" "HTTPS/443 / Bearer Token"
        pipelinesComponents -> llamaStack "Generates embeddings, LLM inference" "HTTPS/443 / API Key"
        pipelinesComponents -> modelRegistry "Registers trained models with provenance" "HTTPS/443 / Bearer Token"
        pipelinesComponents -> k8sAPI "Reads secrets, provisions PVCs" "HTTPS/6443 / SA Token"
        pipelinesComponents -> ociRegistry "Downloads model artifacts" "HTTPS/443 / Registry Creds"
        konflux -> pipelinesComponents "Builds container images" "Tekton Pipeline"
        konflux -> pypiMirror "Fetches Python dependencies" "HTTPS/443"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "Internal Red Hat" {
                background #cc0000
                color #ffffff
            }
            element "Infrastructure" {
                background #555555
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
