workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Plans and deploys LLM models on RHOAI"

        plannerSystem = softwareSystem "llm-d-planner" "LLM deployment planning service that recommends optimal model/GPU configurations based on use-case requirements, SLO targets, and benchmark data" {
            backendApi = container "Backend API" "REST API for deployment recommendations, capacity planning, GPU estimation, configuration generation, and cluster management" "Python FastAPI, Port 8000"
            streamlitUi = container "Streamlit UI" "Interactive web UI for conversational deployment planning, capacity planner, and GPU recommender" "Python Streamlit, Port 8501"
            vllmSimulator = container "vLLM Simulator" "Mock vLLM-compatible OpenAI API for GPU-free development and testing" "Python FastAPI, Port 8080"
            recommendationEngine = container "Recommendation Engine" "Multi-criteria scoring (accuracy, price, latency, complexity) and ranking" "Python Library"
            intentExtractor = container "Intent Extractor" "LLM-powered natural language intent extraction for deployment requirements" "Python Library"
            configGenerator = container "Configuration Generator" "Generates KServe InferenceService YAML, HPA, ServiceMonitor, and llm-d kustomize overlays" "Python Jinja2"
            capacityPlanner = container "Capacity Planner" "GPU memory calculator using HuggingFace model metadata" "Python Library"
            gpuRecommender = container "GPU Recommender" "Roofline model-based GPU performance estimator via BentoML llm-optimizer" "Python Library"
            knowledgeBase = container "Knowledge Base" "PostgreSQL benchmark repository, Model Catalog client, SLO templates, quality scorer" "Python Library"
            clusterManager = container "Cluster Manager" "Kubernetes cluster integration for GPU detection, namespace management, InferenceService deployment" "Python Library"
        }

        # Internal Platform Dependencies
        postgresql = softwareSystem "PostgreSQL" "Benchmark data storage (exported_summaries table)" "Internal"
        ollama = softwareSystem "Ollama" "In-cluster LLM server for intent extraction" "Internal"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Validated model benchmark data from RHOAI platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform — target for generated InferenceService CRs" "Internal RHOAI"
        llmdScheduler = softwareSystem "llm-d Inference Scheduler" "Target for generated kustomize overlays and Helm values" "Internal RHOAI"
        openshiftRoutes = softwareSystem "OpenShift Routes" "External HTTPS ingress via edge-terminated TLS Routes" "Internal Platform"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Automatic CA bundle injection for TLS verification" "Internal Platform"
        prometheusGrafana = softwareSystem "Prometheus / Grafana" "Monitoring stack — target for generated ServiceMonitor and dashboard ConfigMap" "Internal Platform"

        # External Dependencies
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model metadata API (architecture, parameters, safetensors)" "External"
        openaiApi = softwareSystem "OpenAI API" "Alternative LLM provider for intent extraction" "External"
        vertexAi = softwareSystem "Vertex AI (Anthropic)" "Alternative LLM provider for intent extraction" "External"
        kubernetesApi = softwareSystem "Kubernetes API" "Cluster API for GPU detection and InferenceService CRUD" "External"

        # Relationships — User
        user -> plannerSystem "Plans and deploys LLM models via web UI and API"
        user -> streamlitUi "Describes deployment needs in natural language" "HTTPS/443 via OpenShift Route"

        # Relationships — Internal containers
        streamlitUi -> backendApi "All planner API calls" "HTTP/8000"
        backendApi -> intentExtractor "Extract intent from user input"
        backendApi -> recommendationEngine "Score and rank configurations"
        backendApi -> capacityPlanner "Calculate GPU memory requirements"
        backendApi -> gpuRecommender "Estimate GPU performance via roofline"
        backendApi -> configGenerator "Generate deployment YAML"
        backendApi -> knowledgeBase "Query benchmarks and SLO templates"
        backendApi -> clusterManager "Detect GPUs, deploy InferenceServices"

        # Relationships — Internal platform
        knowledgeBase -> postgresql "Benchmark data CRUD" "PostgreSQL/5432"
        intentExtractor -> ollama "LLM chat completion" "HTTP/11434"
        knowledgeBase -> modelCatalog "Sync validated benchmark data" "HTTPS/8443"
        clusterManager -> kubernetesApi "GPU detection, InferenceService CRUD" "HTTPS/6443"
        configGenerator -> kserve "Generates InferenceService CRs" "serving.kserve.io/v1beta1"
        configGenerator -> llmdScheduler "Generates kustomize overlays and Helm values"
        configGenerator -> prometheusGrafana "Generates ServiceMonitor and Grafana dashboard"

        # Relationships — External APIs
        intentExtractor -> openaiApi "Alternative LLM provider" "HTTPS/443"
        intentExtractor -> vertexAi "Alternative LLM provider" "HTTPS/443"
        capacityPlanner -> huggingfaceHub "Model metadata retrieval" "HTTPS/443"

        # Platform relationships
        openshiftRoutes -> streamlitUi "TLS edge termination" "HTTP/8501"
        openshiftRoutes -> backendApi "TLS edge termination" "HTTP/8000"
        openshiftServiceCA -> plannerSystem "CA bundle injection for Model Catalog TLS"
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
            element "Internal" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #e17055
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape roundedBox
            }
            element "Container" {
                shape roundedBox
            }
        }
    }
}
