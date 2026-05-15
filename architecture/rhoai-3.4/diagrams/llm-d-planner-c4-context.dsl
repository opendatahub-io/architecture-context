workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Plans and deploys LLM inference workloads on OpenShift"

        plannerSystem = softwareSystem "llm-d Planner" "Capacity planning and deployment recommendation service for LLM workloads" {
            backend = container "FastAPI Backend" "REST API server with 28 endpoints across 9 route modules. Implements intent extraction, recommendation generation, capacity planning, GPU estimation, YAML generation, and Kubernetes deployment." "Python 3.14, FastAPI, Uvicorn" {
                intentExtraction = component "Intent Extraction" "Converts natural language to structured DeploymentIntent via Ollama LLM" "Python module"
                recommendationEngine = component "Recommendation Engine" "Multi-criteria scoring (accuracy, price, latency, complexity) with 5 ranked views" "Python module"
                capacityPlanner = component "Capacity Planner" "Estimates GPU memory for MHA/GQA/MQA/MLA attention types" "Python module"
                gpuRecommender = component "GPU Recommender" "Roofline performance estimation via BentoML llm-optimizer" "Python module"
                yamlGenerator = component "YAML Generator" "Produces KServe InferenceService, HPA, ServiceMonitor YAML via Jinja2" "Python module"
                clusterManager = component "Cluster Manager" "GPU detection and InferenceService CRUD" "Python module"
                modelCatalogClient = component "Model Catalog Client" "Syncs model and benchmark data from RHOAI Model Catalog" "Python module"
            }
            ui = container "Streamlit UI" "Web interface with chat-based requirements gathering, capacity planner, GPU recommender, and deployment management pages" "Python 3.14, Streamlit"
            postgres = container "PostgreSQL 16" "Benchmark data storage, SLO-filtered queries, estimated performance caching" "PostgreSQL 16 (RHEL9)"
            ollama = container "Ollama" "Local LLM inference sidecar for conversational intent extraction" "Ollama, granite3.3:2b / qwen2.5:7b"
            simulator = container "vLLM Simulator" "OpenAI-compatible endpoints with benchmark-driven latency simulation for GPU-free development" "Python 3.14, FastAPI" "Optional"
        }

        huggingface = softwareSystem "HuggingFace Hub" "Model metadata, architecture config, tokenizer data" "External"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Model listings and performance metric artifacts" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes API" "Cluster node info, InferenceService lifecycle management" "Platform"
        kserve = softwareSystem "KServe" "Target deployment platform for generated InferenceService YAML" "Internal RHOAI"
        vllm = softwareSystem "vLLM" "Target inference runtime referenced in generated deployment YAML" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "TLS edge termination for external access" "Platform"

        # User interactions
        user -> plannerSystem "Submits business requirements, reviews recommendations, deploys models"
        user -> ui "Interacts via browser" "HTTPS/443"

        # External interactions
        ui -> backend "All API calls" "HTTP/8000"
        backend -> postgres "Benchmark queries, caching" "TCP/5432, Password auth"
        backend -> ollama "Intent extraction LLM calls" "HTTP/11434"
        backend -> huggingface "Model config and metadata" "HTTPS/443, Bearer Token"
        backend -> modelCatalog "Model listings and performance artifacts" "HTTPS/8443, Bearer Token, service-serving CA"
        backend -> k8sApi "GPU detection (list nodes), InferenceService CRUD" "HTTPS/6443, SA Token"
        plannerSystem -> kserve "Generates and applies InferenceService YAML"
        plannerSystem -> vllm "References as inference runtime in generated YAML"
        openshiftRouter -> ui "Route: planner" "HTTP/8501"
        openshiftRouter -> backend "Route: planner-backend" "HTTP/8000"
    }

    views {
        systemContext plannerSystem "SystemContext" {
            include *
            autoLayout
            description "System context showing llm-d Planner in the RHOAI ecosystem"
        }

        container plannerSystem "Containers" {
            include *
            autoLayout
            description "Container view showing internal services and data stores"
        }

        component backend "BackendComponents" {
            include *
            autoLayout
            description "Backend component view showing internal modules"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Optional" {
                background #cccccc
                color #333333
                border dashed
            }
        }
    }
}
