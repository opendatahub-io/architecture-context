workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and runs LLM vulnerability scans and red-team evaluations"

        garakProvider = softwareSystem "TrustyAI Garak LLS Provider" "Out-of-tree Llama Stack evaluation provider and eval-hub adapter for automated LLM red-teaming using NVIDIA Garak" {
            inlineProvider = container "Inline Provider" "Runs garak as subprocess within Llama Stack server process" "Python Module"
            remoteProvider = container "Remote Provider" "Submits garak scans as Kubeflow Pipeline runs" "Python Module"
            evalHubAdapter = container "Eval-Hub Adapter" "Standalone adapter for RHOAI evaluation platform (simple + kfp modes)" "Python Module"
            coreModule = container "Core Module" "Shared pipeline step logic: validation, taxonomy, SDG, scan execution, result parsing" "Python Module"
            configModule = container "Config Module" "Benchmark profiles (OWASP, AVID, CWE, intents), deep-merge config, API key resolution" "Python Module"
            garakRunner = container "Garak Runner" "Process management: subprocess spawn, output streaming, timeout + SIGTERM/SIGKILL" "Python Module"
            containerImage = container "odh-trustyai-garak-lls-provider-dsp" "Production container image for KFP pipeline steps and eval-hub K8s Job pods" "Container (UBI9, Python 3.12)"
        }

        llamaStack = softwareSystem "Llama Stack Distribution" "Hosts AI providers as plugins, manages server lifecycle" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines (KFP/DSPA)" "Kubeflow Pipelines for running ML workflows in Kubernetes" "Internal RHOAI"
        evalHub = softwareSystem "Eval-Hub Service" "RHOAI evaluation platform orchestrating adapter pods" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap with garak-provider-image for KFP base image resolution" "Internal RHOAI"

        vllm = softwareSystem "Target LLM (vLLM)" "Inference endpoint being scanned for vulnerabilities" "External"
        sdgModel = softwareSystem "SDG Model Endpoint" "Model for synthetic data generation (intents benchmarks)" "External"
        judgeModels = softwareSystem "Judge/Attacker/Evaluator Models" "Auxiliary models for intents TAP attack, classification, evaluation" "External"
        shieldModels = softwareSystem "Shield Models (Llama Guard, Prompt Guard)" "Input/output guardrail models for safety testing" "External"

        s3 = softwareSystem "S3 Object Storage" "Artifact transfer: scan reports, SDG outputs, taxonomy files" "External"
        ociRegistry = softwareSystem "OCI Registry" "Persistent storage for scan artifact bundles" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and artifact logging" "External"
        postgresql = softwareSystem "PostgreSQL" "Llama Stack distribution state storage" "External"
        k8sApi = softwareSystem "Kubernetes API" "Secrets and ConfigMap access" "Infrastructure"

        # User interactions
        user -> llamaStack "Creates InferenceService eval runs via Llama Stack API" "HTTP/8321"
        user -> evalHub "Triggers evaluations via eval-hub UI/API"

        # Llama Stack hosting
        llamaStack -> garakProvider "Loads inline + remote providers as plugins" "In-process"

        # Provider to KFP
        garakProvider -> dspa "Submits pipeline runs (remote + kfp modes)" "HTTPS/443, Bearer Token"

        # Model scanning
        garakProvider -> vllm "Sends probe prompts for vulnerability assessment" "HTTPS/443, Bearer Token"
        garakProvider -> sdgModel "Generates synthetic red-team prompts" "HTTPS/443, Bearer Token"
        garakProvider -> judgeModels "TAP attack, judge classification, evaluation" "HTTPS/443, per-role API keys"
        garakProvider -> shieldModels "Shield scan orchestration (guardrail testing)" "HTTP/8321"

        # Eval-hub orchestration
        evalHub -> garakProvider "Orchestrates adapter pod lifecycle via K8s Job" "K8s Job + ConfigMap"

        # Storage
        garakProvider -> s3 "Upload/download scan artifacts" "HTTPS/443, AWS IAM"
        garakProvider -> ociRegistry "Push scan artifact bundles (eval-hub mode)" "HTTPS/443, TLS"
        garakProvider -> mlflow "Log metrics, artifacts, run metadata" "HTTPS/443"
        llamaStack -> postgresql "Distribution state storage" "PostgreSQL/5432"

        # Infrastructure
        garakProvider -> k8sApi "Read Secrets (model auth, S3 creds), ConfigMaps" "HTTPS/443, mTLS SA Token"
        trustyaiOperator -> garakProvider "Provides garak-provider-image ConfigMap key" "K8s ConfigMap"

        # Internal container relationships
        inlineProvider -> coreModule "Uses shared logic"
        remoteProvider -> coreModule "Uses shared logic"
        evalHubAdapter -> coreModule "Uses shared logic"
        inlineProvider -> garakRunner "Spawns garak subprocess"
        evalHubAdapter -> garakRunner "Spawns garak subprocess"
        inlineProvider -> configModule "Deep-merge benchmark profiles"
        remoteProvider -> configModule "Deep-merge benchmark profiles"
        evalHubAdapter -> configModule "Deep-merge benchmark profiles"
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
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape roundedBox
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
