workspace {
    model {
        dataScientist = person "Data Scientist" "Plans and deploys LLM models with SLO targets"
        mlEngineer = person "ML Engineer" "Manages GPU capacity and model performance"

        llmDPlanner = softwareSystem "llm-d Planner" "SLO-driven capacity planning and deployment automation for LLM deployments on Kubernetes" {
            backendAPI = container "Backend API" "FastAPI REST API coordinating intent extraction, recommendation, configuration generation, and cluster management" "Python / FastAPI / Uvicorn" "Service"
            streamlitUI = container "Streamlit UI" "Conversational web interface with multi-tab workflow for requirements gathering, recommendations, deployment, and monitoring" "Python / Streamlit" "Frontend"
            intentEngine = container "Intent Extraction Engine" "LLM-powered natural language analysis converting user descriptions into structured DeploymentIntent schemas" "Python Module"
            recEngine = container "Recommendation Engine" "Multi-criteria scoring (accuracy 40%, price 40%, latency 10%, complexity 10%) with SLO-driven capacity planning" "Python Module"
            configGen = container "Configuration Generator" "YAML generation for KServe InferenceService, HPA, ServiceMonitor using Jinja2 templates" "Python / Jinja2"
            capPlanner = container "Capacity Planner" "GPU memory estimation (model weights, KV cache for MHA/GQA/MQA/MLA, activation, overhead)" "Python Module"
            gpuRecommender = container "GPU Recommender" "Roofline-based performance estimation (TTFT, ITL, throughput) across GPU types" "Python / BentoML llm-optimizer"
            knowledgeBase = container "Knowledge Base" "Hybrid data layer with PostgreSQL for benchmarks and JSON files for SLO templates" "Python / psycopg2"
            clusterMgr = container "Cluster Manager" "Kubernetes deployment lifecycle management via kubectl subprocess calls" "Python / kubectl"
            vllmSimulator = container "vLLM Simulator" "GPU-free mock vLLM service with OpenAI-compatible API and benchmark-driven latency simulation" "Python / FastAPI" "Development"
            dbInitJob = container "db-init Job" "Database schema initialization and benchmark data loading" "Python / Kubernetes Job"
            cli = container "CLI" "Command-line interface for capacity planning and GPU estimation" "Python / argparse"
        }

        postgresql = softwareSystem "PostgreSQL" "Benchmark data storage (16)" "Infrastructure"
        ollama = softwareSystem "Ollama" "Local LLM inference service (qwen2.5:7b or granite3.3:2b)" "Infrastructure"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model metadata, safetensors parameter counts, gated model access" "External"
        modelCatalog = softwareSystem "RHOAI Model Catalog" "Benchmark data synchronization, model artifact listing, performance metrics" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster management — deploy, status, delete InferenceServices" "Infrastructure"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform (target deployment)" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / Grafana" "Observability integration via generated ServiceMonitor manifests" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "TLS edge termination for external access (Routes)" "Infrastructure"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Service-serving CA bundle injection for internal HTTPS" "Infrastructure"

        # User interactions
        dataScientist -> llmDPlanner "Plans LLM deployments via browser UI"
        mlEngineer -> llmDPlanner "Estimates GPU capacity and manages deployments"

        # Internal container relationships
        streamlitUI -> backendAPI "All data operations, recommendations, deployments" "HTTP/8000"
        cli -> backendAPI "Capacity planning and GPU estimation" "HTTP/8000"
        backendAPI -> intentEngine "Delegates intent extraction"
        backendAPI -> recEngine "Delegates recommendation scoring"
        backendAPI -> configGen "Delegates YAML generation"
        backendAPI -> capPlanner "Delegates GPU memory estimation"
        backendAPI -> gpuRecommender "Delegates roofline estimation"
        backendAPI -> knowledgeBase "Reads benchmarks, SLO templates, model catalog"
        backendAPI -> clusterMgr "Delegates cluster operations"
        dbInitJob -> knowledgeBase "Loads schema and benchmark data"

        # External dependencies
        intentEngine -> ollama "LLM inference for intent extraction" "HTTP/11434"
        knowledgeBase -> postgresql "Benchmark data read/write" "PostgreSQL/5432"
        capPlanner -> huggingfaceHub "Model metadata, safetensors info" "HTTPS/443"
        knowledgeBase -> modelCatalog "Benchmark data synchronization" "HTTPS/8443"
        clusterMgr -> kubernetesAPI "Deploy/delete/list InferenceService CRs" "HTTPS/6443"
        configGen -> kserve "Generates InferenceService CRDs" "YAML output"
        backendAPI -> prometheus "Generates ServiceMonitor manifests" "YAML output"
        openshiftRouter -> streamlitUI "Routes external traffic" "HTTP/8501"
        openshiftRouter -> backendAPI "Routes external traffic" "HTTP/8000"
        openshiftServiceCA -> backendAPI "Injects CA bundle for Model Catalog TLS" "ConfigMap mount"
        dbInitJob -> postgresql "Schema init + benchmark loading" "PostgreSQL/5432"
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
                background #438dd5
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Service" {
                shape RoundedBox
            }
            element "Frontend" {
                shape WebBrowser
            }
            element "Development" {
                background #e1d5e7
                color #333333
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
