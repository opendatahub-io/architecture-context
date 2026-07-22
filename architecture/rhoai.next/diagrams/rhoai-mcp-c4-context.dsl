workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates projects, deploys models, runs training jobs via AI agent"
        aiAgent = person "AI Agent" "Claude Desktop, VS Code Copilot, or other MCP client"

        rhoaiMcp = softwareSystem "RHOAI MCP Server" "MCP server bridging AI agents to Red Hat OpenShift AI clusters via 55+ tools" {
            mcpServer = container "MCP Server Core" "FastMCP-based server with pluggy plugin system, multi-transport (stdio/SSE/streamable-http)" "Python / FastMCP"
            authModule = container "Auth Module" "OIDC JWT validation, Kubernetes TokenReview, RBAC filtering via SubjectAccessReview" "Python / PyJWT"
            k8sClient = container "K8s Client" "Multi-auth Kubernetes API client with user impersonation and CRD support" "Python / kubernetes"
            domainPlugins = container "Domain Plugins (7)" "CRUD operations for projects, notebooks, inference, pipelines, connections, storage, training" "Python / pluggy"
            compositePlugins = container "Composite Plugins (4)" "Cross-domain orchestration: cluster explorer, training workflows, meta/discovery, planner" "Python / pluggy"
            plannerClient = container "Planner Client" "REST client for external Planner API providing model recommendations" "Python / httpx"
            modelRegClient = container "Model Registry Client" "Auto-discovers and connects to Kubeflow Model Registry or Red Hat AI Model Catalog" "Python / httpx"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane for all CRD CRUD operations" "External"
        kubeflowNotebook = softwareSystem "Kubeflow Notebook Controller" "Manages workbench (Notebook) CRDs" "Internal RHOAI"
        kserve = softwareSystem "KServe Controller" "Model serving via InferenceService CRDs" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator v2" "Training job lifecycle via TrainJob CRDs" "Internal RHOAI"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Pipeline server management via DSPA CRDs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry / Model Catalog" "Model metadata storage and discovery" "Internal RHOAI"
        plannerService = softwareSystem "Planner Service" "Model recommendation and deployment config generation" "Internal RHOAI"
        oidcProvider = softwareSystem "OIDC Provider" "Identity provider for JWT token validation" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Validates opaque OCP OAuth tokens via TokenReview" "External"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "DataScienceCluster/DSCI status and component health" "Internal RHOAI"

        # Relationships - External
        dataScientist -> aiAgent "Uses AI agent to interact with RHOAI"
        aiAgent -> rhoaiMcp "MCP Protocol (stdio/SSE/streamable-http) over HTTPS/443"

        # Relationships - Internal
        mcpServer -> authModule "Validates requests"
        mcpServer -> domainPlugins "Dispatches MCP tool calls via pluggy hooks"
        mcpServer -> compositePlugins "Dispatches composite tool calls"
        domainPlugins -> k8sClient "CRUD operations"
        compositePlugins -> k8sClient "Cross-domain queries"
        compositePlugins -> plannerClient "Model recommendations"
        compositePlugins -> modelRegClient "Model discovery"
        authModule -> oidcProvider "JWKS fetching, token validation" "HTTPS/443"
        authModule -> k8sAPI "TokenReview, SubjectAccessReview" "HTTPS/443"
        k8sClient -> k8sAPI "CRD CRUD, namespace/secret mgmt" "HTTPS/443"

        # Relationships - Platform
        rhoaiMcp -> kubeflowNotebook "Manages Notebook CRDs" "via K8s API"
        rhoaiMcp -> kserve "Manages InferenceService/ServingRuntime CRDs" "via K8s API"
        rhoaiMcp -> trainingOperator "Manages TrainJob/ClusterTrainingRuntime CRDs" "via K8s API"
        rhoaiMcp -> dspOperator "Manages DSPA CRDs" "via K8s API"
        rhoaiMcp -> modelRegistry "REST API queries" "HTTP(S)/8080-8443"
        rhoaiMcp -> plannerService "Model recommendations" "HTTP(S)"
        rhoaiMcp -> rhoaiDashboard "Reads DataScienceCluster status" "via K8s API"
        rhoaiMcp -> openshiftOAuth "TokenReview for opaque tokens" "via K8s API"
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
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
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
