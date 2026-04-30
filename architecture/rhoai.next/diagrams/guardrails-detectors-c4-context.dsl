workspace {
    model {
        dataScientist = person "Data Scientist" "Configures guardrails detectors and evaluation criteria for model safety"
        platformAdmin = person "Platform Admin" "Deploys and manages detector services on RHOAI"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of detector microservices for text content analysis (safety, PII, file validation, LLM-as-a-judge)" {
            builtInDetector = container "Built-in Detector" "Lightweight regex PII detection, file type validation, and custom Python detector execution" "Python FastAPI :8080" "Detector"
            hfDetector = container "HuggingFace Detector" "ML-based content classification using HuggingFace transformer models (AutoModelForSequenceClassification, GraniteForCausalLM)" "Python FastAPI :8000" "Detector"
            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-a-judge evaluation using external OpenAI-compatible LLM servers via vLLM Judge (31+ metrics)" "Python FastAPI :8000" "Detector"
            commonLib = container "Common Library" "Shared FastAPI base application, Pydantic schemas (IBM Detector API), Prometheus instrumentation" "Python Library" "Library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Invokes detectors on text generation input/output for content safety" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML model serving platform, manages InferenceServices and ServingRuntimes" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS transport security and sidecar injection for KServe-deployed detectors" "Internal RHOAI"
        s3 = softwareSystem "S3/MinIO" "Object storage for ML model files" "External"
        vllm = softwareSystem "vLLM / OpenAI-compatible LLM Server" "External LLM for judge evaluation prompts" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public model registry for downloading transformer models" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        # Relationships
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP :8080 plaintext"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP :8000 mTLS (Istio)"
        orchestrator -> llmJudgeDetector "POST /api/v1/text/contents, /api/v1/text/generation" "HTTP :8000 mTLS (Istio)"

        builtInDetector -> commonLib "Uses" "Python import"
        hfDetector -> commonLib "Uses" "Python import"
        llmJudgeDetector -> commonLib "Uses" "Python import"

        kserve -> hfDetector "Manages lifecycle" "InferenceService CRD"
        kserve -> llmJudgeDetector "Manages lifecycle" "InferenceService CRD"

        istio -> hfDetector "Sidecar injection, mTLS" "Service mesh"
        istio -> llmJudgeDetector "Sidecar injection, mTLS" "Service mesh"

        hfDetector -> s3 "Download model files" "HTTP :9000 AWS IAM"
        hfDetector -> huggingfaceHub "Download models (optional, init)" "HTTPS :443 TLS 1.2+"
        llmJudgeDetector -> vllm "Send evaluation prompts" "HTTP configurable"

        prometheus -> builtInDetector "Scrape metrics" "HTTP GET /metrics"
        prometheus -> hfDetector "Scrape metrics" "HTTP GET /metrics"
        prometheus -> llmJudgeDetector "Scrape metrics" "HTTP GET /metrics"

        dataScientist -> orchestrator "Configures guardrails for model inference"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
