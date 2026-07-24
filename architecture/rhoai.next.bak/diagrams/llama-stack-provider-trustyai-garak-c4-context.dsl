workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Configures and triggers LLM security scans via eval-hub"

        garakProvider = softwareSystem "Garak Provider" "Automated LLM red-teaming evaluation adapter for eval-hub — runs Garak vulnerability scans as K8s Jobs or KFP Pipelines" {
            garakAdapter = container "GarakAdapter" "Main eval-hub FrameworkAdapter — orchestrates scans, parses results, reports metrics" "Python 3.12"
            garakKFPAdapter = container "GarakKFPAdapter" "Subclass forcing KFP execution mode for pipeline-based scans" "Python 3.12"
            core = container "Core Library" "Framework-agnostic: config resolution, command building, subprocess management, pipeline steps" "Python 3.12"
            config = container "Config Module" "Pydantic models, predefined scan profiles (OWASP, AVID, CWE, quality, intents)" "Python 3.12"
            resultUtils = container "Result Utils" "Parses Garak JSONL/AVID reports, computes TBSA scoring, generates HTML reports (Jinja2 + Vega)" "Python 3.12"
            sdg = container "SDG Module" "Synthetic Data Generation via sdg-hub for adversarial prompt generation from harm taxonomies" "Python 3.12"
            intents = container "Intents Module" "Policy taxonomy dataset loading and Garak intent stub/typology file generation" "Python 3.12"
            garakCLI = container "Garak CLI" "NVIDIA Garak red-teaming framework executed as subprocess (os.setsid process group)" "Python subprocess"
        }

        evalHub = softwareSystem "eval-hub" "Evaluation orchestration platform — dispatches JobSpecs, collects results" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration for multi-step KFP mode scans (6-step pipeline)" "Internal RHOAI"
        s3 = softwareSystem "S3 Storage" "S3-compatible object storage for artifact transfer — scan results, SDG output, taxonomy files" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and artifact persistence for scan results and reports" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for scan result persistence (OCIArtifactSpec)" "External"
        targetLLM = softwareSystem "Target LLM" "Model under test — OpenAI-compatible /v1/chat/completions endpoint" "External"
        judgeLLM = softwareSystem "Judge LLM" "MulticlassJudge detector for response evaluation (intents mode)" "External"
        attackerLLM = softwareSystem "Attacker LLM" "TAPIntent tree-of-attacks adversarial prompt generator (intents mode)" "External"
        evaluatorLLM = softwareSystem "Evaluator LLM" "TAPIntent evaluator — scores attack effectiveness (intents mode)" "External"
        sdgLLM = softwareSystem "SDG LLM" "LLM for Synthetic Data Generation of adversarial prompts from taxonomies (intents mode)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model weights and tokenizer downloads for Garak probes" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for reading Secrets, ConfigMaps" "Infrastructure"
        operatorConfig = softwareSystem "trustyai-service-operator-config" "ConfigMap providing garak-provider-image reference" "Internal RHOAI"

        // Relationships
        dataScientist -> evalHub "Configures scan via eval-hub UI/API"
        evalHub -> garakProvider "Dispatches JobSpec (ConfigMap mount)"

        garakAdapter -> core "Resolves config, builds commands, runs subprocess"
        garakAdapter -> resultUtils "Parses scan results, generates HTML reports"
        garakAdapter -> sdg "Generates adversarial prompts (intents mode)"
        garakAdapter -> intents "Loads policy taxonomies (intents mode)"
        garakKFPAdapter -> garakAdapter "Extends (forces KFP mode)"
        core -> config "Reads scan profiles"
        garakAdapter -> garakCLI "Spawns subprocess (os.setsid)"

        garakCLI -> targetLLM "POST /v1/chat/completions" "HTTPS/443, Bearer Token"
        garakCLI -> judgeLLM "POST /v1/chat/completions (intents)" "HTTPS/443, JUDGE_API_KEY"
        garakCLI -> attackerLLM "POST /v1/chat/completions (intents)" "HTTPS/443, ATTACKER_API_KEY"
        garakCLI -> evaluatorLLM "POST /v1/chat/completions (intents)" "HTTPS/443, EVALUATOR_API_KEY"
        garakAdapter -> sdgLLM "POST /v1/chat/completions (SDG)" "HTTPS/443, SDG_API_KEY"
        garakAdapter -> s3 "Upload/download artifacts" "HTTPS/443, AWS IAM"
        garakKFPAdapter -> kfp "Submit 6-step pipeline" "HTTPS/443, SA Token"
        garakAdapter -> mlflow "Log experiments and artifacts" "HTTPS/443, Bearer Token"
        garakAdapter -> ociRegistry "Push scan artifacts" "HTTPS/443, Registry creds"
        garakAdapter -> evalHub "Report JobResults (sidecar callback)"
        garakAdapter -> k8sAPI "Read Secrets and ConfigMaps" "HTTPS/443, SA Token"
        k8sAPI -> operatorConfig "Reads garak-provider-image"
        garakCLI -> huggingface "Download models/tokenizers" "HTTPS/443"
    }

    views {
        systemContext garakProvider "SystemContext" {
            include *
            autoLayout
        }

        container garakProvider "Containers" {
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
