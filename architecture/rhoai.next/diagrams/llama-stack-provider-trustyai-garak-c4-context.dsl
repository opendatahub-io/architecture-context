workspace {
    model {
        dataScientist = person "Data Scientist" "Runs red-teaming benchmarks against LLMs to evaluate model safety"
        securityEngineer = person "Security Engineer" "Reviews vulnerability scan results and compliance reports"

        garakProvider = softwareSystem "llama-stack-provider-trustyai-garak" "Out-of-tree Llama Stack evaluation provider and eval-hub adapter for NVIDIA Garak red-teaming scans" {
            inlineProvider = container "Inline Provider" "Runs Garak scans locally in-process with asyncio semaphore concurrency" "Python Library"
            remoteProvider = container "Remote Provider" "Submits Garak scan pipelines to KFP, polls for completion" "Python Library"
            evalHubAdapter = container "Eval-Hub Garak Adapter" "FrameworkAdapter for eval-hub platform integration" "Python FrameworkAdapter"
            evalHubKFPAdapter = container "Eval-Hub KFP Adapter" "Forces KFP execution mode for eval-hub jobs" "Python FrameworkAdapter"
            coreModules = container "Core Modules" "Shared business logic: config resolution, command building, garak execution, result parsing" "Python Module"
            shieldScan = container "Shield Scan Orchestrator" "Wraps LLM inference with safety shields for vulnerability assessment" "Python Module"
            intentsModule = container "Intents Module" "Policy taxonomy loading, intent stub generation, context-aware scanning" "Python Module"
            sdgModule = container "SDG Module" "Synthetic adversarial prompt generation via sdg-hub" "Python Module"
            garakConfig = container "Garak Command Config" "Pydantic models mapping to Garak CLI config (system, run, plugins, reporting, CAS)" "Python Module"
            resultUtils = container "Result Utilities" "Parses JSONL/AVID reports, computes TBSA scores, generates HTML reports" "Python Module"

            inlineProvider -> coreModules "Uses for scan execution"
            remoteProvider -> coreModules "Uses for pipeline construction"
            evalHubAdapter -> coreModules "Uses for scan execution"
            evalHubKFPAdapter -> evalHubAdapter "Extends (forces KFP mode)"
            inlineProvider -> shieldScan "Wraps inference with shields"
            inlineProvider -> intentsModule "Loads taxonomy for intent scanning"
            evalHubAdapter -> intentsModule "Loads taxonomy for intent scanning"
            intentsModule -> sdgModule "Generates adversarial prompts"
            coreModules -> garakConfig "Builds garak CLI configuration"
            coreModules -> resultUtils "Parses scan results"
        }

        llamaStack = softwareSystem "Llama Stack Distribution" "Meta's LLM application framework providing inference, safety, files, and benchmark APIs" "Internal"
        kfp = softwareSystem "Kubeflow Pipelines (DSP)" "Pipeline orchestration for remote scan execution" "Internal RHOAI"
        evalHub = softwareSystem "Eval-Hub Platform" "RHOAI evaluation orchestration platform" "Internal RHOAI"
        vllm = softwareSystem "vLLM / Model Serving" "Target LLM serving endpoint (OpenAI-compatible)" "Internal RHOAI"
        s3 = softwareSystem "S3-Compatible Storage" "Artifact storage for scan results and SDG outputs" "External"
        mlflow = softwareSystem "MLflow Tracking" "Experiment tracking and metric logging" "External"
        ociRegistry = softwareSystem "OCI Registry" "Persistent scan artifact storage" "External"
        sdgHub = softwareSystem "sdg-hub" "Synthetic data generation library for adversarial prompts" "External Library"
        garak = softwareSystem "NVIDIA Garak" "Core LLM vulnerability scanner (0.14.1+rhaiv.8)" "External Library"
        postgresql = softwareSystem "PostgreSQL" "Persistent state storage for Llama Stack Distribution" "External"

        dataScientist -> garakProvider "Runs benchmarks via Llama Stack API" "HTTP/8321"
        securityEngineer -> garakProvider "Reviews scan results and compliance reports"

        garakProvider -> llamaStack "Model inference, shield execution, file storage, benchmark registry" "HTTP/8321"
        garakProvider -> kfp "Pipeline submission, run polling, experiment management" "HTTPS/443"
        garakProvider -> vllm "Target model for vulnerability scanning" "HTTPS or HTTP/443 or 8080"
        garakProvider -> s3 "Artifact upload/download (eval-hub KFP mode)" "HTTPS/443"
        garakProvider -> mlflow "Experiment tracking (optional)" "HTTP/HTTPS"
        garakProvider -> ociRegistry "Scan artifact persistence (eval-hub mode)" "HTTPS/443"
        garakProvider -> garak "Core vulnerability scanning" "CLI/Python"
        garakProvider -> sdgHub "Adversarial prompt generation" "Python API"
        evalHub -> garakProvider "Creates evaluation jobs" "ConfigMap/JobSpec"
        llamaStack -> postgresql "Persistent state storage" "TCP/5432"
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "External Library" {
                background #775599
            }
            element "Internal" {
                background #438dd5
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
