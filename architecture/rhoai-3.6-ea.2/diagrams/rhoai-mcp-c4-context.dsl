workspace {
    model {
        aiAgent = person "AI Agent" "Claude Desktop, Claude Code, or other MCP-compatible AI assistants"
        dataScientist = person "Data Scientist" "Uses AI agents to interact with RHOAI platform"

        rhoaiMcp = softwareSystem "rhoai-mcp" "MCP server exposing RHOAI operations as AI-agent-callable tools via stdio/SSE/streamable-http" {
            server = container "FastMCP Server" "MCP protocol server with stdio, SSE, and streamable-http transport modes" "Python (FastMCP)"
            authLayer = container "Auth Layer" "OIDC/TokenReview authentication, per-user context, RBAC-based tool filtering via SubjectAccessReview" "Python (ASGI Middleware)"
            domainPlugins = container "Domain Plugins" "9 domain modules: projects, notebooks, inference, pipelines, connections, storage, training, model_registry, prompts" "Python (pluggy)"
            compositePlugins = container "Composite Plugins" "4 cross-cutting orchestration plugins: cluster, training, meta, planner" "Python (pluggy)"
            k8sClient = container "K8sClient" "Kubernetes API abstraction with CoreV1Api, DynamicClient, CRD caching" "Python (kubernetes)"
        }

        k8sApi = softwareSystem "Kubernetes API" "OpenShift/Kubernetes API server for cluster resource management" "External"
        oidcProvider = softwareSystem "OIDC Provider" "OpenID Connect identity provider for user authentication" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter workbench management via Notebook CRD" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving via InferenceService and ServingRuntime CRDs" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Training job management via TrainJob CRD" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines" "Pipeline infrastructure via DSPA CRD" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata registry" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Model benchmark data for planner recommendations" "Internal RHOAI"
        llmDPlanner = softwareSystem "llm-d-planner" "LLM model recommendation engine based on hardware and use-case" "Library"

        dataScientist -> aiAgent "Instructs via natural language"
        aiAgent -> rhoaiMcp "MCP tool calls via SSE/HTTP" "HTTPS/443"
        rhoaiMcp -> k8sApi "CRUD on cluster resources" "HTTPS/6443"
        rhoaiMcp -> oidcProvider "JWKS discovery and token validation" "HTTPS/443"
        rhoaiMcp -> kubeflowNotebooks "Manage Jupyter workbenches" "via K8s API"
        rhoaiMcp -> kserve "Deploy/manage model serving" "via K8s API"
        rhoaiMcp -> trainingOperator "Create/manage training jobs" "via K8s API"
        rhoaiMcp -> dspa "Configure pipeline infrastructure" "via K8s API"
        rhoaiMcp -> modelRegistry "Query registered models" "HTTP/8080"
        rhoaiMcp -> modelCatalog "Fetch benchmark data" "HTTPS/8443"
        rhoaiMcp -> llmDPlanner "Model recommendations" "Library call"

        server -> authLayer "Delegates auth"
        authLayer -> domainPlugins "Filtered tool dispatch"
        authLayer -> compositePlugins "Filtered tool dispatch"
        domainPlugins -> k8sClient "K8s operations"
        compositePlugins -> k8sClient "K8s operations"
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
                color #ffffff
            }
            element "Library" {
                background #3498db
                color #ffffff
            }
            element "Person" {
                shape person
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
