workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates ML projects, deploys models, runs training jobs via AI agent"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration and components"

        rhoaiMCP = softwareSystem "RHOAI MCP Server" "MCP protocol server exposing RHOAI platform operations as tools for AI agents" {
            mcpServer = container "FastMCP Server" "Handles MCP protocol (SSE/streamable-http/stdio) and request routing" "Python / FastMCP"
            pluginManager = container "Plugin Manager" "Loads and manages domain/composite plugins via pluggy hooks" "Python / pluggy"
            k8sClient = container "K8s Dynamic Client" "Kubernetes API abstraction with CRD caching and impersonation" "Python / kubernetes-python"
            authSystem = container "Auth System" "OIDC JWT / OCP TokenReview validation with per-tool RBAC filtering" "Python / PyJWT / ASGI middleware"

            mcpServer -> pluginManager "Routes tool calls to"
            mcpServer -> authSystem "Validates requests via"
            pluginManager -> k8sClient "Executes K8s operations via"
            authSystem -> k8sClient "SubjectAccessReview via"
        }

        aiAgent = softwareSystem "AI Agent" "Claude Desktop, Claude Code, or Lightspeed" "External"

        k8sAPIServer = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebook Controller" "Manages Jupyter workbench lifecycle via Notebook CRD" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference serving via InferenceService CRD" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines Operator" "ML pipeline infrastructure via DSPA CRD" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Distributed training job management via TrainJob CRD" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and artifacts" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Red Hat AI Model Catalog for model artifact resolution" "Internal RHOAI"
        plannerBackend = softwareSystem "Planner Backend" "Model recommendation engine via natural language intent" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for RHOAI platform (AcceleratorProfile, DSC)" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Token validation via TokenReview API" "External"
        oidcProvider = softwareSystem "OIDC Identity Provider" "JWT token issuance and JWKS for validation" "External"
        github = softwareSystem "GitHub" "Hosts rh-ai-quickstart repositories for template deployments" "External"

        # User interactions
        dataScientist -> aiAgent "Instructs agent to perform RHOAI operations"
        aiAgent -> rhoaiMCP "Invokes MCP tools via SSE/HTTP" "MCP Protocol 8000/TCP"

        # Internal integrations (all via K8s API)
        rhoaiMCP -> k8sAPIServer "CRUD operations on 19 API resource types" "HTTPS 6443/TCP TLS 1.2+"
        rhoaiMCP -> kubeflowNotebooks "Create/start/stop/delete workbenches" "via K8s API (Notebook CRD)"
        rhoaiMCP -> kserve "Deploy models, list runtimes, get endpoints" "via K8s API (InferenceService CRD)"
        rhoaiMCP -> dsPipelines "Create/manage pipeline infrastructure" "via K8s API (DSPA CRD)"
        rhoaiMCP -> trainingOperator "Create/monitor/suspend/resume training jobs" "via K8s API (TrainJob CRD)"
        rhoaiMCP -> rhoaiDashboard "Query platform component status, GPU profiles" "via K8s API (DSC, AcceleratorProfile CRDs)"

        # Direct REST API integrations
        rhoaiMCP -> modelRegistry "Query registered models, versions, artifacts" "REST API HTTP(S) 8080/8443"
        rhoaiMCP -> modelCatalog "Resolve model artifact URIs" "REST API HTTP(S) 8080/8443"
        rhoaiMCP -> plannerBackend "Model recommendations via NL intent" "REST API HTTP 8000/TCP"

        # Auth integrations
        rhoaiMCP -> openshiftOAuth "Validate OCP OAuth tokens" "TokenReview API HTTPS 6443/TCP"
        rhoaiMCP -> oidcProvider "Fetch JWKS for JWT validation" "HTTPS 443/TCP"

        # External integrations
        rhoaiMCP -> github "Clone quickstart repositories" "HTTPS 443/TCP"
    }

    views {
        systemContext rhoaiMCP "SystemContext" {
            include *
            autoLayout
        }

        container rhoaiMCP "Containers" {
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
        }
    }
}
