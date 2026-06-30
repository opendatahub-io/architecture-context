workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Plans and deploys LLM models on Kubernetes"

        llmDPlanner = softwareSystem "llm-d Planner" "AI-powered capacity planning and deployment automation for LLM deployments on Kubernetes" {
            backend = container "FastAPI Backend" "REST API orchestrating planning workflow: intent extraction, recommendation, capacity planning, GPU estimation, deployment" "Python 3.14 / FastAPI / Uvicorn" "Service"
            ui = container "Streamlit UI" "Conversational web interface for requirement gathering, recommendation visualization, deployment management" "Python 3.14 / Streamlit" "WebApp"
            postgres = container "PostgreSQL" "Stores performance benchmarks (TTFT, ITL, E2E, throughput) for model+GPU+traffic profile combinations" "PostgreSQL" "Database"
            ollama = container "Ollama" "Local LLM service for intent extraction from natural language (default provider)" "Ollama" "Service"
            dbInit = container "db-init Job" "Initializes database schema and loads benchmark data on first deployment" "Python / Shell" "Job"
        }

        # Internal RHOAI Dependencies
        modelCatalog = softwareSystem "Model Catalog API" "RHOAI model and benchmark data registry (rhoai-model-registries namespace)" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Kubernetes-native serverless inference platform; Planner creates InferenceService CRs" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing TLS edge termination via Routes" "Internal Platform"
        serviceCaOperator = softwareSystem "OpenShift service-ca Operator" "Injects service-serving CA bundle ConfigMaps for internal TLS" "Internal Platform"

        # External Dependencies
        huggingFace = softwareSystem "HuggingFace Hub" "Model architecture metadata, parameter counts, safetensors indexes" "External"
        vertexAI = softwareSystem "Vertex AI / Anthropic" "Cloud LLM provider for intent extraction (alternative to Ollama)" "External"
        openAI = softwareSystem "OpenAI-compatible API" "LLM provider for intent extraction (alternative to Ollama)" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster GPU detection, InferenceService lifecycle management" "External"

        # User interactions
        user -> llmDPlanner "Describes LLM deployment requirements in natural language"
        user -> ui "Interacts via browser (HTTPS/443 via OpenShift Route)"

        # Internal container relationships
        ui -> backend "All API calls" "HTTP/8000"
        backend -> postgres "Benchmark queries and inserts" "PostgreSQL/5432 Password"
        backend -> ollama "LLM intent extraction" "HTTP/11434"
        dbInit -> postgres "Schema init and data load" "PostgreSQL/5432"

        # External relationships
        backend -> huggingFace "Model metadata retrieval" "HTTPS/443 Bearer Token (optional)"
        backend -> vertexAI "LLM intent extraction (vertex provider)" "HTTPS/443 GCP ADC"
        backend -> openAI "LLM intent extraction (openai provider)" "HTTPS/443 API Key"
        backend -> k8sAPI "GPU detection, InferenceService CRUD" "HTTPS/6443 SA Token"
        backend -> modelCatalog "Model and benchmark sync" "HTTPS/8443 SA Bearer Token"
        backend -> kserve "Creates InferenceService CRs" "HTTPS/6443 SA Token"

        # Platform relationships
        openshiftRouter -> ui "Routes external traffic" "HTTP/8501"
        openshiftRouter -> backend "Routes external traffic" "HTTP/8000"
        serviceCaOperator -> llmDPlanner "Injects CA bundle ConfigMap" "Annotation-based"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Service" {
                shape RoundedBox
            }
            element "WebApp" {
                shape WebBrowser
            }
            element "Database" {
                shape Cylinder
            }
            element "Job" {
                shape Hexagon
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
