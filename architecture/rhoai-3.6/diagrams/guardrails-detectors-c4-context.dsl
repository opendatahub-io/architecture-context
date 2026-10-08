workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Orchestrates guardrail checks on LLM input/output by invoking detector microservices"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of text detection microservices providing regex-based PII detection, HuggingFace model classification, and LLM-as-a-judge evaluation" {
            builtInDetector = container "Built-in Detector" "Lightweight heuristic text detectors: regex PII (email, CC, SSN, phone, IP), file-type validation (JSON, XML, YAML), custom detectors" "Python FastAPI/uvicorn, 4 workers, port 8080"
            huggingfaceDetector = container "HuggingFace Detector" "HuggingFace model-based content classification supporting sequence classification, token classification, and causal LM (Granite Guardian)" "Python FastAPI/uvicorn, port 8000, KServe InferenceService"
            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-a-judge evaluation via external vLLM server using vllm_judge library with built-in metrics catalog" "Python FastAPI/uvicorn, port 8000, KServe InferenceService"
            detectorBaseAPI = container "DetectorBaseAPI" "Shared FastAPI base class providing health checks, Prometheus instrumentation (trustyai_guardrails_ prefix), error handling" "Python Framework"
        }

        kserve = softwareSystem "KServe" "Kubernetes serverless ML inference platform" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh providing mTLS and auth enforcement" "Internal Platform"
        vllmServer = softwareSystem "vLLM Server" "OpenAI-compatible LLM inference server for judge evaluation" "External"
        modelStore = softwareSystem "HuggingFace Model Store" "Local or S3-compatible model artifact storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        orchestrator -> guardrailsDetectors "Invokes detectors via POST /api/v1/text/contents" "HTTP REST"
        orchestrator -> builtInDetector "Invokes for regex PII, file-type, custom detection" "HTTP/8080"
        orchestrator -> huggingfaceDetector "Invokes for model-based classification" "HTTP/8000, Platform TLS"
        orchestrator -> llmJudgeDetector "Invokes for LLM-as-a-judge evaluation" "HTTP/8000, Platform TLS"

        llmJudgeDetector -> vllmServer "Delegates evaluation via async HTTP" "HTTP/8080"
        huggingfaceDetector -> modelStore "Loads model artifacts" "Filesystem / S3"

        kserve -> huggingfaceDetector "Deploys and manages" "ServingRuntime / InferenceService"
        kserve -> llmJudgeDetector "Deploys and manages" "ServingRuntime / InferenceService"
        istio -> huggingfaceDetector "Enforces mTLS and auth" "Sidecar proxy"
        istio -> llmJudgeDetector "Enforces mTLS and auth" "Sidecar proxy"

        prometheus -> builtInDetector "Scrapes metrics" "HTTP/8080 /metrics"
        prometheus -> huggingfaceDetector "Scrapes metrics" "HTTP/8000 /metrics"

        builtInDetector -> detectorBaseAPI "Extends" ""
        huggingfaceDetector -> detectorBaseAPI "Extends" ""
        llmJudgeDetector -> detectorBaseAPI "Extends" ""
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape Person
            }
        }
    }
}
