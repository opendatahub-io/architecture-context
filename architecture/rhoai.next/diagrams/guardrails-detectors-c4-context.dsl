workspace {
    model {
        operator = person "Platform Operator" "Deploys and configures guardrails detectors via KServe InferenceServices"
        datascientist = person "Data Scientist" "Uses LLM applications protected by guardrails"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of detector microservices for text content analysis, PII detection, file validation, and LLM-as-a-judge evaluation" {
            builtInDetector = container "Built-in Detector" "Lightweight regex-based PII detection (email, CC, SSN, phone, IP), file-type validation (JSON, XML, YAML), and custom detector functions" "Python FastAPI, 8080/TCP" {
                regexRegistry = component "RegexDetectorRegistry" "Regex-based PII pattern matching" "Python"
                fileTypeRegistry = component "FileTypeDetectorRegistry" "JSON/XML/YAML schema validation" "Python"
                customRegistry = component "CustomDetectorRegistry" "User-defined Python functions with AST security validation" "Python"
            }
            hfDetector = container "HuggingFace Detector" "ML model-based content classification using AutoModelForSequenceClassification, TokenClassification, or GraniteForCausalLM" "Python FastAPI + PyTorch, 8000/TCP"
            judgeDetector = container "LLM Judge Detector" "LLM-as-a-judge content evaluation via vllm_judge library with built-in and custom metrics" "Python FastAPI, 8000/TCP"
            commonLib = container "Common Library" "Shared FastAPI base class, Pydantic schemas, Prometheus instrumentation, health endpoint" "Python Library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "IBM-led orchestrator that invokes detectors on LLM text generation input/output" "External"
        kserve = softwareSystem "KServe" "Kubernetes-native serverless inference platform for deploying detectors as InferenceServices" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and sidecar injection" "Internal RHOAI"
        vllmServing = softwareSystem "vLLM Serving" "OpenAI-compatible LLM server for judge evaluations" "Internal RHOAI"
        s3Storage = softwareSystem "S3/Minio Storage" "Object storage for HuggingFace model artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing AI/ML workloads" "Internal RHOAI"

        # User interactions
        datascientist -> orchestrator "Submits text for guardrail analysis (via LLM application)"
        operator -> kserve "Deploys InferenceService CRs for detectors"

        # Orchestrator to detectors
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080 via platform TLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000 via platform TLS"
        orchestrator -> judgeDetector "POST /api/v1/text/contents" "HTTP/8000 via platform TLS"

        # Detector internal dependencies
        builtInDetector -> commonLib "Extends BaseDetectorApp"
        hfDetector -> commonLib "Extends BaseDetectorApp"
        judgeDetector -> commonLib "Extends BaseDetectorApp"

        # External dependencies
        hfDetector -> s3Storage "Downloads model files via KServe storage initializer" "HTTP/9000, AWS credentials"
        judgeDetector -> vllmServing "Delegates LLM evaluation via Judge.from_url()" "HTTP/8080, no auth"

        # Platform dependencies
        guardrailsDetectors -> kserve "Deployed as KServe InferenceServices with ServingRuntime CRs"
        guardrailsDetectors -> istio "Sidecar injection for mTLS (sidecar.istio.io/inject: true)"

        # Observability
        prometheus -> builtInDetector "Scrapes /metrics endpoint" "HTTP/8080"
        prometheus -> hfDetector "Scrapes /metrics endpoint" "HTTP/8000"
        prometheus -> judgeDetector "Scrapes /metrics endpoint" "HTTP/8000"

        # Dashboard integration
        rhoaiDashboard -> guardrailsDetectors "Displays InferenceService status (opendatahub.io/dashboard: true)"
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
