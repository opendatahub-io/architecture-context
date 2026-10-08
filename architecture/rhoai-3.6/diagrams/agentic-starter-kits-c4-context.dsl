workspace {
    model {
        datascientist = person "Data Scientist / Developer" "Builds and deploys AI agents using starter kit templates"
        sre = person "SRE / Platform Engineer" "Deploys and monitors agents on OpenShift"

        agenticStarterKits = softwareSystem "Agentic Starter Kits" "Production-ready starter kits for building AI agents on RHOAI across 12 frameworks" {
            agentAuth = container "agent-auth" "Shared ASGI middleware for ServiceAccount token authentication via Kubernetes TokenReview API" "Python Package"
            langGraphAgents = container "LangGraph Agents" "ReAct, RAG, DB Memory, CI Summarizer, HITL, Guardrailed agent templates" "Python / LangGraph"
            crewAIAgent = container "CrewAI Agent" "CrewAI-based agent with web search tool" "Python / CrewAI"
            llamaIndexAgent = container "LlamaIndex Agent" "LlamaIndex-based agent with web search tool" "Python / LlamaIndex"
            autoGenAgent = container "AutoGen MCP Agent" "AutoGen AssistantAgent with MCP tools over SSE" "Python / AutoGen"
            googleADKAgent = container "Google ADK Agent" "Google ADK 2.0 agent with LiteLLM routing" "Python / Google ADK"
            vanillaPythonAgent = container "Vanilla Python Agent" "Minimal agent using OpenAI Python client" "Python"
            a2aAgent = container "A2A Agent" "Multi-agent system using A2A protocol with LangGraph orchestrator and CrewAI worker" "Python / A2A"
            langflowAgent = container "Langflow Agent" "Visual flow-based agent with Langfuse tracing" "Python / Langflow"
            openClawDeploy = container "OpenClaw Deployment" "Kustomize-based deployment of OpenClaw gateway with vLLM backend" "Kustomize / Node.js upstream"
            evalHarness = container "Eval Harness" "Behavioral evaluation engine with runner, scorers, and MLflow client" "Python"
        }

        llmInference = softwareSystem "LLM Inference" "Model serving endpoint (OGX, vLLM, or Ollama)" "External"
        openShift = softwareSystem "OpenShift" "Container platform with Routes, RBAC, and service mesh" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and LLM tracing server" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for conversation memory and failure grouping" "External"
        milvus = softwareSystem "Milvus" "Vector database for RAG similarity search" "External"
        githubAPI = softwareSystem "GitHub API" "CI/CD data source for failure analysis" "External"
        slack = softwareSystem "Slack" "Team messaging for triage summary delivery" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for TokenReview authentication" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content safety filtering proxy" "External"

        datascientist -> agenticStarterKits "Uses templates to build and deploy AI agents"
        sre -> agenticStarterKits "Deploys via Helm charts and Kustomize manifests"

        agenticStarterKits -> llmInference "Sends inference requests" "HTTP/8321, API_KEY"
        agenticStarterKits -> openShift "Deployed on, uses Routes for TLS" "HTTPS/443"
        agenticStarterKits -> mlflow "Logs traces and experiments" "HTTPS/443, Bearer token"
        agenticStarterKits -> postgresql "Stores conversation memory and failure data" "TCP/5432, Password"
        agenticStarterKits -> milvus "Performs vector similarity search" "TCP/19530"
        agenticStarterKits -> githubAPI "Retrieves CI failure data" "HTTPS/443, GITHUB_TOKEN"
        agenticStarterKits -> slack "Posts triage summaries" "HTTPS/443, Webhook"
        agentAuth -> kubernetesAPI "Validates ServiceAccount tokens" "HTTPS/443, mTLS"
        langGraphAgents -> nemoGuardrails "Filters content for safety" "HTTP, proxy pattern"

        evalHarness -> agenticStarterKits "Tests deployed agents via HTTP" "HTTP/8080"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
