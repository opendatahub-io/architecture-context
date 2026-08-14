workspace {
    model {
        aiAgent = person "AI Agent" "AI assistant or automation tool that uses MCP protocol to interact with RHOAI"

        rhoaiMcp = softwareSystem "rhoai-mcp" "MCP server enabling AI agents to manage RHOAI platform resources via Model Context Protocol" {
            fastmcpServer = container "FastMCP Server" "Handles MCP protocol messages, routes to plugins" "Python / Starlette / uvicorn"
            oidcMiddleware = container "OIDC Auth Middleware" "Validates Bearer tokens, enforces per-tool RBAC via SubjectAccessReview" "ASGI Middleware"
            pluginManager = container "Plugin Manager" "Discovers and loads domain plugins, collects RBAC mappings" "pluggy"
            workbenchPlugin = container "Workbench Plugin" "Manages Kubeflow Notebook workbenches" "Python Plugin"
            servingPlugin = container "Model Serving Plugin" "Manages KServe InferenceServices and ServingRuntimes" "Python Plugin"
            trainingPlugin = container "Training Plugin" "Manages Kubeflow TrainJobs and TrainingRuntimes" "Python Plugin"
            pipelinePlugin = container "Pipeline Plugin" "Manages DataSciencePipelinesApplications" "Python Plugin"
            clusterPlugin = container "Cluster Mgmt Plugin" "Manages pods, nodes, PVs, namespaces, secrets" "Python Plugin"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for managing all Kubernetes and CRD resources" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform managing InferenceServices" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workbench management" "Internal RHOAI"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Distributed ML training job management" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"

        # External relationships
        aiAgent -> rhoaiMcp "Sends MCP tool calls via stdio/SSE/streamable-http"

        # Internal container relationships
        oidcMiddleware -> fastmcpServer "Forwards authenticated requests"
        fastmcpServer -> pluginManager "Dispatches tool calls"
        pluginManager -> workbenchPlugin "Routes workbench tools"
        pluginManager -> servingPlugin "Routes serving tools"
        pluginManager -> trainingPlugin "Routes training tools"
        pluginManager -> pipelinePlugin "Routes pipeline tools"
        pluginManager -> clusterPlugin "Routes cluster tools"

        # Platform integrations
        workbenchPlugin -> k8sApi "CRUD Notebook CRs" "HTTPS/6443"
        servingPlugin -> k8sApi "Watch/CRUD InferenceService, ServingRuntime CRs" "HTTPS/6443"
        trainingPlugin -> k8sApi "CRUD TrainJob, TrainingRuntime CRs" "HTTPS/6443"
        pipelinePlugin -> k8sApi "CRUD DSPA CRs" "HTTPS/6443"
        clusterPlugin -> k8sApi "List/CRUD core resources" "HTTPS/6443"

        rhoaiMcp -> kserve "Manages InferenceServices and ServingRuntimes" "Kubernetes API / HTTPS"
        rhoaiMcp -> kubeflowNotebooks "Manages Notebook workbenches" "Kubernetes API / HTTPS"
        rhoaiMcp -> kubeflowTraining "Manages TrainJobs and TrainingRuntimes" "Kubernetes API / HTTPS"
        rhoaiMcp -> dsp "Manages DataSciencePipelinesApplications" "Kubernetes API / HTTPS"
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
                shape Person
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
