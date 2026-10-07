workspace {
    model {
        datascientist = person "Data Scientist / Developer" "Builds and deploys AI agents using starter kits"
        externalclient = person "External Client" "Sends chat completion requests to deployed agents"

        agenticStarterKits = softwareSystem "Agentic Starter Kits" "Production-ready agent templates for Red Hat OpenShift AI" {
            sharedHelmChart = container "Shared Helm Chart" "Deployment, Service, Route, Secret, ServiceAccount resources" "Helm"
            agentAuth = container "agent-auth" "ASGI middleware for K8s ServiceAccount token authentication via TokenReview API" "Python"
            tracingModule = container "Tracing Module" "MLflow integration for experiment tracking (opt-in)" "Python"
            testHarness = container "Behavioral Test Harness" "pytest-based eval engine with scorers and MLflow client" "Python"

            langGraphReact = container "LangGraph ReAct Agent" "General-purpose ReAct loop agent with tool calling" "Python/FastAPI" "Agent Template"
            langGraphRAG = container "LangGraph Agentic RAG" "RAG agent with Milvus vector store retrieval" "Python/FastAPI" "Agent Template"
            langGraphDBMemory = container "LangGraph DB Memory Agent" "ReAct agent with PostgreSQL-backed conversation memory" "Python/FastAPI" "Agent Template"
            langGraphHITL = container "LangGraph Human-in-the-Loop" "ReAct agent with human approval step" "Python/FastAPI" "Agent Template"
            crewAIAgent = container "CrewAI Websearch Agent" "CrewAI-based web search agent" "Python/FastAPI" "Agent Template"
            llamaIndexAgent = container "LlamaIndex Websearch Agent" "LlamaIndex web search agent" "Python/FastAPI" "Agent Template"
            autoGenAgent = container "AutoGen MCP Agent" "AutoGen AssistantAgent with MCP tools over SSE" "Python/FastAPI" "Agent Template"
            googleADKAgent = container "Google ADK Agent" "Google ADK 2.0 agent with LiteLLM routing" "Python/FastAPI" "Agent Template"
            a2aAgent = container "A2A LangGraph+CrewAI Agent" "Multi-agent A2A protocol orchestrator" "Python/FastAPI" "Agent Template"
            vanillaPythonAgent = container "Vanilla Python Agent" "Minimal agent using OpenAI Python client" "Python/FastAPI" "Agent Template"

            ciFailureSummarizer = container "CI Failure Summarizer" "CI failure ingestion, incident grouping, Slack triage" "Python/FastAPI" "Example"
            guardrailedAgent = container "Guardrailed Banking Agent" "Banking agent with NeMo Guardrails safety proxy" "Python/FastAPI" "Example"

            openClaw = container "OpenClaw Gateway" "AI coding assistant gateway backed by vLLM" "Node.js" "Non-Standard Deployment"
        }

        openShift = softwareSystem "OpenShift Platform" "Container orchestration platform" "External"
        ogxVLLM = softwareSystem "OGX / vLLM / Ollama" "LLM model serving backends" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and agent tracing server" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for TokenReview" "External"
        milvus = softwareSystem "Milvus" "Vector database for document retrieval" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for conversation memory" "External"
        slackAPI = softwareSystem "Slack API" "Messaging platform for CI triage notifications" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content safety filtering proxy" "External"

        datascientist -> agenticStarterKits "Deploys agents using Helm chart"
        externalclient -> agenticStarterKits "POST /chat/completions via HTTPS/443"

        agenticStarterKits -> ogxVLLM "LLM inference requests" "HTTP/HTTPS, API_KEY"
        agenticStarterKits -> k8sAPI "TokenReview for SA auth" "HTTPS/443"
        agenticStarterKits -> mlflow "Experiment tracing" "HTTP/HTTPS, Bearer token"
        agenticStarterKits -> milvus "Vector retrieval" "HTTP"
        agenticStarterKits -> postgresql "Conversation memory" "TCP/5432"
        agenticStarterKits -> slackAPI "CI triage notifications" "HTTPS/443"
        agenticStarterKits -> nemoGuardrails "Content filtering" "HTTP/HTTPS"
        agenticStarterKits -> openShift "Deployed on" "Route, Service, Deployment"

        agentAuth -> k8sAPI "TokenReview API" "HTTPS/443"
        tracingModule -> mlflow "Log traces" "HTTP/HTTPS"
        langGraphRAG -> milvus "Vector retrieval" "HTTP"
        langGraphDBMemory -> postgresql "Conversation memory" "TCP/5432"
        ciFailureSummarizer -> slackAPI "Triage notifications" "HTTPS/443"
        guardrailedAgent -> nemoGuardrails "Safety filtering" "HTTP/HTTPS"
        openClaw -> ogxVLLM "Inference" "HTTP/HTTPS, VLLM_API_KEY"
    }

    views {
        systemContext agenticStarterKits "SystemContext" {
            include *
            autoLayout
        }

        container agenticStarterKits "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Agent Template" {
                background #4a90e2
                color #ffffff
            }
            element "Example" {
                background #7ed321
                color #ffffff
            }
            element "Non-Standard Deployment" {
                background #e8e8e8
                color #333333
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
