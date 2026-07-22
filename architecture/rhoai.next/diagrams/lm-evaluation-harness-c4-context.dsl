workspace {
    model {
        dataScientist = person "Data Scientist" "Creates LMEvalJob CRs to benchmark language models"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and model deployments"

        lmEvalHarness = softwareSystem "LM Evaluation Harness" "Batch-oriented LLM evaluation framework that runs benchmarks against model endpoints and reports results" {
            adapter = container "LMEval Adapter" "Orchestrates evaluation: reads job spec, configures model backend, runs lm-eval, reports results via callbacks" "Python (main.py)"
            lmEvalLib = container "lm-eval Library" "Core evaluation framework providing task management, model backends, metrics, and evaluation pipeline" "Python Library (EleutherAI upstream)"
            ociPublisher = container "OCI Artifact Publisher" "Pushes evaluation results as OCI artifacts to registries using skopeo and olot" "Python Script"
            s3Downloader = container "S3 Downloader" "Downloads model assets from S3-compatible storage for offline/air-gapped evaluations" "Python Script (boto3)"
        }

        lmEvalOperator = softwareSystem "TrustyAI LMEval Operator" "Creates and manages Kubernetes Jobs for LMEval execution" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Orchestrates evaluation jobs, receives status callbacks and results" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving Endpoint" "Serves LLM via OpenAI-compatible API (vLLM, TGI, etc.)" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and metric logging" "Internal RHOAI"

        ociRegistry = softwareSystem "OCI Registry (Quay)" "Stores evaluation results as OCI artifacts" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Hosts benchmark datasets, tokenizers, and model configs" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Stores pre-staged model weights and datasets for air-gapped mode" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Manages Jobs, ConfigMaps, Secrets" "Infrastructure"

        # Relationships
        dataScientist -> lmEvalOperator "Creates LMEvalJob CR via kubectl/Dashboard"
        lmEvalOperator -> k8sAPI "Creates Job + ConfigMap + Secrets" "HTTPS/6443"
        k8sAPI -> lmEvalHarness "Schedules Job Pod"

        adapter -> evalHub "Reports job status and results" "HTTPS/443 Bearer Token"
        lmEvalLib -> modelServing "Sends evaluation prompts" "HTTPS/443 OpenAI API"
        ociPublisher -> ociRegistry "Pushes result artifacts" "HTTPS/443 Docker Auth"
        lmEvalLib -> hfHub "Downloads datasets and tokenizers" "HTTPS/443 HF_TOKEN"
        s3Downloader -> s3Storage "Downloads model assets" "HTTPS/443 AWS IAM"
        adapter -> mlflow "Logs metrics and results" "HTTPS/443 Bearer Token"

        adapter -> lmEvalLib "Configures and runs evaluations"
        adapter -> ociPublisher "Triggers result persistence"
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
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
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
