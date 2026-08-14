workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Sends content analysis requests to detector microservices"

        guardrailsDetectors = softwareSystem "guardrails-detectors" "Collection of content-analysis microservices providing regex, ML-based, and LLM-as-Judge text detection" {
            builtInDetector = container "Built-in Detector" "Regex pattern matching, file-type validation, custom detector plugins" "Python/FastAPI" "Port 8080"
            hfDetector = container "HuggingFace Detector" "Transformer-based classification (AutoModelForSequenceClassification, GraniteForCausalLM)" "Python/FastAPI" "Port 8000"
            llmJudgeDetector = container "LLM Judge Detector" "Delegates content evaluation to external vLLM via vllm-judge library" "Python/FastAPI" "Port 8000"
        }

        kserve = softwareSystem "KServe" "Kubernetes model serving platform managing ServingRuntimes" "External"
        vllm = softwareSystem "vLLM Inference Server" "LLM inference backend (e.g. qwen2-predictor)" "External"
        minio = softwareSystem "MinIO" "S3-compatible object storage for ML model artifacts" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        orchestrator -> guardrailsDetectors "Sends POST /api/v1/text/contents, /api/v1/text/generation" "HTTP/8000,8080"
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000"
        orchestrator -> llmJudgeDetector "POST /api/v1/text/contents, /api/v1/text/generation" "HTTP/8000"

        llmJudgeDetector -> vllm "Delegates evaluation via vllm-judge" "HTTP/8080"
        hfDetector -> minio "Loads transformer models at startup" "S3/HTTP 9000"

        kserve -> guardrailsDetectors "Manages as ServingRuntime definitions"
        prometheus -> guardrailsDetectors "Scrapes /metrics and /api/v1/metrics" "HTTP"
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
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #27ae60
                color #ffffff
                shape person
            }
        }
    }
}
