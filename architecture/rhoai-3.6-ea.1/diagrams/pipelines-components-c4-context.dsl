workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines using Kubeflow Pipelines"
        platformOperator = person "Platform Operator" "Deploys and configures RHOAI platform"

        pipelinesComponents = softwareSystem "pipelines-components" "Init container and KFP component library for reusable ML pipeline stages" {
            initContainer = container "Init Container" "Copies pre-compiled pipeline YAMLs to shared volume; recompiles with operator-pinned image refs when RELATED_IMAGE_* env vars are set" "Python (UBI9)"
            componentLibrary = container "KFP Component Library" "Reusable @dsl.component functions for data processing, training, evaluation, and deployment" "Python (kfp-components)"
            pipelineDefinitions = container "Pipeline Definitions" "Pre-assembled pipelines (SFT, AutoML, RAG) compiled from Python DSL to YAML" "KFP Pipeline YAML"
        }

        kfpApiServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server that registers and orchestrates pipeline runs" "Internal RHOAI"
        kubernetesApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        kserve = softwareSystem "KServe" "Serverless ML model inference platform" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Central registry for ML model metadata" "Internal RHOAI"
        codeflareRay = softwareSystem "CodeFlare / Ray" "Distributed computing framework for batch processing" "Internal RHOAI"

        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for datasets and model artifacts" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Public model and dataset repository" "External"
        rhaiPyPI = softwareSystem "RHAI Python Package Index" "Red Hat managed PyPI for supply chain control" "External"

        # Relationships
        dataScientist -> kfpApiServer "Submits pipeline runs via UI/CLI"
        platformOperator -> pipelinesComponents "Deploys via operator"

        initContainer -> pipelineDefinitions "Reads pre-compiled YAMLs"
        initContainer -> kfpApiServer "Stages YAMLs to shared volume" "Filesystem (shared volume)"

        kfpApiServer -> componentLibrary "Executes pipeline steps as containers"

        componentLibrary -> s3Storage "Fetches datasets, stores artifacts" "HTTPS/443 (boto3)"
        componentLibrary -> huggingFaceHub "Downloads models and datasets" "HTTPS/443"
        componentLibrary -> kubernetesApi "Resource operations, RayJob submission" "HTTPS/443 (ServiceAccount token)"
        componentLibrary -> kserve "Model evaluation via Eval Hub" "HTTPS (mTLS)"
        componentLibrary -> modelRegistry "Registers trained models" "HTTPS (ServiceAccount token)"
        componentLibrary -> codeflareRay "Submits distributed RayJobs" "HTTP/gRPC (CodeFlare SDK)"

        pipelinesComponents -> rhaiPyPI "Build-time dependency resolution" "HTTPS/443"
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
