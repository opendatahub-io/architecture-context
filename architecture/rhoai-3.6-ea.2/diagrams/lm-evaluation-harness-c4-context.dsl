workspace {
    model {
        dataScientist = person "Data Scientist" "Configures and triggers language model evaluation jobs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and operator configuration"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "Batch evaluation framework that runs standardized LM benchmarks as Kubernetes jobs" {
            adapter = container "EvalHub Adapter" "Orchestrates 5-phase evaluation lifecycle (init, load, eval, post-process, persist)" "Python / main.py"
            lmEval = container "lm_eval Library" "Upstream evaluation engine with 60+ benchmarks (MMLU, HellaSwag, GSM8K, BBH, etc.)" "Python / EleutherAI"
            s3Downloader = container "S3 Downloader" "Downloads evaluation assets from S3-compatible storage" "Python / boto3"
            ociPusher = container "OCI Artifact Pusher" "Pushes evaluation results as OCI artifacts" "Python / skopeo + olot"

            adapter -> lmEval "Orchestrates evaluation runs"
            adapter -> s3Downloader "Downloads model/dataset assets"
            adapter -> ociPusher "Persists result artifacts"
        }

        lmesOperator = softwareSystem "TrustyAI LMES Operator" "Creates and manages lmes-job Kubernetes Jobs via LMEvalJob CRDs" "Internal RHOAI"
        modelServer = softwareSystem "Model Inference Endpoint" "Serves LLM predictions via OpenAI-compatible API (vLLM, etc.)" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Evaluation hub for status tracking and results aggregation" "Internal RHOAI"
        huggingFace = softwareSystem "HuggingFace Hub" "Hosts benchmark datasets and tokenizer artifacts" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model and dataset assets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation results" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and metrics logging" "External"

        dataScientist -> lmesOperator "Creates LMEvalJob CR via kubectl/dashboard"
        platformAdmin -> lmesOperator "Configures operator and job templates"
        lmesOperator -> lmEvalHarness "Creates Kubernetes Job"
        lmEvalHarness -> modelServer "Sends evaluation prompts via local-completions" "HTTP/HTTPS"
        lmEvalHarness -> evalHub "Reports status updates and results" "HTTPS"
        lmEvalHarness -> huggingFace "Downloads benchmark datasets" "HTTPS/443"
        lmEvalHarness -> s3Storage "Downloads model/dataset assets" "HTTPS"
        lmEvalHarness -> ociRegistry "Pushes result OCI artifacts" "HTTPS/443"
        lmEvalHarness -> mlflow "Logs evaluation metrics" "HTTP/HTTPS"
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
            element "Person" {
                shape Person
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
