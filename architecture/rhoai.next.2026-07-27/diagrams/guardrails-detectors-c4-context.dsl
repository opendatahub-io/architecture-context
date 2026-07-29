workspace {
    model {
        client = person "Client / Guardrails Orchestrator" "Sends content for safety analysis and evaluation"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Content-safety detection services providing built-in regex/file-type detectors and LLM-as-Judge evaluation" {
            builtInDetector = container "Built-in Detector" "FastAPI application hosting regex, file-type, and custom detector registries for content analysis" "Python / FastAPI"
            llmJudgeDetector = container "LLM Judge Detector" "FastAPI application evaluating content against configurable metrics (safety, toxicity, accuracy, helpfulness) using LLM-as-Judge pattern" "Python / FastAPI"
            minioServer = container "MinIO Server" "S3-compatible model storage serving downloaded model artifacts" "MinIO (quay.io/trustyai/modelmesh-minio-examples)" "Database"
            initContainer = container "LLM Downloader" "Init container that downloads models from HuggingFace Hub to PVC" "quay.io/rgeada/llm_downloader"
        }

        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model artifact repository hosting ibm-granite/granite-guardian-3.0-2b and other models" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        # Relationships - External
        client -> guardrailsDetectors "Sends content for analysis" "HTTP/HTTPS"

        # Relationships - Internal
        client -> builtInDetector "POST /api/v1/text/contents, GET /registry, GET /metrics" "HTTP/HTTPS, No Auth"
        client -> llmJudgeDetector "POST /api/v1/text/contents, POST /api/v1/text/generation, GET /api/v1/metrics" "HTTP/HTTPS, No Auth"
        llmJudgeDetector -> minioServer "Fetches model artifacts" "S3 API / TCP 9000"
        initContainer -> huggingFaceHub "Downloads model artifacts" "HTTPS/443"
        initContainer -> minioServer "Stores downloaded models" "Filesystem (PVC)"
    }

    views {
        systemContext guardrailsDetectors "SystemContext" {
            include *
            autoLayout
        }

        container guardrailsDetectors "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
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
            element "Database" {
                shape cylinder
                background #438dd5
                color #ffffff
            }
        }
    }
}
