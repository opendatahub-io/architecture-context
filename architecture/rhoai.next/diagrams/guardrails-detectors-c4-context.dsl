workspace {
    model {
        dataScientist = person "Data Scientist" "Configures guardrails policies and custom detectors"
        mlEngineer = person "ML Engineer" "Deploys and manages detector InferenceServices"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of text detection microservices for PII detection, content validation, ML classification, and LLM-as-Judge evaluation" {
            builtInDetector = container "Built-in Detector" "Regex-based PII detection, file-type validation (JSON/XML/YAML with schema), and custom Python detector execution" "Python FastAPI/uvicorn" "8080/TCP"
            hfDetector = container "HuggingFace Detector" "ML model inference using HuggingFace transformers for sequence classification, token classification, and causal LM guardrailing" "Python FastAPI/uvicorn + PyTorch" "8000/TCP"
            llmJudge = container "LLM Judge Detector" "LLM-as-a-Judge evaluation using an external vLLM server via the vllm_judge library" "Python FastAPI/uvicorn" "8000/TCP"
            commonLib = container "Common Library" "Shared FastAPI base class, Pydantic schemas, Prometheus metrics instrumentation, and logging configuration" "Python Library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Routes content analysis requests to appropriate detector services" "Internal Platform"
        kserve = softwareSystem "KServe" "Kubernetes-native model serving platform for deploying InferenceServices" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, traffic management, and PeerAuthentication" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        s3Storage = softwareSystem "S3/MinIO Storage" "Model artifact storage for HuggingFace detector models" "Internal Service"
        vllmServer = softwareSystem "vLLM Server" "OpenAI-compatible LLM inference server for Judge evaluations" "Internal Service"
        hfHub = softwareSystem "HuggingFace Hub" "Public model repository (example deployment only)" "External"

        # Relationships
        orchestrator -> guardrailsDetectors "Sends content analysis requests" "HTTP/REST, mTLS"
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080, mTLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000, mTLS"
        orchestrator -> llmJudge "POST /api/v1/text/contents" "HTTP/8000, mTLS"

        builtInDetector -> commonLib "Uses base class and schemas"
        hfDetector -> commonLib "Uses base class and schemas"
        llmJudge -> commonLib "Uses base class and schemas"

        hfDetector -> s3Storage "Downloads model files at startup" "HTTP/9000, AWS credentials"
        llmJudge -> vllmServer "Sends LLM evaluation requests" "HTTP/8080"
        hfDetector -> hfHub "Downloads models (example only)" "HTTPS/443"

        kserve -> hfDetector "Deploys and manages"
        kserve -> llmJudge "Deploys and manages"
        istio -> guardrailsDetectors "Provides mTLS sidecar injection"
        prometheus -> guardrailsDetectors "Scrapes /metrics endpoints" "HTTP"

        mlEngineer -> kserve "Deploys detector InferenceServices"
        dataScientist -> builtInDetector "Configures custom detectors"
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
            element "Internal Service" {
                background #f5a623
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
        }
    }
}
