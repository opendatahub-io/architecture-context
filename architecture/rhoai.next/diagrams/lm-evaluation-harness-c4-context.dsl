workspace {
    model {
        dataScientist = person "Data Scientist" "Creates LMEvalJob CRs to evaluate language models"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and evaluation infrastructure"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "Batch job container for executing language model evaluations using 6,500+ benchmark tasks" {
            adapter = container "EvalHub Adapter (main.py)" "Bridges EvalHub job lifecycle with lm-eval framework — loads job spec, configures model backend, runs evaluation, publishes results" "Python 3.11"
            lmEvalCore = container "lm_eval Core Library" "Core evaluation framework providing task management, model abstraction, metrics computation, caching, and result aggregation" "Python Library"
            taskSystem = container "Task System" "6,500+ YAML-defined benchmark task configurations (MMLU, HellaSwag, ARC, etc.) plus Unitxt dynamic definitions" "YAML Configuration"
            modelBackend = container "local-completions Backend" "OpenAI-compatible HTTP client with async support (up to 128 concurrent), configurable TLS, retry logic" "Python (aiohttp/requests)"
        }

        trustyaiOperator = softwareSystem "trustyai-service-operator" "Creates and manages Kubernetes Jobs from LMEvalJob CRDs" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Evaluation lifecycle management — receives status updates, results, and coordinates evaluation workflows" "Internal RHOAI"
        modelInference = softwareSystem "Model Inference Endpoint" "Serves model completions via OpenAI-compatible API (vLLM, TGI, etc.)" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry" "Stores evaluation result artifacts as OCI images" "Internal"
        mlflow = softwareSystem "MLflow Tracking Server" "Logs evaluation metrics, run metadata, and overall scores" "Internal RHOAI"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Hosts benchmark datasets, tokenizer models, and gated resources" "External"
        s3Storage = softwareSystem "S3/COS Object Storage" "Provides offline test data caches for disconnected evaluations" "External"
        wandb = softwareSystem "Weights & Biases" "Optional experiment tracking and logging" "External"

        # User interactions
        dataScientist -> trustyaiOperator "Creates LMEvalJob CR via kubectl"
        platformAdmin -> evalHub "Monitors evaluation workflows"

        # Operator creates jobs
        trustyaiOperator -> lmEvalHarness "Creates Kubernetes Job with ConfigMap (job spec)" "HTTPS/443"

        # lm-eval-harness interactions
        lmEvalHarness -> modelInference "Sends evaluation prompts, receives completions" "HTTPS (OpenAI-compatible API)"
        lmEvalHarness -> evalHub "Reports status updates and evaluation results" "HTTPS/443 REST callbacks"
        lmEvalHarness -> ociRegistry "Pushes evaluation result artifacts" "HTTPS/443 OCI push"
        lmEvalHarness -> mlflow "Logs metrics and run metadata" "HTTPS REST API"
        lmEvalHarness -> huggingFaceHub "Downloads benchmark datasets and tokenizers" "HTTPS/443"
        lmEvalHarness -> s3Storage "Accesses offline test data caches" "HTTPS/443 S3 API"
        lmEvalHarness -> wandb "Optional experiment logging" "HTTPS/443"

        # Internal container relationships
        adapter -> lmEvalCore "Configures and invokes simple_evaluate()"
        lmEvalCore -> taskSystem "Loads benchmark task definitions"
        lmEvalCore -> modelBackend "Instantiates via model registry"
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
                shape person
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
