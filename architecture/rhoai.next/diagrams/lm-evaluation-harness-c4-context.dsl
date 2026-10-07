workspace {
    model {
        datascientist = person "Data Scientist" "Defines evaluation jobs via EvalHub"
        platformadmin = person "Platform Admin" "Manages TrustyAI operator and model deployments"

        lmesJob = softwareSystem "lm-evaluation-harness" "Batch evaluation framework for language models — runs as ephemeral Kubernetes Jobs" {
            adapter = container "LMEvalAdapter" "EvalHub framework adapter — job lifecycle, error sanitization, credential resolution, OCI artifact persistence" "Python (main.py)"
            lmeval = container "lm_eval" "Core evaluation engine — 60+ benchmarks, task definitions, scoring metrics, simple_evaluate() API" "Python Package (v0.4.8)"
            s3downloader = container "S3 Downloader" "Pre-fetches model assets and datasets from S3-compatible storage" "Python Script"
            ociutil = container "OCI Utility" "Creates and pushes evaluation result OCI artifacts via olot and skopeo" "Python Script"

            adapter -> lmeval "Wraps simple_evaluate()" "Python API"
            adapter -> ociutil "Creates OCI artifacts" "Python API"
            adapter -> s3downloader "Pre-fetches assets" "Python API"
        }

        trustyai = softwareSystem "TrustyAI Operator" "Manages LMEvalJob CRDs and creates Kubernetes Jobs" "Internal RHOAI"
        evalhub = softwareSystem "EvalHub Service" "Evaluation orchestration — job specs, status tracking, result aggregation" "Internal RHOAI"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "Serves model completions via OpenAI-compatible API (vLLM, TGI, etc.)" "Internal/External"
        hfhub = softwareSystem "HuggingFace Hub" "Hosts evaluation datasets, tokenizers, and metric definitions" "External"
        s3storage = softwareSystem "S3-Compatible Storage" "Stores pre-staged model assets and datasets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Stores evaluation result artifacts as OCI images" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Logs evaluation metrics and run metadata" "External"

        datascientist -> evalhub "Creates evaluation job specification" "HTTPS/443"
        trustyai -> lmesJob "Creates Kubernetes Job from LMEvalJob CRD" "Kubernetes API"
        lmesJob -> evalhub "Reports job status and evaluation results" "HTTPS/443, Bearer Token"
        lmesJob -> modelEndpoint "Sends prompts, receives completions" "HTTPS, OPENAI_API_KEY"
        lmesJob -> hfhub "Downloads datasets and tokenizers" "HTTPS/443, HF_TOKEN"
        lmesJob -> s3storage "Downloads pre-staged assets" "HTTPS, AWS v4 Signing"
        lmesJob -> ociRegistry "Pushes result artifacts" "HTTPS/443, Registry Credentials"
        lmesJob -> mlflow "Logs evaluation metrics" "HTTPS, Configurable Auth"
    }

    views {
        systemContext lmesJob "SystemContext" {
            include *
            autoLayout
        }

        container lmesJob "Containers" {
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
            element "Internal/External" {
                background #f5a623
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
