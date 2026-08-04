workspace {
    model {
        aiAgent = person "AI Agent" "AI agent or LLM client that interacts with RHOAI via MCP protocol"

        rhoaiMcp = softwareSystem "rhoai-mcp" "Model Context Protocol server providing tool-based access to Red Hat OpenShift AI environments" {
            authMiddleware = container "OIDCAuthMiddleware" "Validates Bearer JWT (JWKS) or opaque tokens (TokenReview), sets UserContext for impersonation" "Python ASGI Middleware"
            mcpServer = container "RHOAIServer" "FastMCP runtime orchestrating plugin lifecycle, tool registration, and RBAC-based tool filtering" "Python (FastMCP)"
            pluginManager = container "Plugin Manager" "Loads and manages domain-specific plugins via pluggy entrypoints" "Python (pluggy)"
            notebooksPlugin = container "Notebooks Plugin" "CRUD operations on Kubeflow Notebook workbenches" "Python Plugin"
            servingPlugin = container "Model Serving Plugin" "Watch/CRUD on KServe InferenceServices and ServingRuntimes" "Python Plugin"
            trainingPlugin = container "Training Plugin" "CRUD on Kubeflow TrainJobs and TrainingRuntimes" "Python Plugin"
            pipelinesPlugin = container "Pipelines Plugin" "CRUD on Data Science Pipeline Applications" "Python Plugin"
            registryPlugin = container "Model Registry Plugin" "HTTP client for model metadata and artifact management" "Python Plugin"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API server managing all Kubernetes and CRD resources" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench management (kubeflow.org CRDs)" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform (serving.kserve.io CRDs)" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Training job orchestration (trainer.kubeflow.org CRDs)" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "Pipeline workflow management (opendatahub.io CRDs)" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and artifact storage" "Internal RHOAI"

        aiAgent -> rhoaiMcp "Sends MCP tool calls via SSE/streamable-http" "MCP/8000"
        rhoaiMcp -> k8sApi "Manages CRDs and core resources" "HTTPS/6443"
        rhoaiMcp -> modelRegistry "Queries model metadata" "HTTP/8080"
        k8sApi -> kubeflowNotebooks "Manages Notebook CRs"
        k8sApi -> kserve "Manages InferenceService CRs"
        k8sApi -> trainingOperator "Manages TrainJob CRs"
        k8sApi -> dsPipelines "Manages DSPA CRs"

        authMiddleware -> mcpServer "Passes authenticated request with UserContext"
        mcpServer -> pluginManager "Loads and dispatches tool calls"
        pluginManager -> notebooksPlugin "Routes notebook tool calls"
        pluginManager -> servingPlugin "Routes serving tool calls"
        pluginManager -> trainingPlugin "Routes training tool calls"
        pluginManager -> pipelinesPlugin "Routes pipeline tool calls"
        pluginManager -> registryPlugin "Routes registry tool calls"
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
                shape person
                background #9b59b6
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
