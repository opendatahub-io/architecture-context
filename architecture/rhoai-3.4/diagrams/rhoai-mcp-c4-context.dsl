workspace {
    model {
        aiAgent = person "AI Agent" "Claude, ChatGPT, or other LLM-based assistant that interacts with RHOAI via MCP protocol"
        dataScientist = person "Data Scientist" "Uses AI agents to manage ML workloads on RHOAI"

        rhoaiMcp = softwareSystem "RHOAI MCP Server" "MCP server exposing RHOAI platform capabilities as tools, resources, and prompts for AI agents" {
            mcpServer = container "MCP Server" "FastMCP-based server handling MCP protocol (stdio/SSE/streamable-http)" "Python / FastMCP"
            pluginManager = container "Plugin Manager" "Discovers, registers, and health-checks plugins via pluggy hook system" "Python / pluggy"
            k8sClient = container "K8s Client" "Kubernetes API client with multi-auth support (SA/kubeconfig/token)" "Python / kubernetes"
            domainPlugins = container "Domain Plugins" "10 domain plugins: Notebooks, Inference, Pipelines, Connections, Storage, Training, Model Registry, Quickstarts, Projects, Prompts" "Python"
            compositePlugins = container "Composite Plugins" "4 composite plugins: Cluster Exploration, Training Workflows, Neural Navigator, Meta/Tool Discovery" "Python"
            neuralNavClient = container "Neural Navigator Client" "HTTP client for Neural Navigator recommendation service" "Python / httpx"
            modelRegClient = container "Model Registry Client" "HTTP client for Model Registry and Model Catalog APIs" "Python / httpx"
            portForwardMgr = container "Port Forward Manager" "Async subprocess manager for oc port-forward tunnels" "Python / asyncio"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane API" "External"
        neuralNavigator = softwareSystem "Neural Navigator" "AI-guided model recommendation and deployment config generation service" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Kubeflow Model Registry for ML model versioning and artifacts" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Red Hat AI Model Catalog for browsing curated models" "Internal RHOAI"
        github = softwareSystem "GitHub" "Source code hosting for quickstart repositories" "External"

        # CRD-based systems (managed via K8s API)
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        kubeflow = softwareSystem "Kubeflow Notebooks" "JupyterLab/VS Code workbench management" "Internal RHOAI"
        trainingOperator = softwareSystem "Training Operator" "ML training job orchestration" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline server management" "Internal RHOAI"

        # Relationships - External
        dataScientist -> aiAgent "Instructs via natural language"
        aiAgent -> rhoaiMcp "MCP Protocol (stdio/SSE/HTTP)" "HTTPS/443 via Route"

        # Relationships - Internal
        rhoaiMcp -> k8sApiServer "All resource CRUD operations" "HTTPS/6443, SA Token"
        rhoaiMcp -> neuralNavigator "Model recommendations, deployment configs" "HTTP/8000 (in-cluster)"
        rhoaiMcp -> modelRegistry "Model metadata, versions, artifacts, benchmarks" "HTTP/8080 or HTTPS/8443"
        rhoaiMcp -> modelCatalog "Curated model browsing" "HTTP/8080 or HTTPS/8443"
        rhoaiMcp -> github "Clone quickstart repositories" "HTTPS/443"

        # CRD interactions (through K8s API)
        rhoaiMcp -> kserve "Manages InferenceService and ServingRuntime CRs" "via K8s API"
        rhoaiMcp -> kubeflow "Manages Notebook CRs (workbenches)" "via K8s API"
        rhoaiMcp -> trainingOperator "Manages TrainJob and TrainingRuntime CRs" "via K8s API"
        rhoaiMcp -> dsPipelines "Manages DSPA CRs" "via K8s API"

        # Container relationships
        mcpServer -> pluginManager "Registers and loads plugins"
        pluginManager -> domainPlugins "Loads domain plugins"
        pluginManager -> compositePlugins "Loads composite plugins"
        domainPlugins -> k8sClient "CRUD operations"
        compositePlugins -> domainPlugins "Orchestrates cross-domain workflows"
        compositePlugins -> neuralNavClient "Model recommendations"
        domainPlugins -> modelRegClient "Model registry queries"
        modelRegClient -> portForwardMgr "Out-of-cluster access tunnels"
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
