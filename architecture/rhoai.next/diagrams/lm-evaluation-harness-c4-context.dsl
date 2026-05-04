workspace {
    model {
        dataScientist = person "Data Scientist" "Creates LMEvalJob CRDs to evaluate language models against standardized benchmarks"

        lmEvalHarness = softwareSystem "lm-evaluation-harness" "Batch-oriented runtime for executing language model evaluations using 6,500+ benchmark tasks as Kubernetes Jobs" {
            adapter = container "EvalHub Adapter" "Bridges EvalHub job lifecycle with lm-eval framework — loads job spec, configures model backend, runs evaluation, publishes results" "Python (main.py)"
            lmEvalCore = container "lm_eval Core Library" "Core evaluation framework providing task management, model abstraction, metrics computation, caching, and result aggregation" "Python Library"
            modelBackend = container "Model Backend (local-completions)" "OpenAI-compatible API client for sending evaluation prompts to inference endpoints with async support (up to 128 concurrent)" "Python (api_models.py)"
            taskSystem = container "Task YAML Definitions" "6,500+ YAML-defined benchmark task configurations (MMLU, HellaSwag, ARC, etc.)" "YAML Configuration"
            unitxt = container "Unitxt Integration" "Flexible textual data preparation framework for customizable task definitions" "Python Module"
        }

        trustyaiOperator = softwareSystem "trustyai-service-operator" "Creates and manages Kubernetes Jobs from LMEvalJob CRDs" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Receives job status updates, evaluation results, and manages evaluation lifecycle" "Internal RHOAI"
        modelInference = softwareSystem "Model Inference Endpoint" "Serves model completions via OpenAI-compatible API (vLLM, TGI, etc.)" "Internal"
        ociRegistry = softwareSystem "OCI Registry" "Stores evaluation result artifacts as OCI images" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Logs evaluation metrics and run metadata for traceability" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Provides benchmark datasets, tokenizer models, and gated resources" "External"
        s3Storage = softwareSystem "S3/COS Object Storage" "Provides pre-cached datasets for offline/disconnected evaluations" "External"
        wandb = softwareSystem "Weights & Biases" "Optional experiment tracking and logging" "External"

        dataScientist -> trustyaiOperator "Creates LMEvalJob CR via kubectl"
        trustyaiOperator -> lmEvalHarness "Creates Kubernetes Job with ConfigMap (job spec at /meta/job.json)"
        lmEvalHarness -> evalHub "Reports job status phases and evaluation results" "HTTPS/443, Bearer Token"
        lmEvalHarness -> modelInference "Sends evaluation prompts, receives completions" "HTTPS/443, Bearer Token (OPENAI_API_KEY)"
        lmEvalHarness -> ociRegistry "Pushes evaluation result artifacts" "HTTPS/443, Registry Auth"
        lmEvalHarness -> mlflow "Logs evaluation metrics and run metadata" "HTTPS, Configurable Auth"
        lmEvalHarness -> hfHub "Downloads benchmark datasets and tokenizers" "HTTPS/443, HF_TOKEN"
        lmEvalHarness -> s3Storage "Accesses offline test data caches" "HTTPS/443, AWS IAM"
        lmEvalHarness -> wandb "Optional experiment tracking" "HTTPS/443"

        adapter -> lmEvalCore "Loads job spec, invokes simple_evaluate()"
        adapter -> evalHub "Callbacks: report_status, report_results" "HTTPS"
        adapter -> ociRegistry "Pushes OCI artifacts via olot library" "HTTPS"
        adapter -> mlflow "Logs metrics via mlflow.save" "HTTPS"
        lmEvalCore -> modelBackend "Routes prompts to model backend"
        lmEvalCore -> taskSystem "Loads benchmark task configurations"
        lmEvalCore -> unitxt "Loads Unitxt-defined dynamic tasks"
        modelBackend -> modelInference "POST /v1/completions (async, up to 128 concurrent)" "HTTPS, TLS 1.2+"
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
                shape RoundedBox
            }
        }
    }
}
