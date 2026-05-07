workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Orchestrates content safety checks by routing text through configured detectors"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of detector microservices providing text content analysis for safety, PII detection, file-type validation, and LLM-as-a-judge evaluation" {
            builtInDetector = container "Built-In Detector" "Regex-based PII detection and file-type validation without ML models" "Python FastAPI/uvicorn" "Service"
            huggingfaceDetector = container "HuggingFace Detector" "ML-based content classification using HuggingFace transformer models (HAP, Granite Guardian)" "Python FastAPI/uvicorn + PyTorch" "Service"
            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-a-judge content evaluation via external vLLM server using vllm_judge library" "Python FastAPI/uvicorn" "Service"
            commonLibrary = container "Common Library" "Shared FastAPI base class (DetectorBaseAPI), Pydantic schemas, Prometheus instrumentation, health checks" "Python Library" "Library"
        }

        kserve = softwareSystem "KServe" "Kubernetes model serving platform for deploying InferenceServices" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and sidecar injection" "External"
        s3Storage = softwareSystem "S3/MinIO Storage" "Object storage for ML model artifacts" "External"
        vllmServer = softwareSystem "vLLM Server" "OpenAI-compatible LLM inference server for judge evaluations" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        # Relationships - Orchestrator to Detectors
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080 plaintext"
        orchestrator -> huggingfaceDetector "POST /api/v1/text/contents" "HTTP/8000 Istio mTLS"
        orchestrator -> llmJudgeDetector "POST /api/v1/text/contents, POST /api/v1/text/generation" "HTTP/8000 Istio mTLS"

        # Relationships - Internal
        builtInDetector -> commonLibrary "inherits DetectorBaseAPI"
        huggingfaceDetector -> commonLibrary "inherits DetectorBaseAPI"
        llmJudgeDetector -> commonLibrary "inherits DetectorBaseAPI"

        # Relationships - External
        llmJudgeDetector -> vllmServer "Sends evaluation prompts" "HTTP/8080"
        huggingfaceDetector -> s3Storage "Downloads model artifacts (via KServe Storage Initializer)" "HTTP/9000 AWS IAM"
        kserve -> huggingfaceDetector "Deploys as InferenceService + ServingRuntime"
        kserve -> llmJudgeDetector "Deploys as InferenceService + ServingRuntime"
        istio -> builtInDetector "Sidecar injection for mTLS"
        istio -> huggingfaceDetector "Sidecar injection for mTLS"
        istio -> llmJudgeDetector "Sidecar injection for mTLS"
        prometheus -> builtInDetector "Scrapes /metrics" "HTTP/8080"
        prometheus -> huggingfaceDetector "Scrapes /metrics" "HTTP/8080"
        prometheus -> llmJudgeDetector "Scrapes /metrics" "HTTP/8080"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Library" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #e1d5e7
                color #333333
                shape person
            }
        }
    }
}
