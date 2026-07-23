workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines for training, evaluation, and deployment"
        mlEngineer = person "ML Engineer" "Builds custom pipelines using kfp-components SDK"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and DSPA instances"

        pipelinesComponents = softwareSystem "pipelines-components" "Reusable KFP component library and managed pipeline delivery system for RHOAI" {
            sdk = container "kfp-components SDK" "27+ reusable KFP v2 components and 18+ pipeline definitions" "Python Library"
            initContainer = container "odh-pipelines-components" "Compiles and delivers managed pipeline YAML to KFP API server" "Init Container (UBI9 Python 3.12)"
            automlRuntime = container "odh-automl" "Pre-built environment for AutoML training with AutoGluon" "Runtime Container (AIPCC CPU)"
            autoragRuntime = container "odh-autorag" "Pre-built environment for AutoRAG optimization with ai4rag and docling" "Runtime Container (AIPCC CPU)"
            genManaged = container "generate_managed_pipelines" "Discovers and compiles managed pipeline YAML at build time" "Python Build Script"
            initManaged = container "init_managed_pipelines" "Copies or recompiles managed pipeline YAML to shared PVC" "Python Runtime Script"
        }

        dspOperator = softwareSystem "data-science-pipelines-operator" "Deploys and manages DataSciencePipelinesApplication instances" "Internal RHOAI"
        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines orchestration and scheduling" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform with vLLM runtime" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Model metadata and version management" "Internal RHOAI"
        milvus = softwareSystem "Milvus" "Vector database for RAG document indexing" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Ray cluster orchestration for distributed processing" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queuing for resource management" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub" "Alternative evaluation backend" "Internal RHOAI"
        connectionsAPI = softwareSystem "RHOAI Connections API" "Credential discovery service" "Internal RHOAI"

        s3 = softwareSystem "S3 / MinIO" "Object storage for training data, documents, and artifacts" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        ogxAPI = softwareSystem "OGX API" "Vector store operations for AutoRAG optimization" "External"
        litellm = softwareSystem "LiteLLM / LLM API" "LLM inference for synthetic data generation" "External"
        rhaiPyPI = softwareSystem "RHEL AI PyPI Index" "Red Hat managed Python package index" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "Infrastructure"

        # User interactions
        dataScientist -> pipelinesComponents "Runs managed pipelines via RHOAI Dashboard"
        mlEngineer -> sdk "Builds custom pipelines using KFP SDK"
        platformAdmin -> dspOperator "Configures DSPA instances"

        # Internal platform interactions
        dspOperator -> initContainer "Deploys as init container (RELATED_IMAGE_*)"
        initContainer -> kfpServer "Writes managed pipeline YAML to shared PVC"
        sdk -> kserve "Creates InferenceService CRs for model deployment" "HTTPS/443"
        sdk -> modelRegistry "Registers trained models and versions" "HTTPS/443"
        sdk -> milvus "Vector ingestion and retrieval for RAG" "gRPC/19530"
        sdk -> kuberay "Creates RayJob CRs for distributed processing"
        sdk -> kueue "Optional workload queuing annotations"
        sdk -> evalHub "Alternative evaluation backend" "HTTPS/443"
        sdk -> connectionsAPI "Credential discovery" "HTTPS/443"
        sdk -> k8sAPI "Secret/ConfigMap reads, CR management" "HTTPS/6443"

        # External service interactions
        automlRuntime -> s3 "Training data and artifact storage" "HTTPS/443 AWS IAM"
        autoragRuntime -> s3 "Document storage" "HTTPS/443 AWS IAM"
        autoragRuntime -> ogxAPI "Vector store operations" "HTTPS/443 API Key"
        sdk -> hfHub "Model and dataset downloads" "HTTPS/443 Bearer Token"
        sdk -> litellm "LLM inference for SDG" "HTTPS/443 API Key"
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
            element "Infrastructure" {
                background #d6b656
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
