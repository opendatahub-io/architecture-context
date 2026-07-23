workspace {
    model {
        user = person "Data Scientist / Platform Engineer" "Plans and deploys LLM inference services on Kubernetes"

        llmdPlanner = softwareSystem "llm-d Planner" "LLM deployment planning platform — guides users from business requirements to production-ready Kubernetes deployments" {
            backendAPI = container "Backend API" "REST API for recommendations, capacity planning, GPU estimation, deployment, and database management" "Python / FastAPI" "Service"
            streamlitUI = container "Streamlit UI" "Chat-based web interface for interactive deployment planning, capacity analysis, and GPU comparison" "Python / Streamlit" "Frontend"
            capacityPlanner = container "Capacity Planner" "GPU memory estimation engine supporting MHA/GQA/MQA/MLA attention, quantization, and parallelism" "Python Library" "Library"
            gpuRecommender = container "GPU Recommender" "Performance estimation across GPU types using BentoML llm-optimizer roofline model" "Python Library" "Library"
            recommendationWorkflow = container "Recommendation Workflow" "End-to-end orchestration: intent extraction → traffic profiling → SLO targeting → config scoring → ranking" "Python Library" "Library"
            intentExtractor = container "Intent Extractor" "LLM-powered natural language understanding for deployment requirements" "Python Library" "Library"
            configGenerator = container "Configuration Generator" "Jinja2-based YAML generation for KServe InferenceService, HPA, ServiceMonitor, and llm-d stack" "Python Library" "Library"
            clusterManager = container "Cluster Manager" "Kubernetes deployment management via kubectl for InferenceService lifecycle" "Python Library" "Library"
            knowledgeBase = container "Knowledge Base" "Benchmark data loading, model catalog integration, SLO templates, and GPU catalog" "Python Library" "Library"
            vllmSimulator = container "vLLM Simulator" "GPU-free mock vLLM server with OpenAI-compatible API for local development" "Python / FastAPI" "DevTool"
        }

        postgres = softwareSystem "PostgreSQL 16" "Benchmark data storage and retrieval" "Database"
        ollama = softwareSystem "Ollama" "Local LLM inference server for intent extraction (default provider)" "Internal"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model metadata, safetensors API, parameter counts" "External"
        rhoaiModelCatalog = softwareSystem "RHOAI Model Catalog" "Benchmark data sourcing for RHOAI deployments" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster management, InferenceService lifecycle, GPU detection" "External"
        kserve = softwareSystem "KServe" "InferenceService CRD for model serving on target cluster" "Internal RHOAI"
        vllmRuntime = softwareSystem "vLLM Runtime" "LLM inference runtime for deployed InferenceService pods" "Internal RHOAI"
        llmdStack = softwareSystem "llm-d Stack" "Alternative deployment target using kustomize + Helm" "Internal RHOAI"
        vertexAI = softwareSystem "Vertex AI" "Optional LLM provider for intent extraction (Claude on GCP)" "External"
        openAICompat = softwareSystem "OpenAI-compatible API" "Optional LLM provider for intent extraction" "External"
        bentoML = softwareSystem "BentoML llm-optimizer" "Roofline performance estimation model" "External"
        openshiftServiceCA = softwareSystem "OpenShift service-CA" "CA bundle for Model Catalog TLS verification" "Internal RHOAI"

        # User relationships
        user -> llmdPlanner "Plans LLM deployments via chat interface"
        user -> streamlitUI "Interacts via browser" "HTTPS/443"

        # Internal container relationships
        streamlitUI -> backendAPI "Proxies all API calls" "HTTP/8000"
        backendAPI -> recommendationWorkflow "Orchestrates recommendation pipeline"
        recommendationWorkflow -> intentExtractor "Extracts structured intent from natural language"
        recommendationWorkflow -> knowledgeBase "Queries benchmark data and SLO templates"
        recommendationWorkflow -> capacityPlanner "Estimates GPU memory requirements"
        recommendationWorkflow -> gpuRecommender "Estimates inference performance"
        backendAPI -> configGenerator "Generates deployment YAML"
        backendAPI -> clusterManager "Manages Kubernetes deployments"

        # External dependencies
        backendAPI -> postgres "Stores and queries benchmark data" "PostgreSQL/5432"
        intentExtractor -> ollama "Default LLM inference for intent extraction" "HTTP/11434"
        backendAPI -> huggingfaceHub "Fetches model config and metadata" "HTTPS/443"
        knowledgeBase -> rhoaiModelCatalog "Sources benchmark data (optional)" "HTTPS/8443"
        clusterManager -> kubernetesAPI "Applies InferenceService manifests, detects GPUs" "HTTPS/6443"
        configGenerator -> kserve "Generates InferenceService CRD YAML"
        configGenerator -> llmdStack "Generates kustomize + Helm manifests"
        gpuRecommender -> bentoML "Uses roofline model for performance estimation" "In-process"
        intentExtractor -> vertexAI "Optional LLM provider" "HTTPS/443"
        intentExtractor -> openAICompat "Optional LLM provider" "HTTPS/443"
        backendAPI -> openshiftServiceCA "Mounts CA bundle for Model Catalog TLS"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #f5a623
                color #ffffff
            }
            element "Database" {
                background #4a90e2
                color #ffffff
                shape Cylinder
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Frontend" {
                background #50e3c2
                color #333333
            }
            element "Library" {
                background #b8e986
                color #333333
            }
            element "DevTool" {
                background #d8d8d8
                color #666666
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
