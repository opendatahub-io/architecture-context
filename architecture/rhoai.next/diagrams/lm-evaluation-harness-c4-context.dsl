workspace {
    model {
        datascientist = person "Data Scientist" "Creates LMEvalJob CRs to evaluate language models against benchmarks"

        lmeval = softwareSystem "LM Evaluation Harness" "Batch-oriented runtime for language model evaluation using lm-evaluation-harness framework" {
            adapter = container "LMEval Adapter" "EvalHub adapter: reads job spec, configures lm-eval, runs benchmarks, reports results" "Python (main.py)"
            lmevalLib = container "lm_eval Library" "Core evaluation framework: task management, model abstraction, metric computation" "Python Library"
            ociPublisher = container "OCI Artifact Publisher" "Packages evaluation results as OCI artifacts and pushes to registry via skopeo" "Python (scripts/oci.py)"
            s3Downloader = container "S3 Downloader" "Downloads test data from S3 for offline/air-gapped evaluations" "Python (scripts/s3_downloader.py)"
        }

        trustyaiOperator = softwareSystem "TrustyAI LMEval Operator" "Creates Kubernetes Jobs from LMEvalJob custom resources" "Internal RHOAI"
        evalhub = softwareSystem "EvalHub Service" "Evaluation orchestration platform: job management, status tracking, results aggregation" "Internal RHOAI"
        inferenceEndpoint = softwareSystem "Inference Endpoint (vLLM/TGI)" "OpenAI-compatible model serving: receives prompts, returns completions" "Internal/External"
        ociRegistry = softwareSystem "OCI Registry (Quay)" "Stores evaluation result OCI artifacts" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Public repository for benchmark datasets and tokenizers" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for offline test data in air-gapped environments" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking: stores evaluation metrics and metadata" "Internal RHOAI"

        # Person interactions
        datascientist -> trustyaiOperator "Creates LMEvalJob CR via kubectl"

        # Operator creates the job
        trustyaiOperator -> lmeval "Creates K8s Job with LMEval container"

        # LMEval external interactions
        lmeval -> evalhub "Reports status, progress, final results" "HTTPS/443, Bearer Token"
        lmeval -> inferenceEndpoint "Sends evaluation prompts, receives completions" "HTTP(S), Bearer Token"
        lmeval -> ociRegistry "Pushes evaluation result artifacts" "HTTPS/443, Docker Auth"
        lmeval -> hfHub "Downloads benchmark datasets and tokenizers" "HTTPS/443, Bearer Token (optional)"
        lmeval -> s3Storage "Downloads offline test data (air-gapped mode)" "HTTPS/443, AWS IAM"
        lmeval -> mlflow "Persists evaluation metrics" "HTTP(S), configurable"

        # Container-level interactions
        adapter -> lmevalLib "Configures and invokes simple_evaluate()"
        adapter -> ociPublisher "Triggers result artifact push"
        s3Downloader -> s3Storage "Downloads datasets to /test_data"
        lmevalLib -> inferenceEndpoint "POST /v1/completions (local-completions backend)"
        ociPublisher -> ociRegistry "skopeo push OCI artifacts"
        adapter -> evalhub "Status callbacks (INITIALIZING, POST_PROCESSING, COMPLETED)"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
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
            element "Internal/External" {
                background #d4a017
                color #ffffff
            }
        }
    }
}
