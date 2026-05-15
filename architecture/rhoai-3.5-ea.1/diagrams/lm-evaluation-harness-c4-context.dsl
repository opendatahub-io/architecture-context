workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Triggers model evaluations via TrustyAI operator or EvalHub"

        lmEvalHarness = softwareSystem "LM Evaluation Harness" "Batch job for running standardized language model evaluations using 6,500+ benchmark tasks (EleutherAI fork)" {
            adapter = container "LMEval Adapter" "Bridges EvalHub job specs to lm_eval simple_evaluate() calls; manages lifecycle, credentials, offline detection, OCI persistence, and callbacks" "Python (main.py)"
            evalEngine = container "lm_eval Library" "Core evaluation engine with task management, model backends, metrics computation, result aggregation, and caching" "Python (EleutherAI v0.4.8 fork)"
            taskDefs = container "Task Definitions" "6,586 declarative benchmark YAML files across 157 categories (NLU, NLG, reasoning, multilingual, medical, code, safety)" "YAML Configuration"
            metrics = container "Metric Modules" "54 offline-capable evaluation metrics (accuracy, BLEU, ROUGE, F1, BERTScore, perplexity)" "Python/YAML"
            ociPublisher = container "OCI Artifact Publisher" "Packages evaluation output into OCI artifacts and pushes to registry via skopeo" "Python (scripts/oci.py)"
        }

        trustyaiOperator = softwareSystem "TrustyAI LMEval Operator" "Creates and manages evaluation Job pods, mounts job specs and secrets" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub Service" "Evaluation platform that receives job status updates and results via callbacks" "Internal RHOAI"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "The language model under evaluation (vLLM, TGI, or OpenAI-compatible)" "Internal/External"
        ociRegistry = softwareSystem "OCI Registry" "Stores evaluation results as OCI artifacts (e.g., Quay)" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking and metric logging" "Internal/External"
        hfHub = softwareSystem "HuggingFace Hub" "Downloads tokenizers, datasets, and evaluation metrics" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Dataset and model artifact storage" "External"

        # User interactions
        dataScientist -> trustyaiOperator "Creates LMEvalJob CR" "kubectl / EvalHub UI"

        # Operator creates job
        trustyaiOperator -> lmEvalHarness "Creates Job Pod (mounts job.json, secrets, PVC)" "Kubernetes API"

        # Internal container relationships
        adapter -> evalEngine "Calls simple_evaluate()" "Python in-process"
        evalEngine -> taskDefs "Loads benchmark tasks" "Filesystem"
        evalEngine -> metrics "Computes evaluation metrics" "Python in-process"
        adapter -> ociPublisher "Publishes result artifacts" "Python in-process"

        # External integrations
        adapter -> evalHub "Reports job status and results" "HTTPS/443, Bearer Token"
        evalEngine -> modelEndpoint "Sends completion requests" "HTTP(S), OPENAI_API_KEY Bearer Token"
        ociPublisher -> ociRegistry "Pushes OCI artifacts" "HTTPS/443, Registry credentials"
        evalEngine -> hfHub "Downloads tokenizers and datasets" "HTTPS/443, HF_TOKEN"
        adapter -> mlflow "Logs experiment metrics" "HTTP(S), evalhub SDK"
        evalEngine -> s3Storage "Accesses datasets" "HTTPS/443, AWS IAM"
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
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal/External" {
                background #d4a017
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
