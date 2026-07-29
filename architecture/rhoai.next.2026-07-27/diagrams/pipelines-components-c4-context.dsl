workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and submits ML pipelines using KFP components"

        pipelinesComponents = softwareSystem "pipelines-components" "Reusable KFP component library (kfp-components v1.11.0) with 22 components across 4 domains: data processing, deployment, evaluation, training" {
            dataProcessing = container "Data Processing Components" "Dataset download, parse & chunk, SDG, AutoML data loading, vector DB ingestion" "Python @dsl.component"
            deployment = container "Deployment Components" "KServe model serving and Model Registry deployment" "Python @dsl.component"
            evaluation = container "Evaluation Components" "EvalHub/KServe inference evaluation and LM Eval" "Python @dsl.component"
            training = container "Training Components" "LoRA/SFT/OSFT fine-tuning, AutoML (AutoGluon), AutoRAG optimization" "Python @dsl.component"
        }

        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration platform" "Internal Platform"
        kubernetes = softwareSystem "Kubernetes API" "Cluster resource management" "Internal Platform"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (serving.kserve.io)" "Internal Platform"
        odh = softwareSystem "OpenDataHub Infrastructure" "Platform provisioning (infrastructure.opendatahub.io)" "Internal Platform"
        ray = softwareSystem "CodeFlare / Ray" "Distributed compute (ray.io RayJob)" "Internal Platform"
        kueue = softwareSystem "Kueue" "Quota management (kueue.x-k8s.io)" "Internal Platform"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage and versioning" "Internal Platform"

        s3 = softwareSystem "AWS S3-Compatible Storage" "Model artifact and dataset storage" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Dataset and model downloads" "External Service"
        llmApi = softwareSystem "LLM API Endpoints" "Language model inference" "External Service"
        ociRegistry = softwareSystem "OCI Registries" "Container/model image downloads" "External Service"
        minio = softwareSystem "MinIO" "S3-compatible object storage" "External Service"

        dataScientist -> kfp "Submits pipeline YAML"
        kfp -> pipelinesComponents "Orchestrates component execution as pods"

        dataProcessing -> s3 "Downloads datasets" "HTTPS/TLS, AWS_SECRET_ACCESS_KEY"
        dataProcessing -> huggingface "Downloads datasets and models" "HTTPS/TLS, HF_TOKEN"
        dataProcessing -> ray "Submits RayJob for distributed parsing" "Kubernetes API"
        dataProcessing -> minio "Reads/writes chunked data" "HTTPS/TLS, secretKeyRef"
        dataProcessing -> kueue "Optional quota management" "Kubernetes API"
        dataProcessing -> llmApi "Generates synthetic data" "HTTPS/TLS, LLM_API_KEY"

        training -> s3 "Loads training data" "HTTPS/TLS, S3_SECRET_KEY"
        training -> ociRegistry "Pulls model images" "HTTPS/TLS, OCI_PULL_SECRET"
        training -> llmApi "AutoRAG optimization" "HTTPS/TLS, LLM_API_KEY"

        deployment -> kserve "Creates InferenceService CRs" "Kubernetes API"
        deployment -> modelRegistry "Registers model versions" "Platform-internal"

        evaluation -> kserve "Sends inference requests" "Kubernetes API"

        pipelinesComponents -> kubernetes "Resource operations" "HTTPS, ServiceAccount token"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
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
