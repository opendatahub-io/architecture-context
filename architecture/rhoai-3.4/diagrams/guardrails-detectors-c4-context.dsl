workspace {
    model {
        datascientist = person "Data Scientist" "Deploys and configures guardrails for ML model inference"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and guardrails configuration"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of text content detector microservices for PII detection, file-type validation, ML classification, and LLM-as-a-judge evaluation" {
            builtInDetector = container "Built-in Detector" "Lightweight heuristic detectors: regex PII, file-type validation, custom user-defined detectors" "Python/FastAPI/uvicorn" "detector"
            hfDetector = container "HuggingFace Detector" "ML model-based content classification using HuggingFace transformers (sequence classification, causal LM)" "Python/FastAPI/PyTorch" "detector"
            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-a-judge evaluation using vllm_judge library against external vLLM server" "Python/FastAPI/vllm_judge" "detector"
            commonFramework = container "Common Framework" "Shared FastAPI base class, API schemas, Prometheus instrumentation, health endpoints" "Python Library" "library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "IBM-led orchestrator that invokes detectors on text generation input/output" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform, manages InferenceService lifecycle" "Internal RHOAI"
        s3Storage = softwareSystem "S3/MinIO Storage" "Object storage for ML model artifacts" "External"
        vllmServer = softwareSystem "vLLM Inference Server" "OpenAI-compatible LLM serving for judge evaluation" "External"
        istio = softwareSystem "Istio Service Mesh" "mTLS, traffic management, sidecar injection" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Platform UI for managing ML workloads" "Internal RHOAI"

        # Relationships - external
        datascientist -> orchestrator "Sends inference requests with guardrails"
        platformadmin -> rhoaiDashboard "Configures guardrails detectors"
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080 mTLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"
        orchestrator -> llmJudgeDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"

        # Internal relationships
        builtInDetector -> commonFramework "extends DetectorBaseAPI"
        hfDetector -> commonFramework "extends DetectorBaseAPI"
        llmJudgeDetector -> commonFramework "extends DetectorBaseAPI"

        # External service relationships
        kserve -> hfDetector "Manages InferenceService lifecycle, model download"
        kserve -> llmJudgeDetector "Manages InferenceService lifecycle"
        hfDetector -> s3Storage "Downloads model artifacts" "S3 API/HTTP/9000"
        llmJudgeDetector -> vllmServer "LLM evaluation requests" "HTTP/8080 OpenAI-compatible"
        istio -> builtInDetector "Sidecar injection, mTLS enforcement"
        istio -> hfDetector "Sidecar injection, mTLS enforcement"
        istio -> llmJudgeDetector "Sidecar injection, mTLS enforcement"
        prometheus -> builtInDetector "Scrapes /metrics" "HTTP/8080"
        prometheus -> hfDetector "Scrapes /metrics" "HTTP/8000"
        rhoaiDashboard -> guardrailsDetectors "Displays detector InferenceServices via opendatahub.io/dashboard annotation"
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
            element "detector" {
                background #4a90e2
                color #ffffff
            }
            element "library" {
                background #6c5ce7
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
