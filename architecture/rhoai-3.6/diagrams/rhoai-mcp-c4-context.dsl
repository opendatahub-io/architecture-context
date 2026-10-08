workspace {
    model {
        agent = person "AI Agent" "An AI agent or MCP client that interacts with RHOAI through programmatic tools"

        rhoaiMCP = softwareSystem "rhoai-mcp" "MCP server exposing RHOAI operations as agent-consumable tools over Model Context Protocol" {
            server = container "RHOAIServer" "FastMCP server with pluggy-based plugin architecture" "Python / FastMCP / uvicorn"
            oidcAuth = container "OIDC Auth Middleware" "ASGI middleware for JWT/TokenReview validation and user context" "Python / PyJWT"
            rbacChecker = container "RBAC Checker" "Tool-level RBAC filtering via SubjectAccessReview" "Python / kubernetes SDK"
            domainPlugins = container "Domain Plugins" "9 plugins: projects, notebooks, inference, pipelines, connections, storage, training, model_registry, prompts" "Python / pluggy"
            compositePlugins = container "Composite Plugins" "4 plugins: cluster, training, meta, planner composites" "Python / pluggy"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster resource management (pods, namespaces, secrets, PVCs, CRDs)" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter workbench lifecycle management" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (InferenceService, ServingRuntime)" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "ML training job management (TrainJob, ClusterTrainingRuntime)" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline infrastructure (DSPA)" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model artifact registration and metadata storage" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Benchmark data for model recommendations" "Internal RHOAI"
        oidcProvider = softwareSystem "OIDC Provider" "JWT token validation (JWKS, OpenID configuration)" "External"
        mcpLifecycleOp = softwareSystem "MCP Lifecycle Operator" "Manages rhoai-mcp deployment via MCPServer CR" "Internal RHOAI"
        plannerBackend = softwareSystem "Planner Backend" "LLM model recommendation service (remote mode)" "Internal RHOAI"

        agent -> rhoaiMCP "Sends MCP tool calls via" "HTTPS/443 (Route) → HTTP/8000"
        rhoaiMCP -> k8sAPI "Manages cluster resources via" "HTTPS/6443, SA or user token"
        rhoaiMCP -> kubeflowNotebooks "Creates/manages workbenches via" "K8s CRD CRUD"
        rhoaiMCP -> kserve "Deploys/manages inference endpoints via" "K8s CRD CRUD"
        rhoaiMCP -> trainingOperator "Creates/manages training jobs via" "K8s CRD CRUD"
        rhoaiMCP -> dsPipelines "Configures pipeline infrastructure via" "K8s CRD CRUD"
        rhoaiMCP -> modelRegistry "Queries/registers model artifacts via" "HTTP/8080 or HTTPS/8443"
        rhoaiMCP -> modelCatalog "Syncs benchmark data for Planner via" "HTTPS/8443, SA token"
        rhoaiMCP -> oidcProvider "Validates JWT tokens via" "HTTPS/443, JWKS discovery"
        rhoaiMCP -> plannerBackend "Gets model recommendations via" "HTTP/8000 (remote mode)"
        mcpLifecycleOp -> rhoaiMCP "Manages deployment lifecycle via" "MCPServer CR (mcp.x-k8s.io/v1alpha1)"
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
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
