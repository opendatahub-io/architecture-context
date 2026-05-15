workspace {
    model {
        datascientist = person "Data Scientist / ML Engineer" "Registers benchmarks and triggers LLM security scans via Llama Stack API"
        securityengineer = person "Security Engineer" "Reviews scan results and TBSA scores for LLM vulnerability assessment"

        garakProvider = softwareSystem "llama-stack-provider-trustyai-garak" "Llama Stack Eval API provider wrapping NVIDIA Garak for automated LLM red-teaming and vulnerability scanning" {
            evalProvider = container "Eval API Provider" "Implements register_benchmark(), run_eval(), job_status/result/cancel()" "Python Provider"
            inlineEval = container "Inline Eval Engine" "Runs Garak as local subprocess within Llama Stack server process" "Python"
            remoteEval = container "Remote Eval Engine" "Compiles and submits 6-step KFP pipeline for distributed scan execution" "Python + KFP SDK"
            evalHubAdapter = container "EvalHub Adapter" "FrameworkAdapter for EvalHub platform with S3-based artifact transfer" "Python"
            coreLogic = container "Core Logic" "Garak runner, config builder, result parser, TBSA scorer" "Python"
            sdgSubsystem = container "SDG Subsystem" "Generates adversarial prompts from harm taxonomies using sdg-hub" "Python + sdg-hub"
            shieldOrchestrator = container "Shield Orchestrator" "SimpleShieldOrchestrator wrapping LLM calls with input/output shield checks" "Python"
            garakConfig = container "Config Manager" "Deep-merge profile resolution (OWASP, AVID, CWE, quality, intents)" "Python"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Hosts provider plugins and exposes Files, Inference, Safety APIs" {
            filesAPI = container "Files API" "Upload/download scan configs, results, reports" "HTTP/REST"
            inferenceAPI = container "Inference API" "LLM inference for shield scan mode" "HTTP/REST"
            safetyAPI = container "Safety API" "Input/output shield checks" "HTTP/REST"
        }

        kfp = softwareSystem "Kubeflow Pipelines" "Distributed pipeline execution engine for remote scan mode" "External"
        targetLLM = softwareSystem "Target LLM" "Language model under security assessment (OpenAI-compatible API)" "External"
        s3 = softwareSystem "S3 / Object Storage" "Artifact storage for EvalHub mode (scan configs, results, reports)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model hub for Garak probe/detector model downloads" "External"
        evalHubPlatform = softwareSystem "EvalHub Platform" "Evaluation orchestration platform triggering scan jobs" "External"
        configMap = softwareSystem "trustyai-service-operator-config" "K8s ConfigMap providing garak-provider-image for KFP pipelines" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "File storage backend for Llama Stack server (reference deployment)" "External"

        # User interactions
        datascientist -> garakProvider "Registers benchmarks and triggers scans" "Llama Stack Eval API / HTTPS"
        securityengineer -> garakProvider "Retrieves scan results and TBSA scores" "Llama Stack Eval API / HTTPS"

        # Provider to Llama Stack APIs
        garakProvider -> llamaStackServer "Uploads/downloads configs and results; shield checks; inference calls" "HTTPS/HTTP, TLS (configurable), API key"

        # Provider to external systems
        garakProvider -> kfp "Submits pipeline runs, polls status" "HTTPS, TLS, Bearer token"
        garakProvider -> targetLLM "Sends adversarial prompts, receives completions" "HTTPS, TLS, API key"
        garakProvider -> s3 "Uploads/downloads scan artifacts (EvalHub mode)" "HTTPS/443, TLS, AWS IAM"
        garakProvider -> huggingface "Downloads probe/detector models" "HTTPS/443, TLS, HF token"
        garakProvider -> configMap "Reads garak-provider-image key" "K8s API"
        evalHubPlatform -> garakProvider "Triggers scan jobs via FrameworkAdapter" "Internal"

        # Internal container relationships
        evalProvider -> inlineEval "Dispatches inline mode"
        evalProvider -> remoteEval "Dispatches remote mode"
        evalProvider -> evalHubAdapter "Dispatches EvalHub mode"
        evalProvider -> garakConfig "Resolves benchmark profiles"
        inlineEval -> coreLogic "Garak execution + result parsing"
        remoteEval -> coreLogic "Pipeline step logic"
        evalHubAdapter -> coreLogic "Pipeline step logic"
        inlineEval -> sdgSubsystem "Generates adversarial prompts"
        inlineEval -> shieldOrchestrator "Shield-wrapped LLM calls"
        shieldOrchestrator -> safetyAPI "Input/output shield checks" "HTTPS, API key"
        shieldOrchestrator -> inferenceAPI "LLM inference calls" "HTTPS, API key"
        coreLogic -> filesAPI "Upload/download artifacts" "HTTP, API key"
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
                color #ffffff
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
