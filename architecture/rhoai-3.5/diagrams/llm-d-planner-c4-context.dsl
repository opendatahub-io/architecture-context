workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models using conversational planning interface"

        llmdPlanner = softwareSystem "llm-d Planner" "LLM deployment planning service — capacity analysis, GPU recommendation, and SLO-driven deployment configuration" {
            backend = container "Backend API" "REST API for capacity planning, GPU recommendation, intent extraction, deployment configuration" "Python / FastAPI" "Service"
            ui = container "Streamlit UI" "Web interface for conversational requirements gathering, recommendation display, deployment management" "Python / Streamlit" "Frontend"
            postgres = container "PostgreSQL" "Persistent storage for benchmark performance data (TTFT, ITL, throughput)" "PostgreSQL 15" "Database"
            ollama = container "Ollama LLM" "Local LLM inference for conversational intent extraction" "Ollama / qwen2.5:7b" "Service"
            dbInit = container "db-init Job" "Schema initialization and benchmark data loading" "Python" "Job"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for GPU detection and InferenceService deployment" "External"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Benchmark data and model metadata synchronization" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Model configuration, parameter counts, safetensors metadata" "External"
        openaiAPI = softwareSystem "OpenAI API" "Alternative LLM provider for intent extraction" "External"
        vertexAI = softwareSystem "Vertex AI" "Alternative LLM provider (Claude on Google Cloud)" "External"
        kserve = softwareSystem "KServe" "Target for generated InferenceService deployment manifests" "Internal RHOAI"
        vllm = softwareSystem "vLLM" "ML serving runtime referenced in generated manifests" "Internal RHOAI"
        llmdStack = softwareSystem "llm-d Stack" "Alternative deployment target via kustomize/Helm" "Internal RHOAI"

        # User interactions
        user -> ui "Uses conversational planning UI" "HTTPS/443 (TLS edge)"
        user -> backend "Direct API access" "HTTPS/443 (TLS edge)"

        # UI to Backend
        ui -> backend "Proxies all API calls" "HTTP/8000"

        # Backend to data tier
        backend -> postgres "Stores and queries benchmark data" "PostgreSQL/5432"
        backend -> ollama "LLM inference for intent extraction" "HTTP/11434"

        # Backend to platform services
        backend -> k8sAPI "GPU detection, InferenceService deployment" "HTTPS/6443"
        backend -> modelCatalog "Sync benchmark data and model metadata" "HTTPS/8443"

        # Backend to external services
        backend -> hfHub "Fetch model configs, parameter counts" "HTTPS/443"
        backend -> openaiAPI "Alternative LLM inference" "HTTPS/443"
        backend -> vertexAI "Alternative LLM inference" "HTTPS/443"

        # Generated outputs
        backend -> kserve "Generates InferenceService manifests" "YAML"
        backend -> llmdStack "Generates kustomize overlays and Helm values" "YAML"

        # DB init
        dbInit -> postgres "Initializes schema and loads benchmark data" "PostgreSQL/5432"
    }

    views {
        systemContext llmdPlanner "SystemContext" {
            include *
            autoLayout
        }

        container llmdPlanner "Containers" {
            include *
            autoLayout
        }

        styles {
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Service" {
                shape RoundedBox
            }
            element "Frontend" {
                shape WebBrowser
            }
            element "Database" {
                shape Cylinder
            }
            element "Job" {
                shape Hexagon
            }
        }
    }
}
