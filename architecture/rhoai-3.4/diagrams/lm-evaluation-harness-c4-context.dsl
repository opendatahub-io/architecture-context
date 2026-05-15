workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Requests model evaluations through EvalHub"

        lmes = softwareSystem "LM Evaluation Harness" "Batch-oriented execution environment for evaluating language models using EleutherAI lm-evaluation-harness framework" {
            adapter = container "LMEval Adapter" "Integrates lm-evaluation-harness with EvalHub: loads job specs, configures backends, runs evaluations, reports results" "Python (main.py)"
            lmEvalLib = container "lm-evaluation-harness" "Core evaluation framework: task management, model abstraction, evaluation orchestration, metrics computation" "Python Library (v0.4.8 fork)"
            ociPublisher = container "OCI Artifact Publisher" "Pushes evaluation results/traces to OCI registries using skopeo and olot" "Python CLI (scripts/oci.py)"
            offlineMetrics = container "Offline Metrics" "Pre-packaged evaluation metrics (accuracy, BLEU, F1, etc.) for disconnected environments" "Python Modules (metrics/)"
        }

        evalHub = softwareSystem "EvalHub Service" "Evaluation orchestration platform that manages evaluation job lifecycle" "Internal RHOAI"
        evalHubOperator = softwareSystem "EvalHub / TrustyAI Operator" "Creates and manages LMES Kubernetes Jobs" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving Runtime" "Serves LLM inference via OpenAI-compatible API (vLLM, TGI, etc.)" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry (Quay)" "Stores evaluation result artifacts as OCI images" "External"
        mlflow = softwareSystem "MLflow Tracking" "Experiment tracking for evaluation metrics and parameters" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Hosts benchmark datasets, tokenizer files, and model resources" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for pre-staged test data in disconnected environments" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Provides ConfigMaps and Secrets for job configuration" "Infrastructure"

        # Relationships
        dataScientist -> evalHub "Requests model evaluation"
        evalHubOperator -> lmes "Creates Kubernetes Job"
        k8sAPI -> lmes "Provides job spec (ConfigMap) and secrets"

        adapter -> lmEvalLib "Configures and invokes simple_evaluate()"
        adapter -> ociPublisher "Publishes evaluation artifacts"
        lmEvalLib -> offlineMetrics "Loads metrics in offline mode"

        adapter -> evalHub "Reports status, progress, results via callbacks" "HTTPS/443, Bearer Token"
        lmEvalLib -> modelServing "Sends completion/logprob requests" "HTTP(S), Bearer Token (OPENAI_API_KEY)"
        ociPublisher -> ociRegistry "Pushes OCI artifacts" "HTTPS/443, Docker auth"
        adapter -> mlflow "Logs metrics and parameters" "HTTPS, Bearer Token"
        lmEvalLib -> hfHub "Downloads datasets and tokenizers" "HTTPS/443, HF_TOKEN"
        adapter -> s3Storage "Retrieves pre-staged test data (offline)" "HTTPS/443, AWS IAM"
    }

    views {
        systemContext lmes "SystemContext" {
            include *
            autoLayout
        }

        container lmes "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #d4a373
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
