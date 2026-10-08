workspace {
    model {
        mlEngineer = person "ML Engineer / Security Analyst" "Initiates red-teaming scans via eval-hub"

        garakAdapter = softwareSystem "llama-stack-provider-trustyai-garak" "Garak red-teaming evaluation adapter for eval-hub, enabling automated LLM vulnerability scanning" {
            adapterCore = container "Garak Adapter" "FrameworkAdapter implementation with simple and KFP execution modes" "Python"
            pipelineSteps = container "Pipeline Steps" "Framework-agnostic business logic for 6-step pipeline (validate, taxonomy, SDG, prompts, scan, outputs)" "Python"
            kfpPipeline = container "KFP Pipeline Definition" "Kubeflow Pipeline with S3 artifact flow and secret injection" "Python / KFP SDK"
            s3Utils = container "S3 Utilities" "Centralized S3 client factory using Data Connection credentials" "Python / boto3"
        }

        evalHub = softwareSystem "eval-hub" "Evaluation orchestration platform managing job lifecycle and result collection" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration with DAG workflows" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI services and provides operator configuration" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for scan artifacts, SDG data, and HTML reports" "External"
        targetLLM = softwareSystem "Target LLM" "The language model under test for red-teaming vulnerability assessment" "External"
        sdgModel = softwareSystem "SDG Model" "Language model for synthetic data generation in intents workflows" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and tokenizer downloads for translation probes" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for ConfigMap and Secret access" "Infrastructure"

        mlEngineer -> evalHub "Configures and triggers red-teaming scans"
        evalHub -> garakAdapter "Launches K8s Job with JobSpec ConfigMap"
        garakAdapter -> kfp "Submits 6-step pipeline (KFP mode)" "HTTP/HTTPS"
        garakAdapter -> s3Storage "Uploads/downloads scan artifacts" "HTTPS/443"
        garakAdapter -> targetLLM "Probes model with adversarial inputs" "HTTP/HTTPS"
        garakAdapter -> sdgModel "Generates synthetic test data" "HTTP/HTTPS"
        garakAdapter -> huggingFace "Downloads models/tokenizers" "HTTPS/443"
        garakAdapter -> k8sAPI "Reads ConfigMaps and Secrets" "HTTPS/443"
        garakAdapter -> trustyaiOperator "Reads operator ConfigMap for pipeline image" "Kubernetes API"
        garakAdapter -> evalHub "Reports results via sidecar callbacks" "HTTP localhost"

        adapterCore -> pipelineSteps "Delegates scan logic"
        adapterCore -> kfpPipeline "Builds and submits pipeline"
        kfpPipeline -> s3Utils "Artifact transfer"
        pipelineSteps -> s3Utils "Artifact transfer"
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
                color #000000
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
        }
    }
}
