workspace "pipelines-components" "RHOAI 3.7-ea.1 KFP component/pipeline library and managed-pipeline images" {
    model {
        dataScientist = person "Data Scientist" "Runs AutoML, AutoRAG, fine-tuning and deployment pipelines"
        platformAdmin = person "Platform Admin" "Installs RHOAI and configures Data Science Pipelines"

        pipelinesComponents = softwareSystem "pipelines-components" "Reusable KFP v2 components and pipelines plus the managed-pipeline init container and task runtime images" {
            library = container "kfp-components library" "KFP v2 components and pipelines: data processing, training, evaluation, deployment" "Python package"
            generator = container "generate-managed-pipelines" "Build-time compiler for managed: true pipelines" "Python"
            initContainer = container "odh-pipelines-components" "One-shot init container staging managed pipelines into /config/managed-pipelines; recompiles when RELATED_IMAGE_* is set" "Python 3.12, UBI python-312"
            automlImage = container "odh-automl" "Task runtime for AutoGluon tabular/timeseries pipelines" "AIPCC cpu-torch2.13 image"
            autoragImage = container "odh-autorag" "Task runtime for AutoRAG pipelines (ai4rag, Docling, Whisper, LangChain, pymilvus)" "AIPCC cpu-torch2.13 image"
            autoragInference = container "odh-autorag-inference" "Placeholder runtime for AutoRAG-generated agents" "AIPCC cpu-torch2.13 image" "Placeholder"
            starterKit = container "agentic-rag starter kit" "Template FastAPI agent emitted by AutoRAG; optional TokenReview auth wrapper" "Python FastAPI, 8000/TCP" "Template"
        }

        odhOperator = softwareSystem "opendatahub-operator" "Supplies RELATED_IMAGE_* pins via imageParamMap" "Internal RHOAI"
        dspo = softwareSystem "Data Science Pipelines Operator" "Runs the init container on the KFP API server pod" "Internal RHOAI"
        kfp = softwareSystem "Data Science Pipelines (KFP API server / Argo)" "Registers managed pipelines and executes component tasks" "Internal RHOAI"
        kserve = softwareSystem "KServe" "InferenceService / ServingRuntime model serving" "Internal RHOAI"
        trainer = softwareSystem "Kubeflow Trainer" "Fine-tuning job execution" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "Ray-based data processing" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata registration" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking" "Internal RHOAI"
        evalhub = softwareSystem "EvalHub / TrustyAI" "Model evaluation" "Internal RHOAI"
        maas = softwareSystem "MaaS / OpenAI-compatible LLM" "LLM and embedding endpoints" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes API" "CRUD for KServe, Trainer, HardwareProfile; TokenReview" "External"
        s3 = softwareSystem "S3-compatible storage" "Datasets, documents, models, artifacts" "External"
        hf = softwareSystem "Hugging Face Hub" "Dataset and model download" "External"
        vectorDb = softwareSystem "Milvus / PGVector" "Vector storage" "External"
        ociRegistry = softwareSystem "OCI registry" "Modelcar / OCI model download" "External"

        platformAdmin -> odhOperator "Installs and configures"
        dataScientist -> kfp "Runs managed and custom pipelines"
        odhOperator -> dspo "Passes RELATED_IMAGE_* pins" "env/params"
        dspo -> initContainer "Runs as init container with RELATED_IMAGE_* env" "Pod spec"
        initContainer -> kfp "Stages managed-pipelines.json + YAML" "Shared volume /config/managed-pipelines"
        generator -> library "Compiles managed pipelines from"
        generator -> initContainer "Bakes compiled YAML into" "Image build"
        library -> automlImage "Installed as wheel in"
        kfp -> automlImage "Executes AutoML tasks in"
        kfp -> autoragImage "Executes AutoRAG tasks in"
        kfp -> library "Executes component tasks from"
        library -> starterKit "AutoRAG emits"

        library -> k8sApi "KServe/Trainer/HardwareProfile CRUD" "HTTPS/443-6443, Bearer token"
        library -> kserve "Deploys InferenceService / ServingRuntime" "via Kubernetes API"
        library -> trainer "Submits fine-tuning jobs" "TrainerClient via Kubernetes API"
        library -> kuberay "Runs Ray data processing" "ray.io CRDs"
        library -> modelRegistry "Registers models" "HTTP (no TLS, no auth)"
        library -> mlflow "Logs experiments" "HTTPS/443, Bearer"
        library -> evalhub "Runs evaluations" "REST/CRD"
        library -> maas "Generation / embeddings" "HTTPS/443, API key"
        library -> s3 "Reads/writes data and artifacts" "HTTPS/443, AWS keys"
        library -> hf "Downloads datasets/models" "HTTPS/443, HF_TOKEN"
        library -> vectorDb "Indexes / retrieves" "gRPC 19530 / PG 5432"
        library -> ociRegistry "Pulls modelcars" "HTTPS/443, pull secret"
        autoragImage -> s3 "Reads documents" "HTTPS/443"
        autoragImage -> maas "LLM / embeddings" "HTTPS/443"
        autoragImage -> vectorDb "Indexes documents" "gRPC / PG"
        starterKit -> k8sApi "TokenReview" "HTTPS, Bearer K8S_REVIEWER_TOKEN"
        starterKit -> maas "Generation" "HTTPS/443, API key"
        starterKit -> vectorDb "Retrieval" "gRPC / PG"
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
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Template" {
                border dashed
            }
            element "Placeholder" {
                border dashed
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}
