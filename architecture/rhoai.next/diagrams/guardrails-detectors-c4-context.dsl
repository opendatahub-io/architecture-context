workspace {
    model {
        dataScientist = person "Data Scientist" "Configures guardrails for ML model deployments"
        platformAdmin = person "Platform Admin" "Deploys and manages guardrails detector services"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of detector microservices for text content analysis (safety, PII, file validation, LLM-as-a-judge)" {
            builtInDetector = container "Built-in Detector" "Lightweight regex PII detection, file type validation, and custom Python detector execution" "Python FastAPI" "Detector"
            hfDetector = container "HuggingFace Detector" "ML-based content classification using HuggingFace transformer models (AutoModelForSequenceClassification, GraniteForCausalLM)" "Python FastAPI + PyTorch" "Detector"
            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-a-judge evaluation using external OpenAI-compatible LLM servers via vLLM Judge library" "Python FastAPI" "Detector"
            commonLibrary = container "Common Library" "Shared FastAPI base application, Pydantic schemas, Prometheus instrumentation" "Python Library" "Library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Orchestrates detector invocations on text generation input/output" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Kubernetes serving platform for ML models (InferenceService, ServingRuntime)" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS and traffic management" "External"
        s3 = softwareSystem "S3/MinIO" "Object storage for ML model artifacts" "External"
        vllmServer = softwareSystem "vLLM / OpenAI-compatible LLM Server" "External LLM server for judge evaluations" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "ML model repository (optional model downloads)" "External"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD pipeline for multi-arch container image builds" "External"

        # Relationships - External
        orchestrator -> guardrailsDetectors "Invokes detectors for content analysis" "HTTP REST"
        guardrailsDetectors -> s3 "Downloads model artifacts" "HTTP/9000"
        guardrailsDetectors -> vllmServer "Sends evaluation prompts" "HTTP"
        guardrailsDetectors -> huggingfaceHub "Optional model download" "HTTPS/443"
        kserve -> guardrailsDetectors "Manages HF and LLM Judge as InferenceServices"
        istio -> guardrailsDetectors "Provides mTLS sidecar" "mTLS"
        prometheus -> guardrailsDetectors "Scrapes /metrics endpoints" "HTTP"
        konflux -> guardrailsDetectors "Builds container images" "CI/CD"

        # Relationships - Internal
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"
        orchestrator -> llmJudgeDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"
        hfDetector -> s3 "Load model files via KServe storage initializer" "HTTP/9000"
        llmJudgeDetector -> vllmServer "Send evaluation prompts" "HTTP"
        builtInDetector -> commonLibrary "Uses base API and schemas"
        hfDetector -> commonLibrary "Uses base API and schemas"
        llmJudgeDetector -> commonLibrary "Uses base API and schemas"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Detector" {
                background #4a90e2
                color #ffffff
            }
            element "Library" {
                background #b8d4f0
                color #333333
            }
        }
    }
}
