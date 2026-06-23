workspace {
    model {
        datascientist = person "Data Scientist / Security Engineer" "Initiates LLM red-teaming scans via eval-hub"

        garakAdapter = softwareSystem "Garak Adapter" "Garak-based LLM red-teaming and vulnerability scanning adapter for the eval-hub evaluation platform" {
            adapterModule = container "Garak Adapter (evalhub)" "FrameworkAdapter implementation, orchestrates scan execution in simple or KFP mode" "Python Service (K8s Job)"
            coreLib = container "Core Library" "Framework-agnostic business logic: config resolution, command building, Garak subprocess runner, pipeline steps" "Python Library"
            resultUtils = container "Result Utils" "Parses Garak JSONL/AVID reports, computes ASR/TBSA metrics, generates HTML reports" "Python Module"
            intentsModule = container "Intents Module" "Loads policy taxonomy datasets, generates Garak CAS topology and intent stubs" "Python Module"
            sdgModule = container "SDG Module" "Wraps sdg_hub library for synthetic adversarial prompt generation" "Python Module"
            kfpPipeline = container "KFP Pipeline" "6-step DAG pipeline definition for distributed scan execution" "Kubeflow Pipeline"
        }

        evalHub = softwareSystem "eval-hub" "Evaluation orchestration platform that creates K8s Jobs and manages scan lifecycle" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline execution engine for distributed multi-step scan workflows" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides configuration including garak container image reference" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking, metric logging, and artifact persistence" "Internal RHOAI"

        targetModel = softwareSystem "Target Model Endpoint" "OpenAI-compatible LLM being scanned for vulnerabilities" "External"
        judgeModel = softwareSystem "Judge/Attacker/Evaluator Models" "Supporting LLMs for intents-based risk assessment (judge, attacker, evaluator, SDG, translation)" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Artifact transfer and persistence for scan results, SDG output, taxonomy data" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container and artifact registry for persisting scan output" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model repository for Helsinki-NLP translation models" "External"

        datascientist -> evalHub "Initiates red-teaming scan"
        evalHub -> garakAdapter "Creates K8s Job with JobSpec ConfigMap"
        garakAdapter -> evalHub "Reports status and results via sidecar callbacks" "HTTP/localhost"
        garakAdapter -> targetModel "Sends Garak probes to scan for vulnerabilities" "HTTPS/443"
        garakAdapter -> judgeModel "Calls judge/attacker/evaluator/SDG models for intents mode" "HTTPS/443"
        garakAdapter -> kfp "Submits and monitors pipeline runs (KFP mode)" "HTTPS/443"
        garakAdapter -> s3 "Uploads/downloads scan artifacts" "HTTPS/443"
        garakAdapter -> ociRegistry "Persists scan output as OCI artifacts" "HTTPS/443"
        garakAdapter -> mlflow "Logs metrics (ASR, TBSA) and artifacts" "HTTPS/443"
        garakAdapter -> trustyaiOperator "Reads garak-provider-image from ConfigMap" "K8s API"
        garakAdapter -> huggingface "Downloads translation models" "HTTPS/443"

        adapterModule -> coreLib "Uses for config resolution and command building"
        adapterModule -> resultUtils "Uses for result parsing and metric computation"
        adapterModule -> intentsModule "Uses for taxonomy loading and CAS topology"
        adapterModule -> sdgModule "Uses for synthetic prompt generation"
        adapterModule -> kfpPipeline "Submits pipeline in KFP mode"
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
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
