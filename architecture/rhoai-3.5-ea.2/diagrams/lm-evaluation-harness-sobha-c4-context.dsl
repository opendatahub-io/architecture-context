workspace {
    model {
        dataScientist = person "Data Scientist" "Creates evaluation jobs to benchmark language models"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures model serving and evaluation pipelines"

        lmevalJob = softwareSystem "LMEval Job" "Batch container executing language model evaluations using lm-evaluation-harness with EvalHub adapter integration" {
            adapter = container "EvalHub Adapter" "Bridges lm-evaluation-harness with EvalHub job lifecycle (job spec parsing, status callbacks, result reporting, OCI artifact creation)" "Python (main.py)"
            lmevalLib = container "lm_eval Library" "Core evaluation framework providing task management (150+ benchmarks), model backends, metrics computation, and evaluation orchestration" "Python (lm-evaluation-harness 0.4.8)"
            localCompletions = container "local-completions Backend" "OpenAI-compatible HTTP client sending batched inference requests to remote model endpoints" "Python (aiohttp)"
            unitxt = container "Unitxt Framework" "Customizable textual data preparation and evaluation framework for custom benchmark tasks" "Python (unitxt 1.17.2)"
            errorSanitizer = container "Error Sanitizer" "Regex-based credential redaction preventing leakage in status reports" "Python"
        }

        lmevalOperator = softwareSystem "TrustyAI LMEval Operator" "Creates and manages Kubernetes Jobs for model evaluation (lmes-controller)" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Job orchestration service receiving status callbacks and evaluation results" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving Endpoint" "vLLM, TGI, or other OpenAI-compatible model serving runtime" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for persisting evaluation result artifacts" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Public repository for benchmark datasets, tokenizers, and model configs" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts and datasets" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "ML experiment tracking for logging evaluation metrics and run metadata" "External"
        kubernetes = softwareSystem "Kubernetes API" "Provides ConfigMaps, Secrets, and Job lifecycle management" "Infrastructure"

        # Relationships
        dataScientist -> lmevalOperator "Creates LMEvalJob CR" "kubectl / ODH Dashboard"
        lmevalOperator -> lmevalJob "Creates Kubernetes Job" "K8s Job API"
        lmevalJob -> evalHub "Reports status + results" "HTTPS/443, Bearer Token"
        lmevalJob -> modelServing "Sends completions requests" "HTTPS/443, Bearer Token"
        lmevalJob -> ociRegistry "Pushes result artifacts" "HTTPS/443, Registry credentials"
        lmevalJob -> hfHub "Downloads datasets, tokenizers" "HTTPS/443, HF_TOKEN (optional)"
        lmevalJob -> s3Storage "Accesses model artifacts" "HTTPS/443, AWS IAM"
        lmevalJob -> mlflow "Logs evaluation metrics" "HTTPS/443, Bearer Token"
        kubernetes -> lmevalJob "Provides ConfigMap + Secrets" "Volume mounts"

        # Internal relationships
        adapter -> lmevalLib "Calls simple_evaluate()"
        lmevalLib -> localCompletions "Sends inference requests"
        lmevalLib -> unitxt "Loads custom tasks"
        adapter -> errorSanitizer "Sanitizes error messages"
    }

    views {
        systemContext lmevalJob "SystemContext" {
            include *
            autoLayout
        }

        container lmevalJob "Containers" {
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
                color #333333
            }
            element "Infrastructure" {
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
