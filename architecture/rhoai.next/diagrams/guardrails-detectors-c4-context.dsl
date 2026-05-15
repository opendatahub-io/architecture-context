workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Calls detector endpoints for content analysis as part of the guardrails pipeline"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of detector algorithm microservices for text content safety analysis" {
            builtInDetector = container "Built-in Detector" "Lightweight text detection via regex (PII), file-type validation, and custom Python detectors" "Python FastAPI/uvicorn" "Service"
            huggingfaceDetector = container "HuggingFace Detector" "ML model-based content classification using HuggingFace Transformers and PyTorch" "Python FastAPI/uvicorn" "Service"
            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-a-judge content evaluation via external vLLM server (upstream only)" "Python FastAPI/uvicorn" "Upstream"
            commonFramework = container "Common Framework" "Shared FastAPI base class, Pydantic schemas, Prometheus instrumentation, logging" "Python Library" "Library"
        }

        kserve = softwareSystem "KServe" "Kubernetes inference serving platform for deploying ML models" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS and traffic management" "External"
        s3Storage = softwareSystem "S3/Minio Storage" "Object storage for HuggingFace model artifacts" "External"
        vllmServer = softwareSystem "vLLM Server" "External vLLM-compatible LLM server for judge evaluation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model repository for downloading pre-trained models" "External"

        # Relationships - System Context
        orchestrator -> guardrailsDetectors "Calls detector endpoints for content analysis" "HTTP REST"

        # Relationships - Container Level
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080"
        orchestrator -> huggingfaceDetector "POST /api/v1/text/contents" "HTTP/8000"
        orchestrator -> llmJudgeDetector "POST /api/v1/text/contents, /api/v1/text/generation" "HTTP/8000"

        builtInDetector -> commonFramework "extends DetectorBaseAPI"
        huggingfaceDetector -> commonFramework "extends DetectorBaseAPI"
        llmJudgeDetector -> commonFramework "extends DetectorBaseAPI"

        llmJudgeDetector -> vllmServer "Delegates LLM-as-a-judge evaluation" "HTTP (OpenAI-compatible)"
        huggingfaceDetector -> s3Storage "Downloads model artifacts via KServe storage initializer" "HTTP/9000"
        huggingfaceDetector -> huggingfaceHub "Downloads pre-trained models (init)" "HTTPS/443"

        kserve -> huggingfaceDetector "Deploys as InferenceService/ServingRuntime"
        kserve -> llmJudgeDetector "Deploys as InferenceService/ServingRuntime"
        istio -> guardrailsDetectors "Provides sidecar mTLS and traffic management"

        prometheus -> builtInDetector "Scrapes /metrics" "HTTP/8080"
        prometheus -> huggingfaceDetector "Scrapes /metrics" "HTTP/8000"
        prometheus -> llmJudgeDetector "Scrapes /metrics" "HTTP/8000"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Upstream" {
                background #f5a623
                color #ffffff
            }
            element "Service" {
                background #7ed321
                color #ffffff
            }
            element "Library" {
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
