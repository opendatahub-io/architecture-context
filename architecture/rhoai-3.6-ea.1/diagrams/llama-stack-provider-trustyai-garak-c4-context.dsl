workspace {
    model {
        evaluator = person "Evaluator / Platform Admin" "Triggers red-team evaluation jobs via eval-hub"

        garakAdapter = softwareSystem "llama-stack-provider-trustyai-garak" "Garak red-teaming evaluation adapter that runs as a Kubernetes Job, supporting simple (in-pod) and KFP execution modes" {
            adapterCore = container "Garak Adapter" "Implements eval-hub FrameworkAdapter interface, orchestrates scan execution" "Python Job Pod"
            pipelineSteps = container "Pipeline Steps" "Credential resolution, config preparation, API key redaction" "Python Module"
            s3Utils = container "S3 Utilities" "Upload/download scan configs, prompts, and results" "Python Module"
            kfpPipeline = container "KFP Pipeline Definition" "6-step pipeline: validation, taxonomy, SDG, prep, scan, output" "Python/KFP DSL"
        }

        evalHub = softwareSystem "eval-hub" "Evaluation orchestration platform that manages evaluation jobs" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration for multi-step ML workflows" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and secret access" "Platform"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for artifact transfer between pods" "External"
        targetModel = softwareSystem "Target AI Model" "AI model endpoint being evaluated for safety (OpenAI-compatible API)" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for persisting scan results" "External"
        garakFramework = softwareSystem "Garak Framework" "NVIDIA Garak red-teaming security scanning framework (v0.15.0+rhaiv.5)" "External"

        evaluator -> evalHub "Triggers evaluation job"
        evalHub -> garakAdapter "Mounts job spec ConfigMap"
        garakAdapter -> garakFramework "Runs as subprocess (simple mode)"
        garakAdapter -> kfp "Submits pipeline (KFP mode)" "HTTPS / KFP_AUTH_TOKEN"
        garakAdapter -> s3Storage "Uploads/downloads artifacts" "HTTPS / AWS credentials"
        garakAdapter -> targetModel "Scans model (simple mode)" "HTTPS / API_KEY"
        garakAdapter -> ociRegistry "Persists scan artifacts" "HTTPS"
        garakAdapter -> evalHub "Reports results via sidecar callback" "HTTP localhost"
        kfp -> s3Storage "Pipeline pods transfer artifacts" "HTTPS / Data Connection secrets"
        kfp -> targetModel "Pipeline pods scan model" "HTTPS / API_KEY"
        garakAdapter -> k8sAPI "Reads Data Connection secrets" "HTTPS / SA token"
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
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
