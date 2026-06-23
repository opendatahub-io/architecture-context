workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Invokes detectors on text generation input and output for content safety"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of detector microservices for text analysis: PII, content safety, file validation, LLM-as-a-judge" {
            builtInDetector = container "Built-In Detector" "Lightweight rule-based detection: regex PII, file type validation, custom Python detectors" "Python FastAPI/uvicorn" "detector"
            hfDetector = container "HuggingFace Detector" "ML model-based content classification using HuggingFace transformers (sequence, token, causal LM)" "Python FastAPI/uvicorn + PyTorch" "detector"
            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-a-judge content evaluation via vLLM Judge library" "Python FastAPI/uvicorn" "detector"
            commonBase = container "Common Base Framework" "DetectorBaseAPI: health, metrics, registry, exception handling" "Python" "framework"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native serverless ML inference platform" "External Platform"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS and traffic management" "External Platform"
        s3Storage = softwareSystem "S3 / MinIO" "S3-compatible object storage for ML model weights" "External Storage"
        vllmServer = softwareSystem "vLLM Server" "OpenAI-compatible LLM serving for judge evaluations" "External Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"
        hfHub = softwareSystem "HuggingFace Hub" "Public model repository for transformer models" "External SaaS"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD pipeline for container image builds" "External Platform"

        # Relationships
        orchestrator -> guardrailsDetectors "Sends text for analysis via POST /api/v1/text/contents" "HTTP/mTLS"
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080 mTLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"
        orchestrator -> llmJudgeDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"

        builtInDetector -> commonBase "extends"
        hfDetector -> commonBase "extends"
        llmJudgeDetector -> commonBase "extends"

        hfDetector -> s3Storage "Downloads model weights" "HTTP/9000 AWS IAM"
        llmJudgeDetector -> vllmServer "Sends evaluation prompts" "HTTP/8080"
        hfDetector -> hfHub "Downloads models (init)" "HTTPS/443 TLS 1.2+"

        kserve -> guardrailsDetectors "Manages deployment lifecycle via InferenceService/ServingRuntime CRDs"
        istio -> guardrailsDetectors "Provides mTLS and auth enforcement via sidecar injection"
        prometheus -> guardrailsDetectors "Scrapes /metrics endpoints" "HTTP"
        konflux -> guardrailsDetectors "Builds container images via Tekton pipelines"
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Storage" {
                background #f5a623
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "External SaaS" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "detector" {
                background #4a90e2
                color #ffffff
            }
            element "framework" {
                background #6bb3e0
                color #ffffff
            }
        }
    }
}
