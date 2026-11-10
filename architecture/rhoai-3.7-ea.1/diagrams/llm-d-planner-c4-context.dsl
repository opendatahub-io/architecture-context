workspace "llm-d-planner" "C4 model for llm-d Planner (RHOAI 3.7-ea.1)" {
    model {
        user = person "Platform Engineer / Data Scientist" "Describes LLM workloads and SLOs; reviews sized deployment recommendations"
        apiClient = person "API Client" "Automation calling the planner REST API directly (no auth)"

        planner = softwareSystem "llm-d Planner" "Turns business requirements (use case, users, SLOs) into sized LLM deployment recommendations and KServe / llm-d manifests" {
            ui = container "UI" "Streamlit wizard, Capacity Planner and GPU Recommender pages" "Python / Streamlit, 8501/TCP"
            backend = container "Backend API" "Intent extraction, specification, recommendation, config generation, cluster deploy, benchmark DB and quality-data admin. No auth middleware." "Python / FastAPI / uvicorn, 8000/TCP"
            db = container "Benchmark DB" "Embedded benchmark store at /app/db/planner.db on RWO PVC" "SQLite" "Database"
            ollama = container "Ollama" "Local LLM (granite3.3:2b) for intent extraction, 1 NVIDIA GPU" "ollama/ollama:latest, 11434/TCP"
            simulator = container "vLLM Simulator" "vLLM-compatible OpenAI API backed by benchmark JSON for GPU-free simulator mode" "Python / FastAPI, 8080/TCP"
            cli = container "planner CLI / library" "Offline Planner API published to PyPI as llm-d-planner" "Python package"
        }

        router = softwareSystem "OpenShift Router" "Edge-TLS Routes planner and planner-backend, no auth proxy" "External"
        k8s = softwareSystem "Kubernetes API" "Node GPU labels; namespace and InferenceService apply/get/delete" "External"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Validated model benchmark data (redhat_ai_validated_models)" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serves generated InferenceService (RawDeployment)" "Internal RHOAI"
        llmd = softwareSystem "llm-d" "Alternative deployment target via generated kustomize/Helm values" "Internal RHOAI"
        serviceCA = softwareSystem "OpenShift Service CA" "Injects CA bundle into planner-service-ca ConfigMap" "Internal RHOAI"
        vertex = softwareSystem "Vertex AI (Claude)" "Optional LLM provider" "External"
        openai = softwareSystem "OpenAI-compatible API" "Optional LLM provider" "External"
        hf = softwareSystem "HuggingFace Hub" "Model configs and LMArena leaderboard dataset" "External"
        aa = softwareSystem "Artificial Analysis" "Model quality scores (API v2)" "External"

        user -> router "Uses UI" "HTTPS/443"
        apiClient -> router "Calls REST API (unauthenticated)" "HTTPS/443"
        router -> ui "Forwards" "HTTP/8501"
        router -> backend "Forwards" "HTTP/8000"
        ui -> backend "All planning operations" "HTTP/8000"
        backend -> db "Reads/writes benchmarks" "File"
        backend -> ollama "Intent extraction" "HTTP/11434"
        backend -> vertex "Intent extraction (optional)" "HTTPS/443, GCP SA creds"
        backend -> openai "Intent extraction (optional)" "HTTPS/443, Bearer API key"
        backend -> modelCatalog "Fetches benchmarks when PLANNER_BENCHMARK_SOURCE=model_catalog" "HTTPS/8443, Bearer, service-CA TLS"
        backend -> k8s "list nodes; kubectl create ns / apply / delete" "HTTPS/6443, SA token"
        backend -> hf "Model configs, Arena data" "HTTPS/443"
        backend -> aa "Quality scores" "HTTPS/443, AA_API_KEY"
        serviceCA -> backend "Provides CA bundle for Model Catalog TLS"
        backend -> kserve "Generates InferenceService / HPA / ServiceMonitor manifests"
        backend -> llmd "Generates kustomize / Helm values"
        kserve -> simulator "Runs simulator image in simulator mode"
        cli -> db "Uses library in-process"
    }

    views {
        systemContext planner "SystemContext" {
            include *
            autoLayout
        }

        container planner "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
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
            element "Database" {
                shape cylinder
                background #f5a623
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
