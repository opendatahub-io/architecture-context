workspace {
    model {
        user = person "Data Scientist" "Plans and deploys LLM models to production Kubernetes clusters"

        plannerSystem = softwareSystem "llm-d Planner" "Guides users from business requirements to production-ready LLM deployments through conversational AI, capacity planning, and SLO-driven recommendations" {
            backend = container "Backend Service" "FastAPI REST API implementing the recommendation pipeline, capacity planning, GPU estimation, and deployment automation" "Python/FastAPI" "Service"
            ui = container "UI Service" "Conversational web interface for requirements gathering, recommendation visualization, specification editing, and deployment monitoring" "Python/Streamlit" "WebApp"
            ollama = container "Ollama Sidecar" "Local LLM inference server running Granite 3.3 2B for intent extraction" "Ollama" "Service"
            database = container "SQLite Database" "Stores benchmark data, model performance metrics, and quality scores" "SQLite" "Database"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for node inspection and workload deployment" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService CRD" "External"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Model registry with benchmark data for RHOAI deployments" "Internal RHOAI"
        serviceCA = softwareSystem "OpenShift Service CA" "Certificate authority for internal service TLS trust" "Internal Platform"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model repository for architecture metadata and configuration lookups" "External"
        openaiAPI = softwareSystem "OpenAI API" "Optional LLM provider for intent extraction" "External"
        vertexAI = softwareSystem "Vertex AI" "Optional LLM provider for intent extraction via Claude" "External"
        arenaAPI = softwareSystem "Arena API" "Human preference quality rankings from lmarena.ai" "External"
        artificialAnalysis = softwareSystem "Artificial Analysis API" "Automated benchmark quality data" "External"

        user -> ui "Describes requirements and reviews recommendations via" "HTTPS/443"
        ui -> backend "Calls recommendation pipeline API" "HTTP/8000"
        backend -> ollama "Sends intent extraction requests" "HTTP/11434"
        backend -> database "Reads/writes benchmark and quality data" "File I/O"
        backend -> kubernetesAPI "Lists nodes for GPU detection, manages InferenceService deployments" "HTTPS/6443"
        backend -> kserve "Generates and manages InferenceService custom resources" "kubectl"
        backend -> modelCatalog "Fetches benchmark data for RHOAI models" "HTTPS/8443"
        backend -> huggingfaceHub "Looks up model architecture and configuration" "HTTPS/443"
        backend -> openaiAPI "Optional: LLM inference for intent extraction" "HTTPS/443"
        backend -> vertexAI "Optional: LLM inference via Claude" "HTTPS/443"
        backend -> arenaAPI "Downloads human preference quality rankings" "HTTPS/443"
        backend -> artificialAnalysis "Downloads automated benchmark quality data" "HTTPS/443"
        serviceCA -> backend "Injects CA bundle for internal TLS trust" "ConfigMap"
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
            element "Internal Platform" {
                background #50c878
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "WebApp" {
                background #50c878
                color #ffffff
            }
            element "Database" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
        }
    }
}
