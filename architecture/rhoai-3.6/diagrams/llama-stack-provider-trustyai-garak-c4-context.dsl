workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Submits red-teaming evaluation jobs via eval-hub"

        garakAdapter = softwareSystem "Garak Eval-Hub Adapter" "Red-teaming evaluation adapter for eval-hub platform, runs OWASP/AVID/CWE/intents vulnerability scans against LLMs" {
            adapter = container "GarakAdapter" "Main FrameworkAdapter: benchmark resolution, config merging, simple/KFP dispatch, result parsing" "Python"
            kfpAdapter = container "GarakKFPAdapter" "KFP-only adapter subclass that forces KFP execution mode" "Python"
            configResolver = container "Config Resolution" "Deep-merge user overrides onto benchmark profiles (OWASP, AVID, CWE, intents)" "Python"
            pipelineSteps = container "Pipeline Steps" "Validation, SDG, prompt normalization, 13-step API key resolution" "Python"
            garakRunner = container "Garak Runner" "Subprocess runner for garak CLI execution" "Python"
            kfpPipeline = container "KFP Pipeline" "Six-step Kubeflow Pipeline: validate, taxonomy, SDG, prompts, scan, outputs" "Python/KFP"
        }

        evalHub = softwareSystem "eval-hub" "Evaluation job orchestration platform" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        trustyaiOp = softwareSystem "TrustyAI Service Operator" "AI trustworthiness operator providing ConfigMap for base image resolution" "Internal RHOAI"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for scan artifacts, SDG outputs, taxonomy data" "External"
        modelEndpoint = softwareSystem "Model Inference Endpoint" "Target LLM being scanned for vulnerabilities" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for scan result persistence" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and artifact logging" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Model and tokenizer downloads" "External"

        dataScientist -> evalHub "Submits evaluation job"
        evalHub -> garakAdapter "Creates K8s Job with ConfigMap and Secrets"

        adapter -> garakRunner "Dispatches simple mode scans"
        adapter -> kfpPipeline "Dispatches KFP mode scans"
        adapter -> configResolver "Resolves benchmark configuration"
        adapter -> pipelineSteps "Uses validation and key resolution"
        kfpAdapter -> adapter "Extends (forces KFP mode)"

        garakAdapter -> modelEndpoint "Scans target model" "HTTPS, API key Bearer"
        garakAdapter -> s3 "Uploads/downloads scan artifacts" "HTTPS/443, AWS credentials"
        garakAdapter -> kfp "Submits and polls KFP pipelines" "HTTP/HTTPS, SA token"
        garakAdapter -> ociRegistry "Pushes scan artifacts" "HTTPS/443, OCI auth"
        garakAdapter -> mlflow "Logs experiments and artifacts" "HTTP/HTTPS"
        garakAdapter -> hfHub "Downloads models/tokenizers" "HTTPS/443"
        garakAdapter -> evalHub "Reports results via sidecar" "HTTP localhost"
        garakAdapter -> trustyaiOp "Reads ConfigMap for base image" "K8s API"
    }

    views {
        systemContext garakAdapter "SystemContext" {
            include *
            autoLayout
        }

        container garakAdapter "Containers" {
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
