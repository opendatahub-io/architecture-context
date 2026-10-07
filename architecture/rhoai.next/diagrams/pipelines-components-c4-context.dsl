workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML training, evaluation, and deployment pipelines"
        mlEngineer = person "ML Engineer" "Configures pipeline components and manages model lifecycle"

        pipelinesComponents = softwareSystem "pipelines-components" "Reusable KFP components and pre-compiled managed pipelines for AI/ML workflows on RHOAI" {
            initContainer = container "Init Container" "Stages pre-compiled managed pipeline YAMLs into shared volume; recompiles when RELATED_IMAGE_* overrides present" "Python/UBI9"
            dataProcessingComponents = container "Data Processing Components" "Dataset download (HF/S3/HTTP), text extraction, SDG, parse-and-chunk" "Python KFP Components"
            trainingComponents = container "Training Components" "Model fine-tuning (SFT, LoRA, OSFT, LoRA-GRPO)" "Python KFP Components"
            evaluationComponents = container "Evaluation Components" "Model evaluation (lm-eval, EvalHub)" "Python KFP Components"
            deploymentComponents = container "Deployment Components" "KServe model deployment via ServingRuntime/InferenceService CRs" "Python KFP Components"
            automlImage = container "AutoML Image" "AutoGluon tabular/time-series training on AIPCC CPU base" "Python/AIPCC"
            autoragImage = container "AutoRAG Image" "Document processing with Docling, RAG optimization with ai4rag" "Python/AIPCC"
        }

        kfpServer = softwareSystem "KFP API Server" "Kubeflow Pipelines API server that serves managed pipelines" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages KFP deployments and injects RELATED_IMAGE_* overrides" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform with ServingRuntime and InferenceService CRDs" "Internal RHOAI"
        hardwareProfiles = softwareSystem "ODH HardwareProfiles" "GPU resource profile definitions for deployment configuration" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub" "Model evaluation benchmark service" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versions" "Internal RHOAI"
        milvus = softwareSystem "Milvus" "Vector database for RAG document indexing" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for datasets and artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Pipeline artifact storage" "External"
        llmEndpoint = softwareSystem "LLM Inference Endpoint" "Large language model API for synthetic data generation" "External"

        dataScientist -> pipelinesComponents "Runs ML pipelines via KFP"
        mlEngineer -> pipelinesComponents "Configures components and managed pipelines"

        dspo -> pipelinesComponents "Injects RELATED_IMAGE_* env vars"
        pipelinesComponents -> kfpServer "Delivers compiled pipeline YAMLs via shared volume"
        pipelinesComponents -> kserve "Creates ServingRuntime and InferenceService CRs" "HTTPS/443"
        pipelinesComponents -> hardwareProfiles "Reads GPU resource profiles" "HTTPS/443"
        pipelinesComponents -> evalHub "Submits benchmark jobs and polls results" "HTTPS"
        pipelinesComponents -> modelRegistry "Registers trained models" "HTTPS"
        pipelinesComponents -> milvus "Indexes documents for RAG" "gRPC/HTTP"
        pipelinesComponents -> huggingface "Downloads models and datasets" "HTTPS/443"
        pipelinesComponents -> s3 "Downloads datasets, uploads artifacts" "HTTPS/443"
        pipelinesComponents -> gcs "Stores pipeline artifacts" "HTTPS/443"
        pipelinesComponents -> llmEndpoint "Calls LLM for synthetic data generation" "HTTPS"
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
                background #4a90e2
                color #ffffff
                shape Person
            }
        }
    }
}
