workspace {
    model {
        dataScientist = person "Data Scientist" "Creates evaluation jobs to benchmark ML models"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and operator configuration"

        lmeval = softwareSystem "LM Evaluation Harness" "Batch-oriented runtime for language model benchmark evaluations using lm-evaluation-harness framework" {
            adapter = container "LMEval Adapter" "EvalHub adapter: reads job spec, configures lm-eval, runs benchmarks, reports results" "Python (main.py)"
            lmevalLib = container "lm_eval Library" "Core evaluation framework: task management, model abstraction, metric computation" "Python Library"
            ociPublisher = container "OCI Artifact Publisher" "Packages evaluation output as OCI artifacts and pushes to registry" "Python (scripts/oci.py) + skopeo"
            s3Downloader = container "S3 Downloader" "Downloads test data from S3-compatible storage for offline evaluation mode" "Python (scripts/s3_downloader.py)"
        }

        trustyaiOperator = softwareSystem "TrustyAI LMEval Operator" "Creates Kubernetes Jobs from LMEvalJob custom resources" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Job orchestration platform for evaluation lifecycle management" "Internal RHOAI"
        inferenceEndpoint = softwareSystem "Inference Endpoint" "OpenAI-compatible model serving (vLLM, TGI)" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and result comparison" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry (Quay)" "Container and artifact registry for evaluation results" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public model and dataset repository" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for offline test data" "External"

        # User interactions
        dataScientist -> trustyaiOperator "Creates LMEvalJob CR via kubectl"
        platformAdmin -> trustyaiOperator "Configures operator settings"

        # Orchestration
        trustyaiOperator -> lmeval "Creates K8s Job with ConfigMap and Secrets"

        # Internal component interactions
        adapter -> lmevalLib "Configures and invokes simple_evaluate()"
        adapter -> ociPublisher "Triggers OCI artifact push"
        s3Downloader -> lmevalLib "Populates /test_data for offline mode"

        # External interactions
        adapter -> evalHub "Reports job status (INITIALIZING → COMPLETED)" "HTTPS/443, Bearer Token"
        lmevalLib -> inferenceEndpoint "Sends evaluation prompts, receives completions" "HTTP(S), Bearer Token"
        ociPublisher -> ociRegistry "Pushes evaluation result OCI artifacts" "HTTPS/443, Docker Auth"
        lmevalLib -> huggingfaceHub "Downloads benchmark datasets and tokenizers" "HTTPS/443, Bearer Token"
        s3Downloader -> s3Storage "Downloads offline test data" "HTTPS/443, AWS IAM"
        adapter -> mlflow "Persists evaluation metrics" "HTTP(S)"
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
