workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models with content safety guardrails"
        mlEngineer = person "ML Engineer" "Configures and deploys detector services and custom guardrails"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of content safety detector microservices for FMS Guardrails Orchestrator" {
            builtInDetector = container "Built-in Detector" "Lightweight regex PII, file format validation, and custom Python detectors" "Python FastAPI / 8080/TCP"
            hfDetector = container "HuggingFace Runtime Detector" "ML model-based content classification using HuggingFace transformers" "Python FastAPI + PyTorch / 8000/TCP"
            judgeDetector = container "LLM Judge Detector" "LLM-as-a-judge content evaluation using vllm_judge library" "Python FastAPI / 8000/TCP"
            commonLib = container "Common Library" "Shared FastAPI base app, Pydantic schemas, Prometheus instrumentation, logging" "Python Library"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Orchestrates content safety detection across multiple detector services" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Kubernetes model serving infrastructure (ServingRuntime + InferenceService)" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and sidecar injection" "External"
        s3Storage = softwareSystem "S3/MinIO Storage" "Object storage for ML model weights" "External"
        vllmServer = softwareSystem "vLLM Inference Server" "OpenAI API-compatible LLM inference server" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        dashboard = softwareSystem "OpenShift AI Dashboard" "Web UI for managing AI/ML workloads" "Internal RHOAI"

        # Relationships
        orchestrator -> guardrailsDetectors "Calls detector endpoints for content analysis" "REST/HTTP, Istio mTLS"
        orchestrator -> builtInDetector "POST /api/v1/text/contents" "HTTP/8080, Istio mTLS"
        orchestrator -> hfDetector "POST /api/v1/text/contents" "HTTP/8000, Istio mTLS"
        orchestrator -> judgeDetector "POST /api/v1/text/contents" "HTTP/8000, Istio mTLS"

        builtInDetector -> commonLib "extends DetectorBaseAPI"
        hfDetector -> commonLib "extends DetectorBaseAPI"
        judgeDetector -> commonLib "extends DetectorBaseAPI"

        hfDetector -> s3Storage "Downloads model weights via KServe storage initializer" "HTTP/9000, AWS IAM"
        judgeDetector -> vllmServer "Sends evaluation requests to external LLM" "HTTP/8080, Istio mTLS"

        kserve -> guardrailsDetectors "Deploys and manages detector InferenceServices" "Kubernetes API"
        istio -> guardrailsDetectors "Provides sidecar proxy for mTLS" "Sidecar injection"
        prometheus -> guardrailsDetectors "Scrapes /metrics endpoints" "HTTP/8080, HTTP/8000"
        dashboard -> guardrailsDetectors "Displays InferenceService status" "Labels: opendatahub.io/dashboard"

        mlEngineer -> orchestrator "Configures guardrails pipeline"
        mlEngineer -> builtInDetector "Deploys custom Python detector functions"
        dataScientist -> dashboard "Monitors detector service health"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
