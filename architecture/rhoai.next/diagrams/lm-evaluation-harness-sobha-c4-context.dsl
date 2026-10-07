workspace {
    model {
        operator = person "Platform Operator" "Manages LM evaluation jobs via trustyai-service-operator"

        lmesJob = softwareSystem "lm-evaluation-harness-sobha" "Batch-oriented language model evaluation harness that runs standardized benchmarks against LLM endpoints via EvalHub" {
            adapter = container "LMEvalAdapter (main.py)" "EvalHub adapter: job spec parsing, credential resolution, offline detection, result persistence, callback reporting" "Python"
            lmEval = container "lm_eval Engine" "Core evaluation framework providing benchmark tasks, model backends, and scoring logic" "Python (EleutherAI v0.4.8)"
            s3Downloader = container "S3 Downloader" "Downloads model/data assets from S3-compatible storage" "Python Script"
        }

        trustyaiOperator = softwareSystem "trustyai-service-operator" "Creates and manages Kubernetes jobs for LMEvalJob CRD processing" "Internal RHOAI"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "OpenAI-compatible model serving endpoint for completions" "External"
        evalHub = softwareSystem "EvalHub Service" "Evaluation orchestration platform managing job lifecycle and results" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Repository for tokenizers, models, and benchmark datasets" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model and data assets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for result persistence" "External"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and metrics logging" "External"

        trustyaiOperator -> lmesJob "Creates Kubernetes Job" "K8s API"
        adapter -> lmEval "Configures and runs evaluation"
        adapter -> s3Downloader "Triggers asset download"
        lmEval -> modelEndpoint "Sends evaluation prompts" "HTTPS /v1/completions"
        adapter -> evalHub "Reports job status and results" "HTTPS"
        lmEval -> hfHub "Downloads tokenizers and datasets" "HTTPS/443"
        s3Downloader -> s3Storage "Downloads model assets" "HTTPS (boto3)"
        adapter -> ociRegistry "Pushes result artifacts" "HTTPS (OCI)"
        adapter -> mlflow "Logs metrics" "HTTPS"
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
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
