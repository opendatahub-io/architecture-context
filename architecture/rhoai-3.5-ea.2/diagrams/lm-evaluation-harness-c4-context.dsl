workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Defines evaluation jobs and reviews benchmark results"
        platformAdmin = person "Platform Admin" "Manages evaluation infrastructure and credentials"

        lmEvalHarness = softwareSystem "LM Evaluation Harness" "Batch-oriented execution environment for running LLM benchmark evaluations using lm-evaluation-harness framework" {
            adapter = container "LMEval Adapter" "EvalHub integration layer — reads job spec, configures lm-eval, runs benchmark, reports results via callbacks" "Python (main.py)"
            evalEngine = container "lm-evaluation-harness" "Core evaluation framework — task registry, model backends, metrics engine, evaluator" "Python Library (lm_eval/)"
            taskDefinitions = container "Task Definitions" "200+ benchmark task configurations (MMLU, ARC, HellaSwag, GPQA, IFEval, etc.) and Unitxt custom tasks" "YAML + Python"
            ociPublisher = container "OCI Artifact Publisher" "Packages evaluation results as OCI artifacts and pushes to registry via skopeo" "Python Script (scripts/oci.py)"
            s3Downloader = container "S3 Downloader" "Downloads model/dataset assets from S3-compatible storage" "Python Script (scripts/s3_downloader.py)"
        }

        trustyAI = softwareSystem "TrustyAI lm-eval-controller" "Kubernetes operator that creates evaluation Job pods" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Evaluation orchestration platform — receives status callbacks and results" "Internal RHOAI"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "OpenAI-compatible model serving endpoint (/v1/completions)" "Internal/External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for persisting evaluation results" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and metrics logging" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Public repository for benchmark datasets and model tokenizers" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for pre-staged model and dataset files" "External"
        k8sAPI = softwareSystem "Kubernetes API" "ConfigMap and Secret volume mounts for job configuration" "Platform"

        # User relationships
        dataScientist -> trustyAI "Defines evaluation job spec"
        dataScientist -> mlflow "Reviews evaluation results"
        platformAdmin -> ociRegistry "Manages registry credentials"
        platformAdmin -> s3Storage "Stages model files for air-gapped use"

        # Deployment relationship
        trustyAI -> lmEvalHarness "Creates Job pod with ConfigMap + Secrets"

        # Internal container relationships
        adapter -> evalEngine "Configures and invokes evaluation"
        evalEngine -> taskDefinitions "Loads benchmark task configurations"
        adapter -> ociPublisher "Triggers OCI artifact push"
        adapter -> s3Downloader "Downloads pre-staged assets"

        # External integrations
        adapter -> evalHub "Reports status transitions and results" "HTTPS/443, Bearer Token"
        evalEngine -> modelEndpoint "Sends prompt batches for evaluation" "HTTPS/443, Bearer Token"
        ociPublisher -> ociRegistry "Pushes result OCI artifacts" "HTTPS/443, Basic auth"
        adapter -> mlflow "Logs evaluation metrics" "HTTPS/443, Bearer Token"
        evalEngine -> hfHub "Downloads datasets and tokenizers" "HTTPS/443, HF_TOKEN"
        s3Downloader -> s3Storage "Downloads model/dataset files" "HTTPS/443, AWS IAM"
        lmEvalHarness -> k8sAPI "Reads ConfigMap and Secret mounts" "Volume mount"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
