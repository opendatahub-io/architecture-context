workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Initiates red-teaming evaluations via eval-hub"

        garakProvider = softwareSystem "Garak Provider" "Garak red-teaming evaluation adapter for the RHOAI eval-hub platform" {
            garakAdapter = container "Garak Adapter" "Main eval-hub FrameworkAdapter: reads JobSpec, dispatches to simple/KFP mode, parses results" "Python"
            kfpAdapter = container "KFP Adapter" "Forces KFP pipeline mode for all evaluations" "Python"
            coreLogic = container "Core Logic" "Framework-agnostic business logic: config resolution, command building, process management, pipeline steps" "Python"
            garakRunner = container "Garak Runner" "Subprocess manager: runs Garak CLI with timeout, process group management, log streaming" "Python"
            resultParser = container "Result Parser" "Parses JSONL/AVID reports, computes TBSA scores, generates ART HTML reports" "Python"
            sdgIntegration = container "SDG Integration" "Synthetic Data Generation via sdg-hub for adversarial prompt generation" "Python"
        }

        evalHub = softwareSystem "eval-hub Service" "Job lifecycle management, result reporting, MLflow persistence" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration platform for multi-step scan workflows" "Internal RHOAI"
        s3Store = softwareSystem "S3-Compatible Object Store" "Artifact storage for scan results, SDG output, taxonomy files" "External"
        targetLLM = softwareSystem "Target LLM Model" "Model endpoint being scanned for vulnerabilities" "External"
        judgeLLM = softwareSystem "Judge LLM Model" "MulticlassJudge detector for intents evaluation" "External"
        attackerLLM = softwareSystem "Attacker LLM Model" "TAPIntent tree-of-attacks attack generation" "External"
        evaluatorLLM = softwareSystem "Evaluator LLM Model" "TAPIntent evaluator for attack quality assessment" "External"
        sdgLLM = softwareSystem "SDG LLM Model" "Synthetic Data Generation for adversarial prompt creation" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and artifact logging" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry" "Scan artifact bundle persistence" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Secrets and ConfigMaps access" "Platform"
        hfHub = softwareSystem "Hugging Face Hub" "Model weights and tokenizer downloads" "External"
        trustyaiOperator = softwareSystem "TrustYAI Service Operator" "Provides garak-provider-image reference via ConfigMap" "Internal RHOAI"
        odhOperator = softwareSystem "OpenDataHub Operator" "Provides garak provider image ConfigMap" "Internal RHOAI"

        # Relationships
        dataScientist -> evalHub "Initiates evaluation via UI/API"
        evalHub -> garakProvider "Creates K8s Job with JobSpec ConfigMap"

        garakAdapter -> coreLogic "Uses for config resolution, command building"
        garakAdapter -> garakRunner "Dispatches simple mode scans"
        garakAdapter -> resultParser "Parses scan results"
        kfpAdapter -> garakAdapter "Extends (forces KFP mode)"
        coreLogic -> sdgIntegration "Uses for intents benchmark"

        garakProvider -> targetLLM "Scans for vulnerabilities" "HTTPS/443 Bearer Token"
        garakProvider -> kfp "Submits and polls pipeline runs (KFP mode)" "HTTPS/443 SA Token"
        garakProvider -> s3Store "Uploads/downloads scan artifacts" "HTTPS/443 AWS IAM"
        garakProvider -> evalHub "Reports results via sidecar callback" "HTTP/8080 Bearer Token (loopback)"
        garakProvider -> mlflow "Logs metrics and artifacts" "HTTPS/443 Bearer Token"
        garakProvider -> ociRegistry "Persists artifact bundles" "HTTPS/443 Registry credentials"
        garakProvider -> k8sAPI "Reads Secrets and ConfigMaps" "HTTPS/443 SA Token"
        garakProvider -> attackerLLM "Generates attack prompts (intents)" "HTTPS/443 Bearer Token"
        garakProvider -> judgeLLM "Evaluates intent violations" "HTTPS/443 Bearer Token"
        garakProvider -> evaluatorLLM "Assesses attack quality" "HTTPS/443 Bearer Token"
        garakProvider -> sdgLLM "Generates adversarial prompts" "HTTPS/443 Bearer Token"
        garakProvider -> hfHub "Downloads model weights (conditional)" "HTTPS/443"
        garakProvider -> trustyaiOperator "Reads ConfigMap for base image" "ConfigMap"
        garakProvider -> odhOperator "Reads ConfigMap for image reference" "ConfigMap"
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
            element "Software System" {
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
            element "Platform" {
                background #f5a623
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
        }
    }
}
