workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Describes AI use case and deploys LLM models"
        admin = person "Platform Admin" "Manages benchmark data and system configuration"

        plannerSystem = softwareSystem "llm-d-planner" "SLO-driven deployment planning tool for LLM models on Kubernetes" {
            backend = container "FastAPI Backend" "Core API providing deployment planning pipeline, benchmark access, LLM integration, Kubernetes deployment management" "Python FastAPI" {
                intentExtractor = component "Intent Extractor" "Extracts structured deployment intent from natural language via LLM" "Python"
                specGenerator = component "Specification Generator" "Transforms intent into technical SLO specifications" "Python"
                recommendationEngine = component "Recommendation Engine" "Scores and ranks model+GPU configurations across quality/price/latency" "Python"
                deploymentGenerator = component "Deployment Generator" "Renders KServe/vLLM Kubernetes YAML via Jinja2 templates" "Python"
                gpuDetector = component "GPU Detector" "Auto-detects GPU types from cluster node labels" "Python"
                qualityScoring = component "Quality Scoring" "Composites Arena + Artificial Analysis data into percentile-normalized quality scores" "Python"
                benchmarkDB = component "Benchmark Database" "SQLite database storing model performance benchmark data" "SQLite"
            }
            ui = container "Streamlit UI" "Conversational web frontend for requirement gathering, visualization, and deployment monitoring" "Python Streamlit"
            ollama = container "Ollama Sidecar" "Local LLM inference for intent extraction using granite3.3:2b model" "Ollama"
            simulator = container "vLLM Simulator" "GPU-free development tool simulating vLLM inference responses" "Python FastAPI"
            cli = container "Planner CLI" "Command-line interface for capacity planning, GPU recommendation, and deployment" "Python CLI"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster resource management and GPU detection" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (InferenceService CRD target)" "Internal RHOAI"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Model metadata and benchmark data source" "Internal RHOAI"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "TLS certificate trust for internal service communication" "Internal Platform"
        hfHub = softwareSystem "HuggingFace Hub" "Model configuration and architecture lookups" "External"
        openaiAPI = softwareSystem "OpenAI-compatible API" "LLM inference provider (optional)" "External"
        vertexAI = softwareSystem "Vertex AI (Anthropic)" "Claude LLM inference provider (optional)" "External"
        arenaAPI = softwareSystem "LMSYS Chatbot Arena" "Human preference model quality rankings" "External"
        aaAPI = softwareSystem "Artificial Analysis" "Automated model benchmark data" "External"

        # User interactions
        user -> plannerSystem "Describes use case, reviews recommendations, deploys models" "HTTPS/443"
        admin -> plannerSystem "Uploads benchmarks, manages database" "HTTPS/443"

        # UI interactions
        user -> ui "Conversational requirement gathering" "HTTPS/443 (via Route)"
        ui -> backend "API calls for planning pipeline" "HTTPS/443 (via Route)"

        # CLI interactions
        user -> cli "Command-line planning and deployment" "Local"
        cli -> backend "API calls" "HTTP/8000"

        # Backend dependencies
        backend -> ollama "Intent extraction" "HTTP/11434"
        backend -> openaiAPI "LLM inference (optional)" "HTTPS/443"
        backend -> vertexAI "Claude inference (optional)" "HTTPS/443"
        backend -> k8sAPI "GPU detection, deployment lifecycle" "HTTPS/6443"
        backend -> modelCatalog "Benchmark data sync" "HTTPS/8443"
        backend -> hfHub "Model config lookups" "HTTPS/443"
        backend -> arenaAPI "Quality data (human preferences)" "HTTPS/443"
        backend -> aaAPI "Quality data (automated benchmarks)" "HTTPS/443"

        # Deployment target
        backend -> kserve "Generates and deploys InferenceService YAML" "kubectl"

        # Platform trust
        backend -> openshiftServiceCA "CA bundle for Model Catalog TLS" "ConfigMap"
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

        component backend "BackendComponents" {
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
