workspace {
    model {
        operator = person "Platform Operator" "Plans and deploys LLM workloads on Kubernetes clusters"

        llmDPlanner = softwareSystem "llm-d-planner" "Multi-component planning and recommendation service for LLM deployments on Kubernetes" {
            ui = container "Streamlit UI" "Interactive frontend for LLM deployment planning" "Python/Streamlit" "Web Browser"
            backend = container "FastAPI Backend" "REST API for capacity planning, GPU estimation, model recommendation, and deployment orchestration" "Python/FastAPI/uvicorn"
            ollama = container "Ollama" "Local LLM inference sidecar for intent extraction" "Go/Ollama"
            sqlite = container "SQLite Database" "Embedded database for benchmark data and deployment state" "SQLite on PVC" "Database"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster resource management and node information" "External"
        openAIAPI = softwareSystem "OpenAI-compatible API" "LLM inference via OpenAI SDK (vLLM, OpenAI, etc.)" "External"
        vertexAI = softwareSystem "Google Vertex AI" "LLM inference via GCP" "External"
        huggingFaceHub = softwareSystem "Hugging Face Hub" "Model catalog and artifact downloads" "External"
        openshiftRoutes = softwareSystem "OpenShift Routes" "TLS termination and external ingress" "Infrastructure"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Platform TLS certificate trust" "Infrastructure"

        # Relationships
        operator -> openshiftRoutes "Accesses via HTTPS"
        openshiftRoutes -> ui "Routes to UI" "HTTP/8501"
        openshiftRoutes -> backend "Routes to API" "HTTP/8000"
        ui -> backend "Sends planning requests" "HTTP/8000"
        backend -> ollama "Sends LLM inference requests" "HTTP/11434"
        backend -> sqlite "Reads/writes benchmark data"
        backend -> kubernetesAPI "Lists nodes for GPU detection" "HTTPS/6443"
        backend -> openAIAPI "Sends LLM inference requests" "HTTPS (OpenAI SDK)"
        backend -> vertexAI "Sends LLM inference requests" "HTTPS/443"
        backend -> huggingFaceHub "Queries model catalog" "HTTPS/443"
        openshiftServiceCA -> backend "Provides CA bundle" "Volume mount"
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
            element "Infrastructure" {
                background #7B68EE
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
            element "Database" {
                shape Cylinder
            }
            element "Web Browser" {
                shape WebBrowser
            }
        }
    }
}
