workspace "guardrails-detectors (RHOAI 3.7-ea.1)" {
    model {
        user = person "Data Scientist" "Deploys guardrails detector InferenceServices in a project namespace"

        detectors = softwareSystem "guardrails-detectors" "FMS Detector API microservices that classify text for safety, PII and format violations" {
            common = container "detectors/common" "DetectorBaseAPI: registry, /health, trustyai_guardrails_* metrics, FMS Detector API schemas" "Python library"
            hf = container "HF Detector Runtime" "Runs HF sequence/token classifiers and Granite Guardian; only image built by Konflux on this branch" "Python, FastAPI, uvicorn :8000, torch" "Shipped"
            builtin = container "Built-in Detector" "Regex PII, JSON/YAML/XML validators, custom Python detectors; not built on this branch" "Python, FastAPI, uvicorn :8080" "Upstream"
            judge = container "LLM-judge Detector" "LLM-as-a-judge via vllm-judge; upstream only" "Python, FastAPI, uvicorn :8000" "Upstream"

            hf -> common "Subclasses"
            builtin -> common "Subclasses"
            judge -> common "Subclasses"
        }

        orchestrator = softwareSystem "FMS Guardrails Orchestrator" "Calls detectors on LLM input and output" "Internal ODH"
        kserve = softwareSystem "KServe" "Hosts the detector as an InferenceService predictor (RawDeployment)" "Internal ODH"
        odhmc = softwareSystem "odh-model-controller" "Ships the OOTB guardrails-detector-huggingface-serving-template; adds auth/routing" "Internal ODH"
        rhods = softwareSystem "rhods-operator" "Distributes the runtime image digest as a related image" "Internal ODH"
        dashboard = softwareSystem "odh-dashboard" "UI deployment of the detector runtime" "Internal ODH"
        prometheus = softwareSystem "Prometheus (UWM)" "Scrapes detector metrics" "Internal ODH"
        s3 = softwareSystem "S3 Storage" "Model weights (via data connection)" "External"
        llm = softwareSystem "Judge LLM" "OpenAI-compatible endpoint at VLLM_BASE_URL" "External"

        user -> kserve "Creates InferenceService with the detector ServingRuntime"
        user -> dashboard "Deploys detector runtime from UI"
        dashboard -> kserve "Creates InferenceService"
        odhmc -> kserve "Provides ServingRuntime template"
        rhods -> odhmc "Supplies image via related-image env"
        kserve -> hf "Runs predictor; storage-initializer populates /mnt/models"
        kserve -> s3 "Downloads model artifacts" "HTTPS/443 or HTTP/9000"
        orchestrator -> hf "POST /api/v1/text/contents" "HTTP/8000"
        orchestrator -> builtin "POST /api/v1/text/contents" "HTTP/8080"
        orchestrator -> judge "POST /api/v1/text/contents, /generation" "HTTP/8000"
        prometheus -> hf "GET /metrics" "HTTP/8000"
        judge -> llm "Judge requests" "HTTP/HTTPS"
    }

    views {
        systemContext detectors "SystemContext" {
            include *
            autoLayout
        }

        container detectors "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
            }
            element "Shipped" {
                background #4a90e2
                color #ffffff
            }
            element "Upstream" {
                background #9fbfe6
            }
        }
    }
}
