workspace {
    !identifiers hierarchical

    model {
        // Users / Actors
        dataScientist = person "Data Scientist" "Creates and deploys ML models, manages workbenches and training jobs"
        mlEngineer = person "ML Engineer" "Deploys models to production, manages serving infrastructure"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, monitors cluster health"

        // Main System
        rhoaiMcp = softwareSystem "RHOAI MCP Server" "MCP server enabling AI agents to interact with RHOAI environments through tools, resources, and workflow prompts" {
            transport = container "Transport Layer" "Handles MCP protocol connections (stdio, SSE, streamable-http)" "Python (FastMCP)"
            pluginManager = container "Plugin Manager" "Discovers, registers, and manages plugin lifecycle with health checks" "Python (pluggy)"
            domainPlugins = container "Domain Plugins (10)" "CRUD operations for RHOAI resource types: projects, notebooks, inference, pipelines, connections, storage, training, model_registry, quickstarts, prompts" "Python Modules"
            compositePlugins = container "Composite Plugins (4)" "Cross-cutting orchestration: cluster exploration, training workflows, meta/discovery, NeuralNav" "Python Modules"
            k8sClient = container "K8s Client" "Abstraction over Kubernetes Python client with auth mode detection" "Python (kubernetes)"
            portForwardMgr = container "Port Forward Manager" "Manages oc port-forward subprocesses for in-cluster service access" "Python (subprocess)"
            config = container "Configuration" "Environment-based config with safety controls (read-only, dangerous ops)" "Python (pydantic-settings)"
        }

        // AI Agent Systems
        aiAgent = softwareSystem "AI Agent" "Claude Desktop, Lightspeed, or custom LLM agent that invokes MCP tools" "External"

        // RHOAI Platform Components
        kubeflowNotebook = softwareSystem "Kubeflow Notebook Controller" "Manages Notebook CR lifecycle for workbenches" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Manages InferenceService and ServingRuntime CRs for model serving" "Internal RHOAI"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Manages DSPA CRs for pipeline server provisioning" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Manages TrainJob and ClusterTrainingRuntime CRs" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Platform lifecycle: DataScienceCluster and DSCInitialization CRs" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for RHOAI platform management" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata, versions, and benchmark storage" "Internal RHOAI"
        modelCatalog = softwareSystem "Red Hat AI Model Catalog" "Pre-curated model catalog with benchmarks" "Internal RHOAI"

        // External Dependencies
        neuralNavigator = softwareSystem "Neural Navigator" "Model recommendation and deployment config generation engine" "External"
        k8sApiServer = softwareSystem "Kubernetes API Server" "Kubernetes/OpenShift cluster API" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts and data" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Authentication for workbench routes" "External"

        // Relationships - Users to AI Agent
        dataScientist -> aiAgent "Uses AI agent to manage ML workflows"
        mlEngineer -> aiAgent "Uses AI agent to deploy and monitor models"
        platformAdmin -> aiAgent "Uses AI agent to explore and diagnose cluster"

        // AI Agent to MCP Server
        aiAgent -> rhoaiMcp "Invokes MCP tools/resources/prompts" "MCP Protocol (stdio/SSE/HTTP) 8000/TCP"

        // MCP Server to Platform Components (all via K8s API)
        rhoaiMcp -> k8sApiServer "All Kubernetes resource operations" "HTTPS/6443 Bearer Token"
        rhoaiMcp -> kubeflowNotebook "Manages Notebook CRs" "via K8s API (CRD)"
        rhoaiMcp -> kserve "Manages InferenceService and ServingRuntime CRs" "via K8s API (CRD)"
        rhoaiMcp -> dspOperator "Manages DSPA CRs" "via K8s API (CRD)"
        rhoaiMcp -> trainingOperator "Manages TrainJob and ClusterTrainingRuntime CRs" "via K8s API (CRD)"
        rhoaiMcp -> rhoaiOperator "Reads DataScienceCluster status" "via K8s API (CRD, read-only)"
        rhoaiMcp -> rhoaiDashboard "Compatible labeling (opendatahub.io/dashboard)" "Label convention"
        rhoaiMcp -> modelRegistry "Queries model metadata, versions, benchmarks" "REST HTTP/8080 via port-forward"
        rhoaiMcp -> modelCatalog "Queries pre-curated model catalog" "REST HTTP/8080 via port-forward"
        rhoaiMcp -> neuralNavigator "Model recommendation and deploy config" "REST HTTP/8000 in-cluster"
        rhoaiMcp -> s3Storage "Data connection validation" "HTTPS/443 AWS IAM"

        // Container relationships
        transport -> pluginManager "Routes MCP calls"
        pluginManager -> domainPlugins "Dispatches to domain handlers"
        pluginManager -> compositePlugins "Dispatches to composite handlers"
        domainPlugins -> k8sClient "Kubernetes operations"
        compositePlugins -> k8sClient "Kubernetes operations"
        compositePlugins -> portForwardMgr "Port-forward for in-cluster services"
    }

    views {
        systemContext rhoaiMcp "SystemContext" {
            include *
            autoLayout
            description "RHOAI MCP Server in the context of AI agents and RHOAI platform components"
        }

        container rhoaiMcp "Containers" {
            include *
            autoLayout
            description "Internal structure of the RHOAI MCP Server"
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
                shape Person
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
