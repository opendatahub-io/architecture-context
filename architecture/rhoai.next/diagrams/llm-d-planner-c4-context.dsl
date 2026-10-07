workspace {
    model {
        user = person "User / Data Scientist" "Plans and deploys LLM inference services via conversational AI interface"

        plannerSystem = softwareSystem "llm-d-planner" "End-to-end LLM deployment planning platform with conversational AI, SLO-driven capacity planning, and GPU recommendation" {
            ui = container "Streamlit UI" "Conversational chat interface with multi-tab recommendation display, specification editor, and deployment monitoring" "Python / Streamlit" "Web App"
            backend = container "FastAPI Backend" "REST API hosting planning engines: intent extraction, specification, recommendation, configuration, cluster management, and Knowledge Base" "Python / FastAPI" "Service"
            sqlite = container "SQLite Database" "Benchmark data, deployment records, quality scoring cache" "SQLite on PVC" "Database"
        }

        ollama = softwareSystem "Ollama" "Local LLM inference service for intent extraction" "External"
        openaiApi = softwareSystem "OpenAI API" "Cloud LLM inference provider (alternative)" "External"
        vertexAi = softwareSystem "Vertex AI" "Google Cloud LLM inference provider (alternative)" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster management and GPU detection" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (deployment target)" "Internal RHOAI"
        hfHub = softwareSystem "HuggingFace Hub" "Model metadata and architecture configurations" "External"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Benchmark data source for RHOAI models" "Internal RHOAI"
        arenaApi = softwareSystem "Arena API" "Model quality human preference rankings (lmarena.ai)" "External"
        aaApi = softwareSystem "Artificial Analysis API" "Model quality automated benchmarks" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "TLS trust chain for internal service connections" "Internal RHOAI"

        # Relationships - User
        user -> plannerSystem "Plans LLM deployments via conversational UI"
        user -> ui "Describes use case in natural language" "HTTPS/443 (via Route)"

        # Relationships - Internal
        ui -> backend "Forwards planning requests" "HTTP/8000"
        backend -> sqlite "Reads/writes benchmark data" "File I/O"

        # Relationships - LLM Providers
        backend -> ollama "Extracts intent from natural language" "HTTP/11434"
        backend -> openaiApi "LLM inference (alternative)" "HTTPS/443 (API Key)"
        backend -> vertexAi "LLM inference (alternative)" "HTTPS/443"

        # Relationships - Data Sources
        backend -> hfHub "Fetches model metadata" "HTTPS/443 (Token optional)"
        backend -> arenaApi "Fetches quality rankings" "HTTPS/443"
        backend -> aaApi "Fetches quality benchmarks" "HTTPS/443 (API Key)"
        backend -> modelCatalog "Fetches benchmark data" "HTTPS/8443 (Bearer Token)"

        # Relationships - Platform
        backend -> k8sApi "Detects GPUs, deploys InferenceServices" "HTTPS/6443 (SA Token)"
        backend -> kserve "Generates InferenceService YAML" "Generated CRs"
        backend -> openshiftServiceCA "Uses CA bundle for TLS trust" "ConfigMap injection"
    }

    views {
        systemContext plannerSystem "SystemContext" {
            include *
            autoLayout
        }

        container plannerSystem "Containers" {
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
            element "Web App" {
                shape WebBrowser
            }
            element "Database" {
                shape Cylinder
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
