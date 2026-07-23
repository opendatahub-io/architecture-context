workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, manages workbenches and training jobs"
        mlEngineer = person "ML Engineer" "Deploys and monitors model serving, manages pipelines"
        aiAgent = person "AI Agent" "Claude Desktop, Claude Code, or any MCP-compatible client"

        rhoaiMcp = softwareSystem "RHOAI MCP Server" "MCP protocol server enabling AI agents to manage RHOAI platform resources programmatically" {
            mcpServer = container "MCP Server" "FastMCP-based protocol server exposing 50+ tools across 14 plugins" "Python / FastMCP"
            pluginManager = container "Plugin Manager" "Pluggy-based plugin lifecycle with CRD health checks and graceful degradation" "Python / pluggy"
            k8sClient = container "K8s Client" "Kubernetes API abstraction with impersonation and multi-auth" "Python / kubernetes"
            oidcMiddleware = container "OIDC Auth Middleware" "JWT/TokenReview multi-user auth with per-user tool RBAC filtering" "Python / ASGI"
            workflowTokens = container "Workflow Token System" "HMAC-SHA256 token chaining for multi-step tool call ordering" "Python"
            portForwardMgr = container "Port Forward Manager" "Manages kubectl port-forward subprocesses with reference counting" "Python / asyncio"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Cluster API for all resource CRUD, RBAC, TokenReview, impersonation" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (InferenceService, ServingRuntime CRDs)" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter workbench lifecycle management (Notebook CRDs)" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Distributed training job management (TrainJob CRDs)" "Internal RHOAI"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Pipeline server lifecycle (DSPA CRDs)" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry / Model Catalog" "Model metadata, versioning, artifacts, and curated catalog with benchmarks" "Internal RHOAI"
        plannerService = softwareSystem "Planner Service" "LLM recommendation engine and deployment config generation" "Internal RHOAI"
        openshiftApi = softwareSystem "OpenShift API" "Projects, Routes, Templates, ImageStreams" "External"
        oidcProvider = softwareSystem "OIDC Provider" "OpenShift OAuth or Keycloak for JWT/token validation" "External"
        dataScienceCluster = softwareSystem "DataScienceCluster" "Cluster status and installed component discovery" "Internal RHOAI"

        aiAgent -> rhoaiMcp "Sends MCP tool calls" "SSE/streamable-http/stdio"
        dataScientist -> aiAgent "Instructs AI agent to manage RHOAI resources"
        mlEngineer -> aiAgent "Instructs AI agent to deploy and monitor models"

        rhoaiMcp -> k8sApiServer "All CRD and resource CRUD, RBAC checks, impersonation" "HTTPS/6443"
        rhoaiMcp -> kserve "Manages InferenceService and ServingRuntime" "via K8s API CRDs"
        rhoaiMcp -> kubeflowNotebooks "Manages Notebook (workbench) lifecycle" "via K8s API CRDs"
        rhoaiMcp -> trainingOperator "Manages TrainJob and TrainingRuntime" "via K8s API CRDs"
        rhoaiMcp -> dspOperator "Manages pipeline server lifecycle" "via K8s API CRDs"
        rhoaiMcp -> modelRegistry "Lists models, versions, artifacts, benchmarks" "REST API v1alpha3 / HTTP 8080"
        rhoaiMcp -> plannerService "Gets LLM recommendations and deployment configs" "REST API / HTTP 8000"
        rhoaiMcp -> openshiftApi "Projects, Routes, Templates, ImageStreams" "HTTPS/6443"
        rhoaiMcp -> oidcProvider "JWKS discovery and JWT validation" "HTTPS/443"
        rhoaiMcp -> dataScienceCluster "Cluster status and installed components" "via K8s API CRDs"
    }

    views {
        systemContext rhoaiMcp "SystemContext" {
            include *
            autoLayout
        }

        container rhoaiMcp "Containers" {
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
                color #333333
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
