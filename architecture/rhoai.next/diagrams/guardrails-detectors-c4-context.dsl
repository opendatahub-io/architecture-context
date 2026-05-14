workspace {
    model {
        operator = person "Platform Operator" "Deploys and configures guardrails detectors"
        dataScientist = person "Data Scientist" "Configures guardrails policies via Orchestrator"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of text detection microservices for content safety and PII detection" {
            builtInDetector = container "Built-in Detector" "Regex-based PII detection, file-type validation, custom Python detectors" "Python FastAPI/uvicorn, 8080/TCP"
            hfDetector = container "HuggingFace Detector" "ML model inference for content classification using HuggingFace transformers" "Python FastAPI/uvicorn + PyTorch, 8000/TCP"
            judgeDetector = container "LLM Judge Detector" "LLM-as-a-Judge evaluation using vllm_judge library" "Python FastAPI/uvicorn, 8000/TCP"
            commonLib = container "Common Library" "Shared FastAPI base class, Pydantic schemas, Prometheus instrumentation, logging" "Python Library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Orchestrates content analysis across multiple detectors" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform for deploying detectors" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "mTLS enforcement and traffic management" "External"
        s3 = softwareSystem "S3/MinIO Storage" "Model artifact storage" "External"
        vllmServer = softwareSystem "vLLM Server" "OpenAI-compatible LLM inference backend" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Pre-trained model repository" "External"

        # Relationships - External
        orchestrator -> guardrailsDetectors "Sends content analysis requests" "HTTP REST"
        kserve -> guardrailsDetectors "Deploys HuggingFace and LLM Judge detectors as InferenceServices"
        operator -> kserve "Configures ServingRuntimes and InferenceServices" "kubectl/oc"

        # Relationships - Internal
        builtInDetector -> commonLib "Extends DetectorBaseAPI"
        hfDetector -> commonLib "Extends DetectorBaseAPI"
        judgeDetector -> commonLib "Extends DetectorBaseAPI"

        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080 mTLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"
        orchestrator -> judgeDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"

        hfDetector -> s3 "Downloads model files via KServe Storage Initializer" "HTTP/9000 AWS IAM"
        judgeDetector -> vllmServer "Sends evaluation requests to LLM" "HTTP/8080"

        prometheus -> builtInDetector "Scrapes metrics" "HTTP GET /metrics"
        prometheus -> hfDetector "Scrapes metrics" "HTTP GET /metrics"
        prometheus -> judgeDetector "Scrapes metrics" "HTTP GET /metrics"

        istio -> builtInDetector "Enforces mTLS" "sidecar injection"
        istio -> hfDetector "Enforces mTLS" "sidecar injection"
        istio -> judgeDetector "Enforces mTLS" "sidecar injection"

        hfDetector -> hfHub "Downloads models (init container, example only)" "HTTPS/443"
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
