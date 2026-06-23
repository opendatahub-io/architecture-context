workspace {
    model {
        dataScientist = person "Data Scientist" "Defines LLM deployment requirements and reviews GPU recommendations"
        platformEngineer = person "Platform Engineer" "Deploys and monitors LLM inference services on OpenShift"

        plannerSystem = softwareSystem "llm-d-planner" "LLM deployment planning service that translates business requirements into optimized GPU configurations and Kubernetes deployment manifests" {
            backendAPI = container "Backend API" "FastAPI REST API providing 27 endpoints for intent extraction, capacity planning, GPU recommendation, deployment YAML generation, and cluster management" "Python / FastAPI" "Service"
            streamlitUI = container "Streamlit UI" "Interactive web frontend for conversational requirement gathering, recommendation visualization, specification editing, and deployment monitoring" "Python / Streamlit" "WebApp"
            recommendationPipeline = container "Recommendation Pipeline" "Orchestrates intent extraction, specification generation, configuration finding, multi-criteria scoring, and deployment generation" "Python" "Component"
            clusterManager = container "Cluster Manager" "Manages GPU detection via node labels and InferenceService CRUD operations against Kubernetes API" "Python / kubernetes-client" "Component"
            catalogSync = container "Model Catalog Sync" "Background daemon thread that syncs validated models and performance benchmarks from RHOAI Model Catalog to local PostgreSQL" "Python" "Component"
            postgresDB = container "PostgreSQL Database" "Stores model performance benchmarks (TTFT, ITL, E2E latency at p95) used for SLO-driven configuration scoring" "PostgreSQL 16" "Database"
            vllmSimulator = container "vLLM Simulator" "GPU-free development server that replays benchmark data to simulate vLLM inference endpoints" "Python / FastAPI" "Service"
        }

        ollamaLLM = softwareSystem "Ollama" "Local LLM inference server (default provider, model: qwen2.5:7b)" "External"
        openAIAPI = softwareSystem "OpenAI-Compatible API" "Alternative LLM inference provider (OpenAI, vLLM, or custom endpoint)" "External"
        vertexAI = softwareSystem "Vertex AI" "Alternative LLM inference using Claude on Google Cloud" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model metadata, architecture, and configuration repository" "External"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Red Hat curated catalog of validated models with performance benchmarks" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform (InferenceService CRD)" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "OpenShift/Kubernetes cluster API for resource management" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection via generated ServiceMonitor CRs" "Internal RHOAI"
        grafana = softwareSystem "Grafana" "Dashboard visualization via generated ConfigMap dashboards" "Internal RHOAI"
        openshiftRoutes = softwareSystem "OpenShift Routes" "TLS edge-terminated external access" "Platform"
        nvidiaGPUOperator = softwareSystem "NVIDIA GPU Operator" "Provides GPU node labels (nvidia.com/gpu.product) for detection" "Platform"

        # User interactions
        dataScientist -> plannerSystem "Describes LLM deployment requirements via chat interface"
        platformEngineer -> plannerSystem "Reviews recommendations, deploys to cluster, monitors status"

        # Internal container relationships
        streamlitUI -> backendAPI "Forwards all API calls" "HTTP/8000"
        backendAPI -> recommendationPipeline "Delegates recommendation requests"
        backendAPI -> clusterManager "Delegates cluster operations"
        backendAPI -> postgresDB "Queries benchmarks, stores results" "TCP/5432"
        recommendationPipeline -> postgresDB "Queries SLO-compliant configurations" "TCP/5432"
        catalogSync -> postgresDB "Inserts synced benchmarks" "TCP/5432"

        # External dependencies
        recommendationPipeline -> ollamaLLM "Intent extraction via LLM" "HTTP/11434"
        recommendationPipeline -> openAIAPI "Alternative LLM inference" "HTTPS/443"
        recommendationPipeline -> vertexAI "Alternative LLM inference" "HTTPS/443"
        backendAPI -> huggingFace "Fetches model metadata and config" "HTTPS/443"
        catalogSync -> modelCatalog "Syncs validated models and benchmarks" "HTTPS/8443"
        clusterManager -> k8sAPI "GPU detection, InferenceService CRUD" "HTTPS/6443"

        # Platform integration
        plannerSystem -> kserve "Generates InferenceService YAML manifests"
        plannerSystem -> prometheus "Generates ServiceMonitor CRs for metrics scraping"
        plannerSystem -> grafana "Generates dashboard ConfigMaps with PromQL queries"
        openshiftRoutes -> streamlitUI "TLS edge termination" "HTTPS/443 -> HTTP/8501"
        openshiftRoutes -> backendAPI "TLS edge termination" "HTTPS/443 -> HTTP/8000"
        clusterManager -> nvidiaGPUOperator "Reads GPU node labels for detection"
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
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "WebApp" {
                background #4a90e2
                color #ffffff
                shape WebBrowser
            }
            element "Database" {
                background #336791
                color #ffffff
                shape Cylinder
            }
            element "Component" {
                background #dae8fc
                color #333333
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
