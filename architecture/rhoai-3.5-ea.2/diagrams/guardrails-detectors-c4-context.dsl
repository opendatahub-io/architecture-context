workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models and configures guardrails for content safety"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and guardrails configuration"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of text detection microservices providing PII detection, file-type validation, HuggingFace model inference, and LLM-as-judge evaluation" {
            builtInDetector = container "Built-in Detector" "Lightweight regex-based PII detection, file-type validation (JSON/XML/YAML), and custom Python detector execution" "Python FastAPI / Port 8080"
            hfDetector = container "HuggingFace Detector" "ML-based content analysis using HuggingFace transformers (sequence classification, token classification, causal LM)" "Python FastAPI / Port 8000"
            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-judge content evaluation delegating to external vLLM server via vllm_judge library" "Python FastAPI / Port 8000"
            commonFramework = container "Common Framework" "Shared DetectorBaseAPI base class, Pydantic schemas, Prometheus instrumentation, health endpoints" "Python Library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "IBM-led orchestrator for text generation input/output inspection" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform managing InferenceService lifecycle" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and sidecar injection" "Internal RHOAI"
        vllm = softwareSystem "vLLM Server" "OpenAI-compatible LLM server for judge evaluation" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (MinIO)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Model weight repository" "External"

        # Relationships
        orchestrator -> builtInDetector "Sends text for content analysis" "HTTP/8080 mTLS"
        orchestrator -> hfDetector "Sends text for ML-based classification" "HTTP/8000 mTLS"
        orchestrator -> llmJudgeDetector "Sends text for LLM judge evaluation" "HTTP/8000 mTLS"

        llmJudgeDetector -> vllm "Sends evaluation requests" "HTTP/8080"
        hfDetector -> s3Storage "Downloads model weights (via KServe storage init)" "HTTP/9000"
        hfDetector -> hfHub "Downloads model weights (init container)" "HTTPS/443"

        kserve -> hfDetector "Manages InferenceService lifecycle"
        kserve -> llmJudgeDetector "Manages InferenceService lifecycle"
        istio -> builtInDetector "Provides mTLS sidecar"
        istio -> hfDetector "Provides mTLS sidecar"
        istio -> llmJudgeDetector "Provides mTLS sidecar"

        prometheus -> builtInDetector "Scrapes trustyai_guardrails_* metrics" "HTTP/8080"
        prometheus -> hfDetector "Scrapes trustyai_guardrails_* metrics" "HTTP/8000"
        prometheus -> llmJudgeDetector "Scrapes trustyai_guardrails_* metrics" "HTTP/8000"

        builtInDetector -> commonFramework "Extends DetectorBaseAPI"
        hfDetector -> commonFramework "Extends DetectorBaseAPI"
        llmJudgeDetector -> commonFramework "Extends DetectorBaseAPI"

        dataScientist -> orchestrator "Configures guardrails for inference pipelines"
        platformAdmin -> kserve "Deploys detector InferenceServices"
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
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
        }
    }
}
