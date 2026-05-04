workspace {
    model {
        orchestrator = person "FMS Guardrails Orchestrator" "Routes content through detection pipelines for guardrailing"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of text detection microservices for PII detection, content validation, ML classification, and LLM-as-a-Judge evaluation" {
            builtInDetector = container "Built-in Detector" "Regex-based PII detection, file-type validation (JSON/XML/YAML), and custom Python detector execution" "Python FastAPI/uvicorn :8080"
            hfDetector = container "HuggingFace Detector" "ML model inference using HuggingFace transformers for sequence classification, token classification, and causal LM guardrailing" "Python FastAPI/uvicorn :8000"
            judgeDetector = container "LLM Judge Detector" "LLM-as-a-Judge evaluation using external vLLM server via vllm_judge library" "Python FastAPI/uvicorn :8000"
            commonLib = container "Common Library" "Shared FastAPI base class, Pydantic schemas, Prometheus metrics, structured logging" "Python Library"
        }

        kserve = softwareSystem "KServe" "Kubernetes-native serverless ML inference platform" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS and traffic management" "Internal Platform"
        s3Storage = softwareSystem "S3/MinIO Storage" "Model artifact storage" "Internal"
        vllmServer = softwareSystem "vLLM Server" "OpenAI-compatible LLM inference server" "Internal"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        hfHub = softwareSystem "HuggingFace Hub" "Public ML model repository" "External"

        # Relationships
        orchestrator -> guardrailsDetectors "Sends text content for analysis" "HTTP/mTLS"
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080 mTLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"
        orchestrator -> judgeDetector "POST /api/v1/text/contents" "HTTP/8000 mTLS"

        builtInDetector -> commonLib "extends DetectorBaseAPI"
        hfDetector -> commonLib "extends DetectorBaseAPI"
        judgeDetector -> commonLib "extends DetectorBaseAPI"

        hfDetector -> s3Storage "Downloads model files" "HTTP/9000 AWS credentials"
        judgeDetector -> vllmServer "Sends evaluation requests" "HTTP/8080"

        kserve -> hfDetector "Deploys as InferenceService"
        kserve -> judgeDetector "Deploys as InferenceService"
        kserve -> s3Storage "Storage Initializer downloads models" "HTTP/9000"
        istio -> guardrailsDetectors "Provides mTLS sidecar injection"
        prometheus -> guardrailsDetectors "Scrapes /metrics endpoints" "HTTP/8080,8000"
        hfHub -> hfDetector "Model download (init container)" "HTTPS/443"
    }

    views {
        systemContext guardrailsDetectors "SystemContext" {
            include *
            autoLayout
            description "System context showing Guardrails Detectors in the RHOAI platform"
        }

        container guardrailsDetectors "Containers" {
            include *
            autoLayout
            description "Container view showing the three detector microservices and shared library"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Internal Platform" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #cccccc
                color #333333
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #7ed321
                color #ffffff
                shape person
            }
        }
    }
}
