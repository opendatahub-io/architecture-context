workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Creates LMEvalJob CRs to benchmark model quality"

        lmeval = softwareSystem "LM Evaluation Harness (LMEval)" "Batch evaluation job that runs standardized LLM benchmarks (MMLU, HellaSwag, GPQA, BBH) against models via OpenAI-compatible endpoints" {
            adapter = container "EvalHub Adapter" "Reads job spec, configures backends, manages lifecycle callbacks, reports results" "Python (main.py)"
            framework = container "lm_eval Framework" "Upstream EleutherAI evaluation framework — task definitions, model abstractions, metrics pipeline" "Python Library"
            localCompletions = container "local-completions Backend" "OpenAI-compatible HTTP client for model inference (max 128 concurrent requests)" "Python (api_models.py)"
            taskEngine = container "Task Engine" "157+ benchmarks, 6500+ YAML configurations, 56 offline metric modules" "Python + YAML"
            ociPublisher = container "OCI Artifact Publisher" "Pushes evaluation results to OCI registries via olot + skopeo" "Python Script (scripts/oci.py)"
        }

        trustyai = softwareSystem "TrustyAI Operator" "Creates and manages LMEvalJob CRs and Kubernetes Jobs" "Internal RHOAI"
        evalhub = softwareSystem "EvalHub Service" "Orchestrates evaluation jobs, receives status callbacks and results" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving Endpoint" "vLLM / TGI / other OpenAI-compatible inference server" "Internal RHOAI"
        hfhub = softwareSystem "HuggingFace Hub" "Hosts model tokenizers and benchmark datasets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Stores evaluation result artifacts" "External"
        s3 = softwareSystem "AWS S3 / IBM COS" "Object storage for model weights and datasets" "External"
        unitxt = softwareSystem "Unitxt Catalog" "Customizable textual data preparation and evaluation framework" "External"
        mlflow = softwareSystem "MLflow" "Optional experiment tracking for evaluation results" "External"

        # User interactions
        datascientist -> trustyai "Creates LMEvalJob CR via kubectl/dashboard"

        # TrustyAI creates jobs
        trustyai -> lmeval "Creates Kubernetes Job with LMEval image, ConfigMap, secrets"

        # Internal container interactions
        adapter -> framework "Configures and runs evaluation"
        framework -> localCompletions "Sends prompts via local-completions backend"
        framework -> taskEngine "Loads benchmark tasks and metrics"
        adapter -> ociPublisher "Publishes results as OCI artifacts"

        # External communications
        adapter -> evalhub "Reports job lifecycle status and final results" "HTTPS/443, Bearer Token"
        localCompletions -> modelServing "POST /v1/completions — sends prompts, receives completions" "HTTP(S)/configurable, Bearer Token"
        framework -> hfhub "Downloads tokenizers and benchmark datasets" "HTTPS/443, Bearer Token (HF_TOKEN)"
        ociPublisher -> ociRegistry "Pushes result artifacts via skopeo" "HTTPS/443, Docker auth"
        framework -> s3 "Loads model weights and datasets from object storage" "HTTPS/443, AWS IAM"
        framework -> unitxt "Loads custom task/metric definitions" "Python API"
        adapter -> mlflow "Persists results as MLflow experiment runs (optional)" "HTTP(S)/configurable"
    }

    views {
        systemContext lmeval "SystemContext" {
            include *
            autoLayout
        }

        container lmeval "Containers" {
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
