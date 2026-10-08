workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Routes content detection requests to appropriate detector microservices"

        guardrailsDetectors = softwareSystem "guardrails-detectors" "Collection of text detection microservices for content safety analysis" {
            builtInDetector = container "built-in Detector" "Regex-based PII detection, file-type validation, and custom Python detectors" "Python FastAPI / uvicorn :8080"
            huggingfaceDetector = container "huggingface Detector" "HuggingFace Transformers ML model inference for content classification" "Python FastAPI / uvicorn :8000"
            llmJudgeDetector = container "llm_judge Detector" "LLM-as-a-judge content evaluation via remote vLLM server" "Python FastAPI / uvicorn :8000"
            detectorBaseAPI = container "DetectorBaseAPI" "Shared FastAPI subclass with detector registry, Prometheus instrumentation, error handling" "Python Framework"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform managing ServingRuntime and InferenceService lifecycle" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "mTLS enforcement, TLS termination, and platform-level authentication" "Internal Platform"
        minio = softwareSystem "S3/MinIO" "S3-compatible object storage for ML model artifacts" "Internal Service"
        vllmServer = softwareSystem "vLLM Inference Server" "OpenAI-compatible LLM server for judge evaluations" "External Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        orchestrator -> guardrailsDetectors "Sends detection requests" "HTTP POST /api/v1/text/contents"
        orchestrator -> builtInDetector "Content analysis (regex, file-type, custom)" "HTTP/8080"
        orchestrator -> huggingfaceDetector "ML classification" "HTTP/8000"
        orchestrator -> llmJudgeDetector "LLM evaluation" "HTTP/8000"

        builtInDetector -> detectorBaseAPI "Extends" ""
        huggingfaceDetector -> detectorBaseAPI "Extends" ""
        llmJudgeDetector -> detectorBaseAPI "Extends" ""

        huggingfaceDetector -> minio "Loads model weights" "S3 API/9000"
        llmJudgeDetector -> vllmServer "Sends evaluation prompts" "HTTP (configurable URL)"

        guardrailsDetectors -> istio "Auth and mTLS enforcement" "Sidecar injection"
        guardrailsDetectors -> kserve "Deployment lifecycle" "InferenceService CRDs"
        prometheus -> guardrailsDetectors "Scrapes metrics" "HTTP GET /metrics"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Internal Service" {
                background #4a90e2
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
