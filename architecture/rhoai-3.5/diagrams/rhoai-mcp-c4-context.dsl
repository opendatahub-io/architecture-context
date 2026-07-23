workspace {
    model {
        datascientist = person "Data Scientist / AI Agent" "Uses MCP-compatible AI assistants to manage RHOAI workflows"

        rhoaiMcp = softwareSystem "RHOAI MCP Server" "MCP server enabling AI agents to manage RHOAI platform resources via 60+ tools across 14 plugins" {
            mcpServer = container "MCP Server" "FastMCP-based server handling SSE/streamable-HTTP transports" "Python / FastMCP"
            pluginManager = container "Plugin Manager" "Discovers and manages 10 domain + 4 composite plugins" "Python / pluggy"
            oidcMiddleware = container "OIDC Auth Middleware" "ASGI middleware for Bearer token validation (JWT/TokenReview)" "Python / PyJWT"
            rbacChecker = container "RBAC Checker" "Per-tool permission filtering via SubjectAccessReview" "Python / kubernetes SDK"
            k8sClient = container "K8s Client" "Abstraction over Kubernetes dynamic client with CRD caching and user impersonation" "Python / kubernetes SDK"
            portForwardMgr = container "Port-Forward Manager" "Singleton manager for oc port-forward with reference counting" "Python / subprocess"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Core cluster API for resource CRUD, RBAC, SubjectAccessReview, TokenReview" "External"
        kubeflowNotebook = softwareSystem "Kubeflow Notebook Controller" "Manages Jupyter/VS Code workbenches via Notebook CRDs" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Manages pipeline servers via DSPA CRDs" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Manages training jobs via TrainJob CRDs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry / Model Catalog" "Stores model metadata, versions, artifacts, benchmarks" "Internal RHOAI"
        plannerBackend = softwareSystem "Planner Backend" "LLM model recommendation and deployment config generation" "Internal RHOAI"
        oidcProvider = softwareSystem "OIDC Identity Provider" "OpenShift OAuth or external IDP for user authentication" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI operator managing DataScienceCluster and component lifecycle" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external HTTPS access via Routes" "External"

        # Relationships
        datascientist -> rhoaiMcp "Manages RHOAI workflows via MCP tools" "MCP over SSE/HTTP"

        rhoaiMcp -> k8sApi "CRUD operations, RBAC checks, user impersonation" "HTTPS/443 TLS 1.2+"
        rhoaiMcp -> kubeflowNotebook "Creates/manages workbenches" "via K8s API (Notebook CR)"
        rhoaiMcp -> kserve "Deploys/manages inference services" "via K8s API (InferenceService CR)"
        rhoaiMcp -> dspOperator "Creates/manages pipeline servers" "via K8s API (DSPA CR)"
        rhoaiMcp -> trainingOperator "Creates/manages training jobs" "via K8s API (TrainJob CR)"
        rhoaiMcp -> modelRegistry "Queries model metadata and benchmarks" "HTTP/8080"
        rhoaiMcp -> plannerBackend "Gets model recommendations" "HTTP/8000"
        rhoaiMcp -> oidcProvider "Validates user tokens (JWKS/TokenReview)" "HTTPS/443 TLS 1.2+"
        rhoaiMcp -> rhodsOperator "Reads cluster status, component availability" "via K8s API (DSC CR)"
        openshiftRouter -> rhoaiMcp "Routes external traffic" "HTTPS/443 → HTTP/8000 (TLS edge)"

        # Container relationships
        mcpServer -> pluginManager "Loads and invokes plugins"
        mcpServer -> oidcMiddleware "Validates incoming requests"
        oidcMiddleware -> rbacChecker "Filters tools per user"
        rbacChecker -> k8sClient "SubjectAccessReview calls"
        pluginManager -> k8sClient "Domain plugin K8s operations"
        k8sClient -> k8sApi "REST API calls with impersonation" "HTTPS/443"
        portForwardMgr -> k8sApi "Port-forward tunnels" "HTTPS/443"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
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
        }
    }
}
