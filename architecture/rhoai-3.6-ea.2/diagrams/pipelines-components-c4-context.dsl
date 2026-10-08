workspace {
    model {
        pipelineAuthor = person "Pipeline Author" "Data scientist or ML engineer who builds and runs AI/ML pipelines"

        pipelinesComponents = softwareSystem "pipelines-components" "Reusable KFP components and managed pipelines for AI/ML workflows on RHOAI" {
            kfpComponentsLib = container "kfp-components" "Python library of reusable KFP components (data processing, training, evaluation, deployment)" "Python Package v1.11.0"
            initContainer = container "init-managed-pipelines" "Copies pre-compiled managed pipeline YAMLs to shared volume for KFP API server" "Init Container (UBI9 Python 3.12)"
            generateScript = container "generate-managed-pipelines" "Discovers managed pipelines, compiles pipeline.py to KFP YAML specs at build time" "Build-Time Script"
            automlImage = container "odh-automl" "Runtime container for AutoGluon tabular and timeseries training" "AIPCC CPU Container"
            autoragImage = container "odh-autorag" "Runtime container for AutoRAG document processing with offline Docling models" "AIPCC CPU Container"
            autoragInfImage = container "odh-autorag-inference" "Inference container for AutoRAG-generated agents" "AIPCC CPU Container"
        }

        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (ServingRuntime, InferenceService CRs)" "Internal RHOAI"
        dspo = softwareSystem "DSPO" "Data Science Pipelines Operator - injects RELATED_IMAGE_* for disconnected deployments" "Internal RHOAI"
        evalHub = softwareSystem "Eval Hub" "Model benchmark evaluation service (REST API)" "Internal RHOAI"
        modelRegistry = softwareSystem "Kubeflow Model Registry" "Model metadata and provenance storage (REST API / 8080)" "Internal RHOAI"
        milvus = softwareSystem "Milvus" "Vector database for RAG document indexing (gRPC / 19530)" "Internal RHOAI"
        hwProfiles = softwareSystem "RHOAI HardwareProfiles" "GPU hardware profile CRDs for resource allocation" "Internal RHOAI"
        vllm = softwareSystem "vLLM" "GPU model serving runtime for inference" "Internal RHOAI"
        ray = softwareSystem "Ray / CodeFlare" "Distributed compute for document parsing" "Internal RHOAI"

        s3 = softwareSystem "S3-Compatible Storage" "Document and data artifact storage" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weight repository" "External"
        llmApi = softwareSystem "LLM API / MaaS" "LLM service for synthetic data generation and RAG optimization" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for CR management" "Infrastructure"

        pipelineAuthor -> pipelinesComponents "Imports kfp-components library"
        pipelinesComponents -> kfp "Compiled pipeline YAML specs consumed by KFP API server"
        pipelinesComponents -> kserve "Creates ServingRuntime and InferenceService CRs" "HTTPS/443 (K8s API)"
        pipelinesComponents -> hwProfiles "Reads HardwareProfile CRs for GPU allocation" "HTTPS/443 (K8s API)"
        dspo -> pipelinesComponents "Injects RELATED_IMAGE_* environment variables"
        pipelinesComponents -> evalHub "Submits evaluation jobs, polls results" "HTTP/HTTPS (variable port)"
        pipelinesComponents -> modelRegistry "Registers trained models with provenance" "HTTP/8080"
        pipelinesComponents -> milvus "Indexes documents for RAG" "gRPC/19530"
        pipelinesComponents -> vllm "References vLLM image in ServingRuntime CRs"
        pipelinesComponents -> ray "Submits RayJobs for distributed parsing"
        pipelinesComponents -> s3 "Uploads/downloads data artifacts" "HTTPS/443"
        pipelinesComponents -> huggingface "Downloads model weights" "HTTPS/443"
        pipelinesComponents -> llmApi "SDG and RAG optimization requests" "HTTPS"
        pipelinesComponents -> k8sApi "Creates/reads/deletes CRs" "HTTPS/443"
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
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}
