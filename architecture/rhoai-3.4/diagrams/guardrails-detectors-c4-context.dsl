workspace {
    model {
        datascientist = person "Data Scientist" "Configures guardrail detectors and detection policies"
        admin = person "Platform Admin" "Deploys and manages guardrails stack on RHOAI"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of detector microservices for text content analysis (PII, toxicity, file validation, LLM-as-a-judge)" {
            builtInDetector = container "Built-in Detector" "Lightweight heuristic text detection: regex PII (email, CC, SSN, phone, IP), file-type validation (JSON/XML/YAML + schema), custom Python detectors" "Python FastAPI/uvicorn, 8080/TCP" {
                regexRegistry = component "RegexDetectorRegistry" "Regex-based PII detection patterns" "Python"
                fileTypeRegistry = component "FileTypeDetectorRegistry" "JSON/XML/YAML validation with optional schema" "Python"
                customRegistry = component "CustomDetectorRegistry" "User-provided Python functions with AST security checking" "Python"
            }

            hfDetector = container "HuggingFace Detector" "ML model-based content classification using HuggingFace transformers (AutoModelForSequenceClassification or GraniteForCausalLM)" "Python FastAPI/uvicorn, 8000/TCP"

            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-a-judge evaluation using vllm_judge library against external vLLM server" "Python FastAPI/uvicorn, 8000/TCP"

            commonFramework = container "Common Framework" "Shared DetectorBaseAPI, Pydantic schemas (IBM Detector API), InstrumentedDetector metrics" "Python library (detectors/common/)"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Invokes detectors on text generation input/output per configured policies" "Internal RHOAI"

        kserve = softwareSystem "KServe" "Serverless ML inference platform hosting detectors as InferenceServices (RawDeployment mode)" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Traffic management, mTLS encryption, and authentication enforcement via sidecar injection" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        s3 = softwareSystem "S3/MinIO Storage" "S3-compatible object storage for ML model artifacts" "External"
        vllmServer = softwareSystem "vLLM Inference Server" "OpenAI-compatible LLM serving for judge evaluations" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Public model repository for downloading pre-trained models" "External"

        # Relationships - Orchestrator to Detectors
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080, Istio mTLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000, Istio mTLS"
        orchestrator -> llmJudgeDetector "POST /api/v1/text/contents, /api/v1/text/generation" "HTTP/8000, Istio mTLS"

        # Internal detector dependencies
        builtInDetector -> commonFramework "extends DetectorBaseAPI"
        hfDetector -> commonFramework "extends DetectorBaseAPI"
        llmJudgeDetector -> commonFramework "extends DetectorBaseAPI"

        # External dependencies
        hfDetector -> s3 "Downloads model files at startup" "HTTP/9000, AWS credentials"
        hfDetector -> hfHub "Downloads models (init container)" "HTTPS/443, TLS 1.2+"
        llmJudgeDetector -> vllmServer "LLM evaluation requests" "HTTP/8080, in-cluster"

        # Platform dependencies
        kserve -> builtInDetector "Hosts as InferenceService"
        kserve -> hfDetector "Hosts as InferenceService"
        kserve -> llmJudgeDetector "Hosts as InferenceService"
        istio -> builtInDetector "mTLS sidecar injection"
        istio -> hfDetector "mTLS sidecar injection"
        istio -> llmJudgeDetector "mTLS sidecar injection"
        prometheus -> builtInDetector "Scrapes /metrics" "HTTP/8080"
        prometheus -> hfDetector "Scrapes /metrics" "HTTP/8000"
        prometheus -> llmJudgeDetector "Scrapes /metrics" "HTTP/8000"

        # User interactions
        datascientist -> orchestrator "Configures detection policies"
        admin -> kserve "Deploys detector InferenceServices"
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

        component builtInDetector "BuiltInComponents" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
