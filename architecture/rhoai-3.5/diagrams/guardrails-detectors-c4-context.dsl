workspace {
    model {
        datascientist = person "Data Scientist" "Configures guardrails detectors and deploys models for content safety"
        platformadmin = person "Platform Admin" "Deploys and manages RHOAI platform and guardrails configuration"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of text detection microservices for content safety, PII detection, and LLM evaluation" {
            builtInDetector = container "Built-in Detector" "Regex-based PII detection (email, CC, SSN, phone, IP), file-type validation (JSON/XML/YAML), custom user-defined detectors with AST sandboxing" "Python/FastAPI/uvicorn" "Service"
            hfDetector = container "HuggingFace Detector" "ML model-based content analysis using AutoModelForSequenceClassification, AutoModelForTokenClassification, and GraniteForCausalLM" "Python/FastAPI/uvicorn/PyTorch" "Service"
            judgeDetector = container "LLM Judge Detector" "LLM-as-a-judge content evaluation with configurable metrics (safety, toxicity, accuracy, helpfulness)" "Python/FastAPI/uvicorn/vllm_judge" "Service"
            commonLib = container "Common Library" "Shared DetectorBaseAPI, Pydantic schemas, Prometheus instrumentation, health endpoint" "Python Library" "Library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Orchestrates content safety checks by calling detector APIs on input/output text" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Kubernetes-native serverless inference platform for deploying ML models" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and policy enforcement" "External"
        s3 = softwareSystem "S3/MinIO Object Storage" "Model artifact storage for HuggingFace detector models" "External"
        vllmServer = softwareSystem "vLLM Inference Server" "OpenAI-compatible inference server for LLM Judge evaluations" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI management dashboard" "Internal RHOAI"

        # Relationships
        orchestrator -> guardrailsDetectors "Calls detector APIs for text analysis" "HTTP/mTLS"
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080 mTLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"
        orchestrator -> judgeDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"

        builtInDetector -> commonLib "extends DetectorBaseAPI"
        hfDetector -> commonLib "extends DetectorBaseAPI"
        judgeDetector -> commonLib "extends DetectorBaseAPI"

        kserve -> hfDetector "Deploys as InferenceService"
        kserve -> judgeDetector "Deploys as InferenceService"
        kserve -> s3 "Storage initializer downloads model files" "HTTP/9000"

        istio -> builtInDetector "Sidecar injection, mTLS STRICT"
        istio -> hfDetector "Sidecar injection, mTLS STRICT"
        istio -> judgeDetector "Sidecar injection, mTLS STRICT"

        hfDetector -> s3 "Model file retrieval via KServe storage initializer" "HTTP/9000"
        judgeDetector -> vllmServer "Proxies evaluation requests" "HTTP"

        prometheus -> guardrailsDetectors "Scrapes /metrics endpoints" "HTTP"

        rhoaiDashboard -> guardrailsDetectors "Dashboard visibility via labels" "opendatahub.io/dashboard: true"

        datascientist -> orchestrator "Submits text for safety analysis"
        platformadmin -> kserve "Deploys InferenceService CRs"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Service" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
            element "Library" {
                shape Component
                background #b8d4f0
                color #333333
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
