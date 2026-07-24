workspace {
    model {
        dataScientist = person "Data Scientist" "Creates LMEvalJob CRs to benchmark language models"
        platformEngineer = person "Platform Engineer" "Configures model endpoints and evaluation infrastructure"

        lmeval = softwareSystem "LM Evaluation Harness" "Batch job runtime for executing language model benchmarks using EleutherAI's lm-evaluation-harness with EvalHub integration" {
            adapter = container "EvalHub Adapter" "Orchestrates benchmark execution, credential management, status reporting, and artifact persistence" "Python (main.py)"
            harness = container "lm-evaluation-harness" "Core evaluation framework with 150+ benchmarks, metrics, and task management" "Python Library (EleutherAI fork)"
            s3Downloader = container "S3 Downloader" "Downloads model/dataset assets from S3-compatible storage for offline evaluation" "Python Script"
            ociBuilder = container "OCI Artifact Builder" "Creates and pushes OCI artifacts containing evaluation results and traces" "Python Script + skopeo"
        }

        trustyai = softwareSystem "TrustyAI Operator" "Manages LMEvalJob CRD lifecycle, creates Kubernetes Jobs" "Internal RHOAI"
        evalhub = softwareSystem "EvalHub Service" "Job orchestration, credential management, and result persistence platform" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking and metric persistence" "Internal RHOAI"
        modelServer = softwareSystem "Model Inference Server" "Target LLM being evaluated via OpenAI-compatible API" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Tokenizer and benchmark dataset repository" "External"
        ociRegistry = softwareSystem "OCI Registry (Quay.io)" "Stores evaluation result OCI artifacts" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Model and dataset asset storage for air-gapped deployments" "External"

        # User interactions
        dataScientist -> trustyai "Creates LMEvalJob CR via kubectl/Dashboard"
        platformEngineer -> modelServer "Deploys and configures model endpoint"

        # TrustyAI creates Jobs
        trustyai -> lmeval "Creates K8s Job with container image + ConfigMap"

        # Internal container interactions
        adapter -> harness "Invokes simple_evaluate()"
        adapter -> ociBuilder "Creates result artifacts post-evaluation"
        s3Downloader -> s3Storage "Downloads assets for offline mode" "HTTPS/443 AWS IAM"

        # Egress from adapter
        adapter -> evalhub "Reports status updates and results" "HTTPS/443 Bearer Token"
        adapter -> mlflow "Persists experiment runs" "HTTPS/443"
        ociBuilder -> ociRegistry "Pushes result OCI artifacts" "HTTPS/443 Docker auth"

        # Egress from harness
        harness -> modelServer "Sends evaluation prompts via /v1/completions" "HTTPS/443 Bearer Token"
        harness -> hfHub "Downloads tokenizers and datasets" "HTTPS/443 HF_TOKEN"
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
            element "Person" {
                shape Person
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
