workspace {
    model {
        user = person "Platform Engineer / Data Scientist" "Plans and deploys LLM models on Kubernetes clusters"

        llmDPlanner = softwareSystem "llm-d-planner" "LLM deployment planning service providing GPU capacity estimation, model recommendation, and deployment configuration" {
            backend = container "FastAPI Backend" "REST API server with 30 endpoints for capacity planning, GPU recommendation, deployment management, and database operations" "Python FastAPI, Port 8000"
            ui = container "Streamlit UI" "Interactive web UI for planning workflows" "Python Streamlit, Port 8501"
            postgres = container "PostgreSQL 16" "Stores benchmark and deployment data" "PostgreSQL, Port 5432"
            ollama = container "Ollama Server" "Local LLM inference server running Granite 3.3 2b on GPU" "Ollama, Port 11434, nvidia.com/gpu: 1"
            plannerCore = container "Planner Core" "Business logic for capacity planning, GPU recommendation, and model deployment" "Python"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for node detection and KServe deployments" "External"
        openAIAPI = softwareSystem "OpenAI-compatible API" "External LLM inference provider" "External"
        vertexAI = softwareSystem "Vertex AI" "Google Cloud LLM inference provider" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model metadata and artifact registry" "External"
        modelCatalog = softwareSystem "Model Catalog" "Benchmark data source" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (InferenceService CRDs)" "Internal Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "TLS edge termination for external access" "Internal Platform"
        serviceCA = softwareSystem "OpenShift Service CA" "CA bundle injection for internal TLS trust" "Internal Platform"

        # User interactions
        user -> ui "Accesses planning UI via browser" "HTTPS (via OpenShift Route)"
        user -> backend "Direct API calls" "HTTPS (via OpenShift Route)"

        # Internal component interactions
        ui -> backend "API requests" "HTTP/8000 (plaintext)"
        backend -> postgres "Benchmark and deployment data" "PostgreSQL/5432 (password auth)"
        backend -> ollama "Local LLM inference" "HTTP/11434 (plaintext)"
        backend -> plannerCore "Business logic" "In-process"

        # External integrations
        backend -> kubernetesAPI "List nodes (GPU detection), manage InferenceService CRs" "HTTPS/6443 (ServiceAccount token)"
        backend -> openAIAPI "LLM inference (configurable provider)" "HTTPS (API key)"
        backend -> vertexAI "LLM inference (configurable provider)" "HTTPS (GCP SA credentials)"
        backend -> huggingFaceHub "Fetch model metadata" "HTTPS (Bearer token)"
        backend -> modelCatalog "Fetch benchmark data" "HTTPS (Bearer token)"
        backend -> kserve "Create/manage InferenceService resources" "HTTPS/6443 (via Kubernetes API)"

        # Platform interactions
        openshiftRouter -> ui "Routes traffic" "HTTP/8501"
        openshiftRouter -> backend "Routes traffic" "HTTP/8000"
        serviceCA -> backend "Injects CA bundle at /etc/pki/service-ca" "ConfigMap volume mount"
    }

    views {
        systemContext llmDPlanner "SystemContext" {
            include *
            autoLayout
        }

        container llmDPlanner "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
