workspace {
    model {
        dataScientist = person "Data Scientist" "Submits model evaluation requests via RHOAI TrustyAI"
        platformAdmin = person "Platform Admin" "Configures evaluation infrastructure and credentials"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "Batch job container for executing LLM benchmarks (MMLU, GSM8K, HellaSwag, ARC, GPQA, IFEval, 200+ tasks)" {
            evalHubAdapter = container "EvalHub Adapter (main.py)" "RHOAI-specific entry point bridging EvalHub job specs to lm-eval simple_evaluate() API" "Python"
            lmEvalCore = container "lm-eval Core Framework" "Task definitions, model backends, metric computation, evaluation orchestration" "Python Library"
            localCompletionsBackend = container "local-completions Backend" "Sends HTTP requests to OpenAI-compatible model endpoints for inference" "Python (aiohttp)"
            taskManager = container "Task Manager" "Manages 200+ built-in evaluation tasks and custom task definitions (YAML, Unitxt)" "Python"
        }

        lmEvalOperator = softwareSystem "TrustyAI LMEval Operator" "Creates and manages Kubernetes Jobs from LMEvalJob CRDs" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Evaluation orchestration service — dispatches jobs, receives results" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving (vLLM / KServe)" "Hosts LLM models with OpenAI-compatible inference API" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking and metric logging" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry" "Stores evaluation result artifacts as OCI images" "Internal"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Public model and dataset repository" "External"
        s3Storage = softwareSystem "S3 / IBM COS" "Object storage for offline test data and model artifacts" "External"

        # Relationships
        dataScientist -> lmEvalOperator "Submits LMEvalJob CR via kubectl / RHOAI Dashboard"
        lmEvalOperator -> lmEvalHarness "Creates Kubernetes Job with job spec ConfigMap"
        evalHub -> lmEvalHarness "Provides job specification via /meta/job.json"

        evalHubAdapter -> lmEvalCore "Calls simple_evaluate() with parsed job parameters"
        lmEvalCore -> taskManager "Loads and configures evaluation tasks"
        lmEvalCore -> localCompletionsBackend "Dispatches inference requests"

        lmEvalHarness -> evalHub "Reports status callbacks and evaluation results" "HTTPS/443, Bearer Token"
        lmEvalHarness -> modelServing "Sends inference requests via /v1/completions" "HTTPS/443 or HTTP/8080, OPENAI_API_KEY"
        lmEvalHarness -> ociRegistry "Pushes evaluation result OCI artifacts" "HTTPS/443, Registry credentials"
        lmEvalHarness -> mlflow "Logs evaluation metrics and experiment metadata" "HTTPS/443 or HTTP/5000, Bearer Token"
        lmEvalHarness -> huggingFaceHub "Downloads tokenizers, datasets, model configs" "HTTPS/443, HF_TOKEN"
        lmEvalHarness -> s3Storage "Downloads offline test data via init container" "HTTPS/443, AWS IAM"
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
            element "Person" {
                shape person
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
            element "Internal" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
