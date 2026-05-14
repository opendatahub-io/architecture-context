workspace {
    model {
        dataScientist = person "Data Scientist" "Creates LMEvalJob CRDs to benchmark language models"
        platformAdmin = person "Platform Admin" "Configures evaluation infrastructure and model endpoints"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "Batch-oriented runtime for executing language model evaluations using 6,500+ benchmarks, shipped as a Kubernetes Job container image (odh-ta-lmes-job)" {
            adapter = container "EvalHub Adapter" "Bridges EvalHub job lifecycle with lm-eval framework — loads JobSpec, configures model backend, runs evaluation, publishes results" "Python (main.py)"
            coreLib = container "lm_eval Core Library" "Core evaluation framework providing task management, model abstraction, metrics computation, caching, and result aggregation" "Python Library"
            modelBackend = container "local-completions Backend" "OpenAI-compatible HTTP client with async concurrent requests (1-128), configurable TLS, retry logic, and batched requests" "Python (TemplateAPI)"
            taskSystem = container "Task System" "6,500+ YAML-defined benchmark task configurations (MMLU, HellaSwag, ARC, etc.) with Unitxt integration" "YAML + Python"
        }

        trustyaiOperator = softwareSystem "trustyai-service-operator" "Creates and manages Kubernetes Jobs from LMEvalJob CRDs" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Receives status updates, evaluation results, and OCI artifact references" "Internal RHOAI"
        modelInference = softwareSystem "Model Inference Endpoint" "OpenAI-compatible API serving model completions (vLLM, TGI, etc.)" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry" "Stores evaluation result artifacts as OCI images" "Internal"
        mlflow = softwareSystem "MLflow Tracking Server" "Logs evaluation metrics and run metadata" "Internal"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Hosts benchmark datasets, tokenizers, and gated model artifacts" "External"
        s3Storage = softwareSystem "S3/COS Object Storage" "Provides pre-cached datasets for offline/disconnected evaluations" "External"
        wandb = softwareSystem "Weights & Biases" "Optional experiment tracking and logging" "External"

        dataScientist -> trustyaiOperator "Creates LMEvalJob CR via kubectl"
        trustyaiOperator -> lmEvalHarness "Creates Kubernetes Job with ConfigMap (JobSpec)"

        adapter -> evalHub "Reports job lifecycle status and results" "HTTPS/443 Bearer Token"
        adapter -> ociRegistry "Pushes evaluation result artifacts" "HTTPS/443 Registry Auth"
        adapter -> mlflow "Logs metrics and run metadata" "HTTPS Configurable"

        modelBackend -> modelInference "Sends evaluation prompts, receives completions" "HTTPS POST /v1/completions Bearer Token"

        coreLib -> huggingfaceHub "Downloads benchmark datasets and tokenizers" "HTTPS/443 HF_TOKEN"
        coreLib -> s3Storage "Loads offline cached datasets (via init container)" "HTTPS/443 AWS IAM"

        lmEvalHarness -> wandb "Optional experiment tracking" "HTTPS/443"
    }

    views {
        systemContext lmEvalHarness "SystemContext" {
            include *
            autoLayout
        }

        container lmEvalHarness "Containers" {
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
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
