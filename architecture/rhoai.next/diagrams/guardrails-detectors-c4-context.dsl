workspace {
    model {
        datascientist = person "Data Scientist" "Deploys ML models and configures guardrails for safe text generation"
        platformadmin = person "Platform Admin" "Deploys and manages guardrails infrastructure on OpenShift AI"

        guardrailsDetectors = softwareSystem "Guardrails Detectors" "Collection of detector microservices for text content analysis — regex/heuristic, ML model-based, and LLM-as-a-judge evaluation" {
            builtInDetector = container "Built-in Detector" "Lightweight heuristic detectors: regex PII (email, SSN, CC, phone, IP), file-type validation (JSON, XML, YAML), custom Python functions" "Python FastAPI, 8080/TCP"
            hfDetector = container "HuggingFace Detector" "ML model-based text classification using AutoModelForSequenceClassification, AutoModelForTokenClassification, or GraniteForCausalLM" "Python FastAPI, 8000/TCP"
            llmJudgeDetector = container "LLM Judge Detector" "LLM-as-a-judge content evaluation using vLLM Judge library with built-in and custom metrics" "Python FastAPI, 8000/TCP"
            commonLib = container "Common Library" "Shared DetectorBaseAPI, Pydantic schemas, InstrumentedDetector (Prometheus), health check" "Python Package"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Orchestrates detector invocations for text generation guardrailing" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Manages InferenceService and ServingRuntime lifecycle for ML model serving" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and platform auth enforcement" "Internal RHOAI"
        s3 = softwareSystem "S3/MinIO" "Object storage for ML model weights" "External"
        vllmServer = softwareSystem "External vLLM Server" "OpenAI-compatible LLM server for judge evaluation" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        dashboard = softwareSystem "OpenShift AI Dashboard" "Platform UI for managing ML workloads" "Internal RHOAI"

        # Relationships
        orchestrator -> builtInDetector "Calls POST /api/v1/text/contents" "HTTP/8080, mTLS"
        orchestrator -> hfDetector "Calls POST /api/v1/text/contents" "HTTP/8000, mTLS"
        orchestrator -> llmJudgeDetector "Calls POST /api/v1/text/contents" "HTTP/8000, mTLS"

        builtInDetector -> commonLib "Extends DetectorBaseAPI"
        hfDetector -> commonLib "Extends DetectorBaseAPI"
        llmJudgeDetector -> commonLib "Extends DetectorBaseAPI"

        hfDetector -> s3 "Downloads model weights at startup" "HTTP/9000, AWS IAM"
        llmJudgeDetector -> vllmServer "Sends evaluation requests" "HTTP, configurable"

        kserve -> hfDetector "Manages lifecycle via InferenceService/ServingRuntime CRs"
        kserve -> llmJudgeDetector "Manages lifecycle via InferenceService/ServingRuntime CRs"

        istio -> builtInDetector "Injects sidecar for mTLS"
        istio -> hfDetector "Injects sidecar for mTLS"
        istio -> llmJudgeDetector "Injects sidecar for mTLS"

        prometheus -> builtInDetector "Scrapes /metrics" "HTTP/8080"
        prometheus -> hfDetector "Scrapes /metrics" "HTTP/8000"
        prometheus -> llmJudgeDetector "Scrapes /metrics" "HTTP/8000"

        datascientist -> orchestrator "Sends text for guardrail analysis"
        platformadmin -> dashboard "Manages detector deployments"
        dashboard -> guardrailsDetectors "Discovers via opendatahub.io/dashboard: true label"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
