workspace {
    model {
        agent = person "AI Agent" "Claude Code, Codex, OpenCode, or Pi agent interacting with RHOAI platform"

        rhoaiMcp = softwareSystem "rhoai-mcp" "MCP server enabling AI agents to programmatically manage RHOAI environments" {
            transport = container "uvicorn ASGI Server" "Hosts MCP transport layer (SSE, streamable-http)" "Python / uvicorn"
            oidcAuth = container "OIDC Auth Middleware" "Pure ASGI middleware for Bearer token validation via JWT/JWKS or TokenReview" "Python / PyJWT"
            rbacChecker = container "RBAC Checker" "SubjectAccessReview-based tool filtering per user" "Python / kubernetes-client"
            mcpServer = container "FastMCP Server" "Tool, resource, and prompt registration; MCP protocol handling" "Python / mcp SDK"
            pluginManager = container "Plugin Manager" "Pluggy-based domain and composite plugin lifecycle" "Python / pluggy"
            k8sClient = container "K8sClient" "Kubernetes API abstraction with impersonation and user-token support" "Python / kubernetes-client"
            workflowTokens = container "Workflow Token System" "HMAC-SHA256 signed stateless tokens for multi-step operation chaining" "Python / hmac"

            domainProjects = container "Projects Domain" "Namespace CRUD and project management" "Python"
            domainNotebooks = container "Notebooks Domain" "Jupyter workbench lifecycle management" "Python"
            domainInference = container "Inference Domain" "InferenceService and ServingRuntime management" "Python"
            domainConnections = container "Connections Domain" "Secret-based connection management" "Python"
            domainStorage = container "Storage Domain" "PVC and storage management" "Python"
            domainPipelines = container "Pipelines Domain" "Data Science Pipeline infrastructure management" "Python"
            domainTraining = container "Training Domain" "Training job and runtime management" "Python"
            domainModelRegistry = container "Model Registry Domain" "REST client for Model Registry API" "Python / httpx"

            compositeExplorer = container "Cluster Explorer" "Cross-domain cluster discovery composite" "Python"
            compositeTraining = container "Training Orchestrator" "Multi-domain training preparation composite" "Python"
            compositePlanner = container "Inference Planner" "GPU/resource planning composite" "Python / llm-d-planner"
            compositeDiagnostics = container "Resource Diagnostics" "Cross-cutting resource analysis composite" "Python"
        }

        k8sApi = softwareSystem "Kubernetes API" "OpenShift/Kubernetes API server for all cluster resource operations" "External"
        modelRegistry = softwareSystem "Model Registry" "RHOAI Model Registry for model metadata and versioning" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Benchmark data and model catalog service" "Internal RHOAI"
        llmdPlanner = softwareSystem "llm-d Planner" "GPU/resource planning backend service" "Internal RHOAI"

        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter workbench CRD controller" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform (InferenceService, ServingRuntime)" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Training job CRD controller" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "Pipeline infrastructure (DSPA)" "Internal RHOAI"
        mcpOperator = softwareSystem "MCP Lifecycle Operator" "Operator managing rhoai-mcp deployment via MCPServer CR" "Internal RHOAI"

        # Relationships
        agent -> rhoaiMcp "Invokes MCP tools via streamable-http or SSE" "HTTPS/443"
        rhoaiMcp -> k8sApi "CRUD operations on cluster resources" "HTTPS/6443"
        rhoaiMcp -> modelRegistry "Queries registered models and versions" "HTTP/8080 or HTTPS/8443"
        rhoaiMcp -> modelCatalog "Syncs benchmark data for planning" "HTTPS/8443"
        rhoaiMcp -> llmdPlanner "GPU/resource planning requests" "HTTP/8000"

        mcpOperator -> rhoaiMcp "Manages deployment lifecycle" "MCPServer CR"

        # Internal container relationships
        transport -> oidcAuth "Dispatches ASGI requests"
        oidcAuth -> rbacChecker "Passes authenticated user context"
        oidcAuth -> k8sApi "TokenReview validation" "HTTPS/6443"
        rbacChecker -> mcpServer "Provides filtered tool set"
        rbacChecker -> k8sApi "SubjectAccessReview" "HTTPS/6443"
        mcpServer -> pluginManager "Dispatches tool calls"
        pluginManager -> domainProjects "Project tools"
        pluginManager -> domainNotebooks "Notebook tools"
        pluginManager -> domainInference "Inference tools"
        pluginManager -> domainConnections "Connection tools"
        pluginManager -> domainStorage "Storage tools"
        pluginManager -> domainPipelines "Pipeline tools"
        pluginManager -> domainTraining "Training tools"
        pluginManager -> domainModelRegistry "Model Registry tools"
        pluginManager -> compositeExplorer "Exploration composites"
        pluginManager -> compositeTraining "Training composites"
        pluginManager -> compositePlanner "Planning composites"
        pluginManager -> compositeDiagnostics "Diagnostics composites"

        domainProjects -> k8sClient "K8s operations"
        domainNotebooks -> k8sClient "K8s operations"
        domainInference -> k8sClient "K8s operations"
        domainConnections -> k8sClient "K8s operations"
        domainStorage -> k8sClient "K8s operations"
        domainPipelines -> k8sClient "K8s operations"
        domainTraining -> k8sClient "K8s operations"
        k8sClient -> k8sApi "Kubernetes API calls" "HTTPS/6443"
        domainModelRegistry -> modelRegistry "REST API calls" "HTTP/HTTPS"

        compositeTraining -> workflowTokens "Issues/validates tokens"
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
                color #000000
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
