workspace {
    model {
        dataScientist = person "Data Scientist / AI Agent" "Interacts with RHOAI via MCP tools to manage workbenches, models, pipelines, and training jobs"

        rhoaiMcp = softwareSystem "rhoai-mcp" "Model Context Protocol server for Red Hat OpenShift AI; enables AI agents to interact with RHOAI environments" {
            mcpServer = container "FastMCP Server" "Python-based MCP server with pluggy plugin system" "Python / uvicorn"
            oidcMiddleware = container "OIDC Auth Middleware" "ASGI middleware for JWT/TokenReview authentication" "Python ASGI"
            pluginManager = container "Plugin Manager" "Loads core domain plugins and external entrypoint plugins" "pluggy"
            toolRbac = container "Tool-Level RBAC" "Filters tool visibility and execution per-user via SubjectAccessReview" "Python"
        }

        kubernetesApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Manages notebook workbenches (kubeflow.org)" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform (serving.kserve.io)" "Internal RHOAI"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages training jobs (trainer.kubeflow.org)" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "Pipeline orchestration (opendatahub.io)" "Internal RHOAI"
        oidcProvider = softwareSystem "OIDC Provider" "Identity provider for JWT token validation" "External"

        dataScientist -> rhoaiMcp "Invokes MCP tools via SSE/Streamable-HTTP" "MCP Protocol / Bearer Token"
        rhoaiMcp -> kubernetesApi "Manages cluster resources with user impersonation" "HTTPS/6443 TLS 1.2+"
        rhoaiMcp -> kubeflowNotebooks "Creates and manages notebook workbenches" "via Kubernetes API"
        rhoaiMcp -> kserve "Reads model serving state, manages serving runtimes" "via Kubernetes API"
        rhoaiMcp -> kubeflowTraining "Creates and manages training jobs" "via Kubernetes API"
        rhoaiMcp -> dsPipelines "Creates and manages pipeline applications" "via Kubernetes API"
        rhoaiMcp -> oidcProvider "Fetches JWKS for token validation" "HTTPS"

        oidcMiddleware -> mcpServer "Forwards authenticated requests"
        mcpServer -> pluginManager "Loads tools, resources, prompts"
        mcpServer -> toolRbac "Enforces per-user tool access"
        toolRbac -> kubernetesApi "SubjectAccessReview" "HTTPS/6443"
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
