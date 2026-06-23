workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Configures and triggers LLM red-teaming scans via eval-hub"

        garakAdapter = softwareSystem "TrustyAI Garak Adapter" "Automated LLM vulnerability scanning and red-teaming adapter using NVIDIA Garak framework" {
            adapter = container "GarakAdapter" "Eval-hub FrameworkAdapter — orchestrates scan lifecycle in simple and KFP modes" "Python Service"
            core = container "Core Module" "Framework-agnostic business logic: command building, config resolution, subprocess runner, pipeline steps" "Python Module"
            sdgModule = container "SDG Module" "Synthetic Data Generation using sdg-hub for adversarial prompt creation from harm taxonomies" "Python Module"
            intentsModule = container "Intents Module" "Taxonomy parsing, intent stub generation for context-aware scanning" "Python Module"
            resultUtils = container "Result Utils" "JSONL/AVID report parsing, metrics aggregation, Vega visualization, ART HTML reports" "Python Module"
            kfpPipeline = container "KFP Pipeline" "Six-step Kubeflow Pipeline: validate → taxonomy → SDG → prompts → scan → outputs" "KFP Definition"

            adapter -> core "Uses for scan execution"
            adapter -> sdgModule "Uses for adversarial prompt generation"
            adapter -> resultUtils "Uses for report generation"
            core -> intentsModule "Uses for intent stub generation"
            kfpPipeline -> core "Uses pipeline steps"
        }

        evalHub = softwareSystem "eval-hub" "Evaluation platform for RHOAI — provisions Jobs, receives results" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for scan artifacts and SDG output" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and artifact storage" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for scan output persistence" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap with KFP base image reference" "Internal RHOAI"

        targetLLM = softwareSystem "Target LLM" "The language model under test — OpenAI-compatible /v1 API" "External"
        sdgModelEndpoint = softwareSystem "SDG Model Endpoint" "LLM used for synthetic adversarial prompt generation" "External"
        judgeModel = softwareSystem "Judge Model" "LLM used for MulticlassJudge scoring in intents scans" "External"
        attackerModel = softwareSystem "Attacker Model" "LLM used for TAP jailbreak tree-of-attack pruning" "External"
        evaluatorModel = softwareSystem "Evaluator Model" "LLM used for TAP evaluator scoring" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model weights and tokenizer downloads" "External"
        googleTranslate = softwareSystem "Google Cloud Translate" "Translation service for multilingual probes" "External"

        dataScientist -> evalHub "Configures scan via eval-hub UI/API"
        evalHub -> garakAdapter "Creates K8s Job with JobSpec"
        garakAdapter -> targetLLM "Sends probe prompts" "HTTPS/443, API Key"
        garakAdapter -> sdgModelEndpoint "Generates adversarial prompts" "HTTPS/443, API Key"
        garakAdapter -> judgeModel "Scores attack results" "HTTPS/443, API Key"
        garakAdapter -> attackerModel "TAP jailbreak probes" "HTTPS/443, API Key"
        garakAdapter -> evaluatorModel "TAP evaluator scoring" "HTTPS/443, API Key"
        garakAdapter -> kfp "Submits and polls pipeline runs" "HTTPS/443, SA Token"
        garakAdapter -> s3Storage "Uploads/downloads scan artifacts" "HTTPS/443, AWS IAM"
        garakAdapter -> mlflow "Logs metrics and reports (optional)" "HTTP/HTTPS, Token"
        garakAdapter -> ociRegistry "Persists scan artifacts" "HTTPS/443, Registry creds"
        garakAdapter -> evalHub "Reports status and results" "HTTPS/443, Callback token"
        garakAdapter -> trustyaiOperator "Reads ConfigMap for KFP base image" "K8s API"
        garakAdapter -> huggingFace "Downloads model weights" "HTTPS/443, HF Token"
        garakAdapter -> googleTranslate "Translation probes" "HTTPS/443, Google API"
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
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
