workspace {
    model {
        dataScientist = person "Data Scientist" "Configures and triggers model evaluations via EvalHub"
        platformOp = person "Platform Operator" "Manages cluster, OCI registry credentials, and air-gapped storage"

        lmeval = softwareSystem "LM Evaluation Harness" "Batch job that evaluates language models using 200+ benchmarks against inference endpoints" {
            adapter = container "LMEval Adapter" "Bridges EvalHub JobSpec to lm-eval simple_evaluate() API" "Python 3.11 (main.py)"
            evalLibrary = container "lm-evaluation-harness" "Core evaluation framework: task management, model backends, metrics" "Python Library (0.4.8)"
            ociPublisher = container "OCI Artifact Publisher" "Creates and pushes evaluation result artifacts" "Python Script (scripts/oci.py)"
            s3Downloader = container "S3 Downloader" "Pre-populates HuggingFace cache from S3 for air-gapped environments" "Python Script (scripts/s3_downloader.py)"
        }

        evalHub = softwareSystem "EvalHub" "Model evaluation platform that orchestrates evaluation jobs" "Internal RHOAI"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "OpenAI-compatible API serving the model under evaluation" "Internal"
        hfHub = softwareSystem "HuggingFace Hub" "Public model and dataset registry" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container and artifact registry for persisting evaluation results" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for cached models/datasets in air-gapped deployments" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and metrics logging" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes" "Container orchestration platform" "Infrastructure"

        # User interactions
        dataScientist -> evalHub "Configures evaluation job"
        platformOp -> ociRegistry "Manages registry credentials"
        platformOp -> s3Storage "Provisions cached datasets"

        # EvalHub → LMEval
        evalHub -> lmeval "Creates Kubernetes Job with ConfigMap JobSpec"

        # LMEval internal flows
        adapter -> evalLibrary "Translates JobSpec to simple_evaluate() call"
        adapter -> ociPublisher "Triggers artifact push on completion"
        s3Downloader -> evalLibrary "Provides local cache for air-gapped mode"

        # LMEval → External
        evalLibrary -> modelEndpoint "POST /v1/completions (evaluation prompts)" "HTTPS/TLS 1.2+"
        evalLibrary -> hfHub "Downloads tokenizers and datasets" "HTTPS/443"
        adapter -> evalHub "Reports status phases and results via callbacks" "HTTPS/443"
        ociPublisher -> ociRegistry "Pushes result artifacts via skopeo" "HTTPS/443"
        s3Downloader -> s3Storage "Downloads cached models/datasets" "HTTPS/443"
        adapter -> mlflow "Logs metrics and run metadata" "HTTPS/443"

        # Infrastructure
        k8s -> lmeval "Schedules and manages batch Job lifecycle"
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
            element "Infrastructure" {
                background #6c8ebf
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
