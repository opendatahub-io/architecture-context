workspace {
    model {
        dataScientist = person "Data Scientist" "Defines evaluation benchmarks and reviews results"
        platformAdmin = person "Platform Admin" "Configures evaluation infrastructure and credentials"

        lmEvalHarness = softwareSystem "LM Evaluation Harness" "Batch-oriented runtime for one-shot language model evaluations using EleutherAI's lm-evaluation-harness framework" {
            adapter = container "EvalHub Adapter" "Bridges EvalHub job orchestration with lm-evaluation-harness simple_evaluate(); handles job specs, credentials, offline mode, error mapping, result formatting" "Python (main.py)"
            lmEvalCore = container "lm_eval Core Library" "EleutherAI evaluation framework providing task management, model backends (local-completions), metrics, caching, and evaluation orchestration" "Python Library"
            ociPusher = container "OCI Artifact Pusher" "Pushes evaluation results/traces to OCI registries using olot and skopeo" "Python Script (scripts/oci.py)"
        }

        lmEvalOperator = softwareSystem "TrustyAI LMEval Operator" "Creates Kubernetes Jobs using the lm-evaluation-harness container image; manages job lifecycle, mounts secrets, configures job specs" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Orchestrates evaluation jobs, receives status callbacks and results" "Internal RHOAI"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "Serves LLM inference via OpenAI-compatible /v1/completions API (vLLM, TGI, etc.)" "Internal/External"
        ociRegistry = softwareSystem "OCI Registry" "Stores evaluation result artifacts as OCI images" "Infrastructure"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Hosts benchmark datasets and tokenizer models" "External"
        mlflow = softwareSystem "MLflow Tracking" "Experiment tracking for evaluation metrics and results" "Internal RHOAI"

        # Relationships
        dataScientist -> lmEvalOperator "Defines LMEvalJob CR with benchmark config"
        platformAdmin -> lmEvalOperator "Configures credentials and infrastructure"

        lmEvalOperator -> lmEvalHarness "Creates Kubernetes Job, mounts ConfigMap (/meta/job.json) and Secrets"

        adapter -> evalHub "Reports job lifecycle status (INITIALIZING → COMPLETED/FAILED)" "HTTPS/443, Bearer Token"
        adapter -> lmEvalCore "Calls simple_evaluate() with parsed job spec parameters"
        lmEvalCore -> modelEndpoint "Sends batched evaluation prompts, receives completions" "HTTPS/443, Bearer Token (OPENAI_API_KEY)"
        lmEvalCore -> huggingFaceHub "Downloads benchmark datasets and tokenizers (disabled in air-gapped mode)" "HTTPS/443, HF_TOKEN"
        adapter -> ociPusher "Triggers artifact persistence after evaluation"
        ociPusher -> ociRegistry "Pushes evaluation result JSON as OCI artifact" "HTTPS/443, Docker auth"
        adapter -> mlflow "Logs evaluation metrics and results (optional)" "HTTPS/443"
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
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
