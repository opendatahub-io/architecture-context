workspace {
    model {
        datascientist = person "Data Scientist" "Initiates model evaluation jobs via EvalHub"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "Batch job container that evaluates language models against standardized benchmarks (HellaSwag, MMLU, GSM8K, HumanEval, etc.)" {
            adapter = container "LMEvalAdapter (main.py)" "EvalHub adapter wrapping lm_eval for batch execution. Handles job parsing, callbacks, OCI artifacts, disconnected mode, error sanitization." "Python Application"
            lmEval = container "lm_eval" "Core evaluation framework providing benchmark tasks, model interfaces, and metrics computation via simple_evaluate() API." "Python Package"
            cli = container "lm-eval CLI" "Command-line interface for standalone evaluation runs outside EvalHub." "Python Console Script"
        }

        lmEvalOperator = softwareSystem "TrustyAI / LMEval Operator" "Kubernetes operator managing LMEvalJob CRD lifecycle and creating batch Jobs" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Evaluation orchestration platform that dispatches and collects evaluation results" "Internal RHOAI"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "Target language model being evaluated via OpenAI-compatible completions API" "Internal"
        hfHub = softwareSystem "HuggingFace Hub" "Repository for tokenizers, datasets, and model configurations" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for persisting evaluation results" "External"
        s3Storage = softwareSystem "AWS S3-Compatible Storage" "Object storage for pre-staged evaluation data" "External"
        mlflow = softwareSystem "MLflow" "ML experiment tracking for evaluation results and metrics" "External"

        datascientist -> evalHub "Submits evaluation request"
        evalHub -> lmEvalOperator "Creates LMEvalJob CR"
        lmEvalOperator -> lmEvalHarness "Creates Kubernetes Job"

        adapter -> lmEval "Calls simple_evaluate()"
        cli -> lmEval "Calls simple_evaluate()"

        lmEvalHarness -> modelEndpoint "POST /v1/completions" "HTTPS/TLS, Bearer token"
        lmEvalHarness -> evalHub "POST status, results, errors" "HTTPS/443, Provider credentials"
        lmEvalHarness -> ociRegistry "Push evaluation artifacts" "HTTPS/443, Username/Password"
        lmEvalHarness -> hfHub "GET tokenizers, datasets" "HTTPS/443, HF_TOKEN"
        lmEvalHarness -> s3Storage "Download evaluation data" "HTTPS, AWS credentials"
        lmEvalHarness -> mlflow "Log results and metrics" "HTTPS/TLS"
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
        }
    }
}
