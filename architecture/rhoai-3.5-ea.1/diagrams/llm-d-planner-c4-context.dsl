workspace {
    model {
        datascientist = person "Data Scientist" "Defines business requirements for LLM deployments, reviews recommendations, and deploys models"
        mlops = person "MLOps Engineer" "Uses CLI for capacity planning and GPU estimation, manages deployments"

        llmdplanner = softwareSystem "llm-d Planner" "LLM deployment planning platform that converts business requirements into GPU-optimized KServe deployments" {
            ui = container "Streamlit UI" "Multi-tab guided workflow for requirements gathering, SLO configuration, recommendation review, and deployment" "Python Streamlit" "Web Browser"
            backend = container "Backend API" "REST API for intent extraction, capacity planning, GPU estimation, recommendations, and deployment management" "Python FastAPI"
            cli = container "CLI" "Command-line interface for capacity planning and GPU estimation" "Python Click"
            intentExtractor = container "Intent Extractor" "Converts natural-language requirements into structured specifications using LLM" "Python Module"
            capacityPlanner = container "Capacity Planner" "Calculates GPU memory requirements (weights, KV cache, activation memory)" "Python Module"
            gpuRecommender = container "GPU Recommender" "Estimates inference performance via roofline modeling (BentoML llm-optimizer)" "Python Module"
            recommendationEngine = container "Recommendation Engine" "Multi-criteria scoring (accuracy, price, latency, complexity) with ranked lists" "Python Module"
            configGenerator = container "Configuration Generator" "Jinja2-based YAML generation for KServe InferenceService, HPA, ServiceMonitor" "Python Module"
            clusterManager = container "Cluster Manager" "Kubernetes cluster interaction for deployment, status queries, GPU discovery" "Python Module"
            knowledgeBase = container "Knowledge Base" "Benchmark repository, Model Catalog client, SLO templates, GPU catalog" "Python Module"
        }

        postgresql = softwareSystem "PostgreSQL 16" "Stores benchmark performance data (exported_summaries) for model/GPU/workload configurations" "Database"
        ollama = softwareSystem "Ollama" "Local LLM inference service for natural-language intent extraction (granite3.3:2b)" "Internal"
        huggingface = softwareSystem "HuggingFace Hub" "Model architecture metadata, safetensors information, model configurations" "External"
        k8sapi = softwareSystem "Kubernetes API" "Cluster management: deployment of InferenceServices, node listing for GPU discovery" "External"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Red Hat AI validated models benchmark data (optional sync source)" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Target inference serving platform - InferenceService CRDs are generated and deployed" "Internal RHOAI"
        vllm = softwareSystem "vLLM" "Target serving runtime used in generated InferenceService deployments" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via generated ServiceMonitor resources" "Internal"
        grafana = softwareSystem "Grafana" "Dashboard visualization via generated ConfigMap dashboards" "Internal"

        # User interactions
        datascientist -> llmdplanner "Defines business requirements via guided UI workflow" "HTTPS/443"
        mlops -> llmdplanner "Runs capacity planning and GPU estimation" "HTTP/8000 (CLI)"

        # UI to Backend
        ui -> backend "All API calls (extraction, recommendations, deployment)" "HTTP/8000"

        # CLI to Backend
        cli -> backend "Capacity planning and estimation commands" "HTTP/8000"

        # Backend internal
        backend -> intentExtractor "Extract intent from natural language"
        backend -> capacityPlanner "Calculate GPU memory requirements"
        backend -> gpuRecommender "Estimate GPU performance"
        backend -> recommendationEngine "Score and rank configurations"
        backend -> configGenerator "Generate KServe YAML manifests"
        backend -> clusterManager "Deploy to Kubernetes"
        backend -> knowledgeBase "Query benchmarks and metadata"

        # Backend to external systems
        intentExtractor -> ollama "LLM intent extraction" "HTTP/11434"
        knowledgeBase -> postgresql "Benchmark data queries and storage" "PostgreSQL/5432"
        recommendationEngine -> postgresql "Benchmark scoring data" "PostgreSQL/5432"
        capacityPlanner -> huggingface "Model architecture metadata" "HTTPS/443"
        gpuRecommender -> huggingface "Model configuration" "HTTPS/443"
        clusterManager -> k8sapi "Deploy InferenceService, discover GPUs" "HTTPS/6443"
        knowledgeBase -> modelCatalog "Optional benchmark data sync" "HTTPS/8443"

        # Generated artifacts
        configGenerator -> kserve "Generates InferenceService + HPA CRDs" "YAML"
        configGenerator -> prometheus "Generates ServiceMonitor CRDs" "YAML"
        configGenerator -> grafana "Generates Dashboard ConfigMaps" "YAML"
    }

    views {
        systemContext llmdplanner "SystemContext" {
            include *
            autoLayout
        }

        container llmdplanner "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Internal RHOAI" {
                background #ee0000
                color #ffffff
            }
            element "Database" {
                background #336791
                color #ffffff
                shape Cylinder
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
