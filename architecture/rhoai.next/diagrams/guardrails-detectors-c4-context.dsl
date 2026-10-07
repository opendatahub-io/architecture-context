workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "IBM-led orchestrator that routes content through configured detectors"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of text detection microservices for content guardrailing" {
            builtInDetector = container "Built-in Detector" "Regex PII detection, file-type validation, custom Python detectors" "Python FastAPI :8080"
            hfDetector = container "HuggingFace Detector" "HuggingFace model inference (sequence/token classification, Granite Guardian)" "Python FastAPI :8000"
            judgeDetector = container "LLM Judge Detector" "LLM-as-a-judge evaluation via vllm_judge library" "Python FastAPI :8000"
            detectorBaseAPI = container "DetectorBaseAPI" "Shared FastAPI base class: /health, /metrics, ASGI lifespan" "Python Library"
            instrumentedDetector = container "InstrumentedDetector" "Prometheus counter management (trustyai_guardrails_*)" "Python Library"
            baseDetectorRegistry = container "BaseDetectorRegistry" "Abstract registry for built-in detector function dispatch" "Python Library"
        }

        kserve = softwareSystem "KServe" "Kubernetes model serving infrastructure" "External"
        istio = softwareSystem "Istio Service Mesh" "mTLS and platform authentication enforcement" "External"
        vllmServer = softwareSystem "vLLM Inference Server" "OpenAI-compatible LLM serving for judge evaluation" "External"
        s3Storage = softwareSystem "S3 / MinIO" "Model artifact storage for HuggingFace models" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "OpenDataHub/RHOAI management UI" "Internal RHOAI"

        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080 Mesh TLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000 Istio mTLS"
        orchestrator -> judgeDetector "POST /api/v1/text/contents, /generation" "HTTP/8000 Istio mTLS"

        builtInDetector -> detectorBaseAPI "extends" ""
        hfDetector -> detectorBaseAPI "extends" ""
        judgeDetector -> detectorBaseAPI "extends" ""
        builtInDetector -> instrumentedDetector "uses" ""
        hfDetector -> instrumentedDetector "uses" ""
        judgeDetector -> instrumentedDetector "uses" ""
        builtInDetector -> baseDetectorRegistry "dispatches via" ""

        judgeDetector -> vllmServer "LLM evaluation requests" "HTTP"
        hfDetector -> s3Storage "Model download via KServe storage initializer" "HTTP/9000 AWS auth"

        kserve -> hfDetector "Manages InferenceService lifecycle" ""
        kserve -> judgeDetector "Manages InferenceService lifecycle" ""
        istio -> hfDetector "mTLS sidecar injection + auth" ""
        istio -> judgeDetector "mTLS sidecar injection + auth" ""

        prometheus -> builtInDetector "Scrapes /metrics" "HTTP/8080"
        prometheus -> hfDetector "Scrapes /metrics" "HTTP/8000"

        rhoaiDashboard -> hfDetector "Dashboard visibility via annotation" ""
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
