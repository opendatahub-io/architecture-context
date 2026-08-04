workspace {
    model {
        operator = person "Platform Operator" "Plans and deploys LLM workloads on Kubernetes"
        datascientist = person "Data Scientist" "Selects models and reviews deployment recommendations"

        llmdPlanner = softwareSystem "llm-d-planner" "Capacity planning and deployment recommendation service for LLM workloads" {
            ui = container "Streamlit UI" "Web-based user interface for LLM deployment planning" "Python/Streamlit" "Web Browser"
            backend = container "FastAPI Backend" "REST API for capacity planning, GPU estimation, model recommendations, and cluster deployment" "Python/FastAPI/uvicorn"
            gpuDetector = container "GPU Detector" "Reads NVIDIA GPU labels from cluster nodes with cached TTL" "Python module"
            postgres = container "PostgreSQL 16" "Stores benchmark data and deployment configurations" "PostgreSQL" "Database"
            ollama = container "Ollama Server" "Local LLM inference server for intent extraction" "Ollama" "LLM Runtime"
        }

        openshift = softwareSystem "OpenShift Platform" "Container orchestration platform" {
            routes = container "OpenShift Routes" "TLS edge termination for external access" "HAProxy"
            serviceCA = container "Service CA Operator" "Injects CA bundles for internal TLS trust" "OpenShift"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster resource management and node information" "External"
        openaiAPI = softwareSystem "OpenAI-compatible API" "External LLM inference service (configurable endpoint)" "External"
        vertexAI = softwareSystem "Google Vertex AI" "Alternative cloud LLM provider" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model metadata and artifact repository" "External"

        # User interactions
        operator -> llmdPlanner "Plans LLM deployments and reviews GPU recommendations"
        datascientist -> llmdPlanner "Explores model options and benchmarks"

        # Internal container relationships
        ui -> backend "REST API calls" "HTTP/8000"
        backend -> gpuDetector "GPU detection requests"
        backend -> postgres "Benchmark queries, deployment configs" "PostgreSQL/5432"
        backend -> ollama "LLM inference (local)" "HTTP/11434"

        # External relationships
        operator -> openshift "Accesses via browser"
        openshift -> llmdPlanner "Routes external traffic" "HTTPS/443 → HTTP"
        gpuDetector -> kubernetesAPI "List nodes with GPU labels" "HTTPS/6443"
        backend -> openaiAPI "LLM inference (structured output)" "HTTPS"
        backend -> vertexAI "LLM inference (alternative)" "HTTPS"
        backend -> huggingface "Model metadata lookup" "HTTPS"
        serviceCA -> backend "Injects CA bundle" "/etc/pki/service-ca"
    }

    views {
        systemContext llmdPlanner "SystemContext" {
            include *
            autoLayout
            description "System context showing llm-d-planner in its operational environment"
        }

        container llmdPlanner "Containers" {
            include *
            autoLayout
            description "Internal container structure of llm-d-planner"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape cylinder
                background #336791
                color #ffffff
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "LLM Runtime" {
                background #1a1a2e
                color #ffffff
            }
        }
    }
}
