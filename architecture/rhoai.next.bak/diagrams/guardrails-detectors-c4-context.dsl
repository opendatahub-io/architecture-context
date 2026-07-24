workspace {
    model {
        dataScientist = person "Data Scientist" "Configures guardrail detectors and deploys models for content safety"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and guardrails configuration"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of text detection microservices for content safety analysis" {
            builtInDetector = container "Built-in Detector" "Regex-based PII detection (email, SSN, CC, phone, IP), file-type validation (JSON, XML, YAML), and custom Python detector execution" "Python/FastAPI/uvicorn" {
                regexRegistry = component "RegexDetectorRegistry" "Pattern matching for PII entities" "Python"
                fileTypeRegistry = component "FileTypeDetectorRegistry" "JSON/XML/YAML schema validation" "Python"
                customRegistry = component "CustomDetectorRegistry" "Runtime-extensible Python guardrails with static analysis sandbox" "Python"
            }
            hfDetector = container "HuggingFace Detector" "HuggingFace model inference for sequence classification, token classification, and Granite causal LM content analysis" "Python/FastAPI/PyTorch"
            judgeDetector = container "LLM Judge Detector" "LLM-as-a-Judge evaluation proxy using vllm_judge library for flexible content assessment" "Python/FastAPI"
            commonLib = container "Common Library" "Shared FastAPI base class (DetectorBaseAPI), Pydantic schemas, Prometheus instrumentation (trustyai_guardrails_*), health endpoints" "Python Library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Intercepts text generation input/output and routes content to detector microservices" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform providing InferenceService, ServingRuntime, and storage initialization" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS encryption, traffic management, and platform authentication" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"

        s3Storage = softwareSystem "S3-compatible Storage" "Model weight storage (MinIO or AWS S3)" "External"
        vllmServer = softwareSystem "vLLM Server" "OpenAI-compatible LLM server for judge evaluation (Qwen, Llama, etc.)" "External"

        # Relationships - External actors
        dataScientist -> kserve "Deploys InferenceService with detector model" "kubectl/Dashboard"
        platformAdmin -> orchestrator "Configures guardrails policies"

        # Relationships - Orchestrator to Detectors
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000"
        orchestrator -> judgeDetector "POST /api/v1/text/contents" "HTTP/8000"

        # Relationships - KServe management
        kserve -> hfDetector "Deploys as InferenceService predictor container"
        kserve -> judgeDetector "Deploys as InferenceService predictor container"
        kserve -> s3Storage "Downloads model weights via Storage Initializer" "HTTP(S)/9000,443"

        # Relationships - Detector to external
        judgeDetector -> vllmServer "Evaluation API calls" "HTTP/8080"

        # Relationships - Platform services
        istio -> builtInDetector "mTLS sidecar injection"
        istio -> hfDetector "mTLS sidecar injection"
        istio -> judgeDetector "mTLS sidecar injection"
        prometheus -> builtInDetector "Scrapes /metrics" "HTTP/8080"
        prometheus -> hfDetector "Scrapes /metrics" "HTTP/8000"
        prometheus -> judgeDetector "Scrapes /metrics" "HTTP/8000"

        # Internal container relationships
        builtInDetector -> commonLib "Extends DetectorBaseAPI"
        hfDetector -> commonLib "Extends DetectorBaseAPI"
        judgeDetector -> commonLib "Extends DetectorBaseAPI"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
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
