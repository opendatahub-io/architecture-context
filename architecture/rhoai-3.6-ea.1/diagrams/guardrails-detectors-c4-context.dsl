workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Upstream caller that invokes detector APIs for content safety evaluation"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of content safety detection microservices for the FMS Guardrails pipeline" {
            builtInDetector = container "Built-in Detector" "Local regex pattern matching and file-type validation" "Python/FastAPI" "Detector"
            hfDetector = container "HuggingFace Detector" "Transformer model inference for sequence/token classification" "Python/FastAPI/PyTorch" "Detector"
            judgeDetector = container "LLM Judge Detector" "Delegates content evaluation to remote vLLM server" "Python/FastAPI" "Detector"
            baseAPI = container "DetectorBaseAPI" "Shared FastAPI base class providing health checks, Prometheus metrics, error handling" "Python/FastAPI" "Framework"
        }

        vllmServer = softwareSystem "vLLM Inference Server" "Remote LLM serving infrastructure for content evaluation" "External"
        minioStorage = softwareSystem "MinIO Storage" "Model artifact storage for HuggingFace detector models" "Internal"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal"
        kserve = softwareSystem "KServe" "Serving runtime platform managing detector deployments" "Internal RHOAI"

        orchestrator -> guardrailsDetectors "Sends content analysis requests" "HTTP POST /api/v1/text/contents, /api/v1/text/generation"
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000"
        orchestrator -> judgeDetector "POST /api/v1/text/contents" "HTTP/8000"

        judgeDetector -> vllmServer "Delegates content evaluation" "HTTP/HTTPS via VLLM_BASE_URL"
        hfDetector -> minioStorage "Loads model artifacts" "TCP/9000"
        prometheus -> guardrailsDetectors "Scrapes metrics" "HTTP GET /metrics"

        kserve -> hfDetector "Manages via ServingRuntime" "guardrails-detector-runtime-guardian"
        kserve -> judgeDetector "Manages via ServingRuntime" "guardrails-detector-runtime-judge"

        builtInDetector -> baseAPI "Extends" ""
        hfDetector -> baseAPI "Extends" ""
        judgeDetector -> baseAPI "Extends" ""
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
            element "Internal" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Detector" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Framework" {
                background #f5a623
                color #ffffff
                shape Hexagon
            }
        }
    }
}
