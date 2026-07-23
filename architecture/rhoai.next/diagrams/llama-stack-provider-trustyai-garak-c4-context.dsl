workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Initiates red-teaming evaluations of LLM models via eval-hub"
        securityEngineer = person "Security Engineer" "Reviews vulnerability scan results and compliance reports"

        garakProvider = softwareSystem "Llama Stack Provider TrustyAI Garak" "Garak red-teaming evaluation adapter for eval-hub; runs automated LLM vulnerability scanning as K8s Jobs" {
            garakAdapter = container "GarakAdapter" "Main adapter: reads JobSpec, builds garak config, executes scans, parses results" "Python FrameworkAdapter"
            garakKFPAdapter = container "GarakKFPAdapter" "KFP-specific adapter: forces distributed pipeline execution mode" "Python FrameworkAdapter subclass"
            kfpPipeline = container "KFP Pipeline (evalhub-garak-scan)" "6-step distributed pipeline: validate → resolve_taxonomy → sdg_generate → prepare_prompts → garak_scan → write_kfp_outputs" "Kubeflow Pipeline"
            coreModule = container "Core Module" "Framework-agnostic: config resolution, command building, garak subprocess execution, API key management" "Python Library"
            sdgModule = container "SDG Module" "Synthetic Data Generation: produces adversarial prompts from harm taxonomies via sdg-hub" "Python Library"
            intentsModule = container "Intents Module" "Taxonomy/intents dataset loading, validation, CAS topology file generation" "Python Library"
            resultUtils = container "Result Utilities" "JSONL parsing, AVID aggregation, TBSA scoring, Vega chart data, ART HTML report generation" "Python Library"
        }

        evalHub = softwareSystem "eval-hub Service" "Evaluation orchestration platform that creates K8s Jobs and manages evaluation lifecycle" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration for distributed multi-step evaluations" "Internal RHOAI"
        targetLLM = softwareSystem "Target LLM Endpoint" "The model under test, OpenAI-compatible API" "External"
        judgeLLM = softwareSystem "Judge/Attacker/Evaluator LLMs" "Auxiliary LLM endpoints for intents mode: judging, attacking, evaluating" "External"
        sdgLLM = softwareSystem "SDG LLM Endpoint" "LLM for synthetic adversarial prompt generation" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for scan artifacts, report files, and inter-pod data transfer" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for persisting scan directories as OCI artifacts" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking: metrics logging and artifact management" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for reading Secrets, ConfigMaps, and service account tokens" "Platform"
        hfHub = softwareSystem "HuggingFace Hub" "Model hub for downloading probe models and translation weights" "External"
        trustyaiOperator = softwareSystem "opendatahub-operator" "Creates trustyai-service-operator-config ConfigMap for base image resolution" "Internal RHOAI"

        # User interactions
        dataScientist -> evalHub "Submits evaluation request via UI/API"
        securityEngineer -> garakProvider "Reviews scan reports (HTML, JSONL, AVID)"

        # eval-hub → adapter
        evalHub -> garakProvider "Creates K8s Job with ConfigMap (JobSpec) and Secrets"

        # Adapter outbound
        garakProvider -> targetLLM "Sends probe prompts (HTTPS/443, Bearer Token)" "OpenAI REST API"
        garakProvider -> judgeLLM "Intents mode: judge detection, TAP attack/eval (HTTPS/443)" "OpenAI REST API"
        garakProvider -> sdgLLM "Intents mode: adversarial prompt generation (HTTPS/443)" "OpenAI REST API"
        garakProvider -> kfp "Submits pipeline runs, polls completion (HTTPS/443, SA Token)" "REST API"
        garakProvider -> s3 "Upload/download scan artifacts (HTTPS/443, AWS IAM)" "S3 API"
        garakProvider -> ociRegistry "Persist scan artifacts as OCI artifacts (HTTPS/443)" "OCI API"
        garakProvider -> mlflow "Log metrics and artifacts (HTTPS/443)" "REST API"
        garakProvider -> k8sAPI "Read Secrets, ConfigMaps (HTTPS/443, SA Token)" "Kubernetes API"
        garakProvider -> hfHub "Download model weights (HTTPS/443)" "HTTPS"
        garakProvider -> evalHub "Report job status and results via sidecar (HTTP/8080, loopback)" "REST callback"

        # Internal relationships
        trustyaiOperator -> garakProvider "Provides base image config via ConfigMap"
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
            element "Platform" {
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
