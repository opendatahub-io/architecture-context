workspace {
    model {
        evaluator = person "Evaluator / Data Scientist" "Submits LLM red-teaming evaluation jobs via eval-hub"

        garakAdapter = softwareSystem "Garak Adapter" "Eval-hub FrameworkAdapter that orchestrates Garak-based LLM security and safety assessments" {
            adapter = container "garak-adapter" "Main adapter: mode selection, credential resolution, result reporting" "Python FrameworkAdapter"
            garakRunner = container "Garak Runner" "Subprocess executor for Garak CLI with timeout and signal handling" "Python Module"
            kfpPipeline = container "KFP Pipeline" "Six-step Kubeflow Pipeline definition for intents workflows" "Python KFP SDK"
            sdgModule = container "SDG Module" "Synthetic Data Generation wrapper for adversarial prompt creation" "Python Module"
            coreSteps = container "Pipeline Steps" "Framework-agnostic logic: validation, config, scan execution, result parsing" "Python Module"
            resultUtils = container "Result Utils" "JSONL/AVID parser, TBSA scoring, HTML report generation" "Python Jinja2"
        }

        evalHub = softwareSystem "eval-hub" "Evaluation orchestration platform managing job lifecycle" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for scan artifacts and results" "External"
        targetLLM = softwareSystem "Target LLM" "Large Language Model under security/safety assessment" "External"
        sdgEndpoint = softwareSystem "SDG Model Endpoint" "Model for Synthetic Data Generation of adversarial prompts" "External"
        trustyaiOp = softwareSystem "trustyai-service-operator" "Operator managing TrustyAI services and KFP base images" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for secrets, configmaps, and job management" "Infrastructure"

        # System-level relationships
        evaluator -> evalHub "Submits evaluation job"
        evalHub -> garakAdapter "Schedules K8s Job with JobSpec"
        garakAdapter -> targetLLM "Sends adversarial probes" "HTTPS"
        garakAdapter -> kfp "Submits and polls pipelines (KFP mode)" "HTTPS"
        garakAdapter -> s3 "Uploads/downloads scan artifacts (KFP mode)" "HTTPS"
        garakAdapter -> sdgEndpoint "Generates adversarial prompts (KFP mode)" "HTTPS"
        garakAdapter -> k8sAPI "Reads secrets and configmaps" "HTTPS/443"
        garakAdapter -> trustyaiOp "Reads KFP base image config" "K8s API"
        garakAdapter -> evalHub "Reports EvaluationResult via sidecar" "HTTP localhost"

        # Container-level relationships
        adapter -> garakRunner "Delegates scan (simple mode)"
        adapter -> kfpPipeline "Delegates scan (KFP mode)"
        adapter -> coreSteps "Validation, config resolution"
        adapter -> resultUtils "Parses and scores results"
        kfpPipeline -> sdgModule "Generates prompts (intents workflow)"
        kfpPipeline -> coreSteps "Pipeline step logic"
        garakRunner -> coreSteps "Scan execution logic"
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
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
