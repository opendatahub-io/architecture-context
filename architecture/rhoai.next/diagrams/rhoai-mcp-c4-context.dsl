workspace {
    model {
        agent = person "AI Agent" "Claude Desktop or Claude Code user interacting with RHOAI via MCP tools"
        dataScientist = person "Data Scientist" "Creates and manages ML workloads through AI agent"

        rhoaiMcp = softwareSystem "RHOAI MCP Server" "Programmatic MCP interface for AI agents to manage RHOAI environments (60+ tools, 8 resources, 18 prompts)" {
            fastmcpServer = container "FastMCP Server" "MCP transport layer supporting stdio, SSE, and streamable-http" "Python / FastMCP"
            pluginManager = container "Plugin Manager" "Pluggy-based lifecycle management for 14 domain + composite plugins" "Python / pluggy"
            k8sClient = container "K8sClient" "Kubernetes API abstraction supporting in-cluster, kubeconfig, and token auth" "Python / kubernetes"
            responseBuilder = container "Response Builder" "Verbosity-controlled response formatting with 70-90% token savings" "Python"
            portForwardManager = container "Port Forward Manager" "Async subprocess management for oc port-forward connections" "Python / asyncio"

            domainProjects = container "Projects Domain" "5 tools: list, create, delete, set_model_serving_mode" "Python Plugin"
            domainNotebooks = container "Notebooks Domain" "8 tools: list, create, start, stop workbenches" "Python Plugin"
            domainInference = container "Inference Domain" "12 tools: deploy_model, list_serving_runtimes, estimate_resources" "Python Plugin"
            domainPipelines = container "Pipelines Domain" "3 tools: get/create pipeline server" "Python Plugin"
            domainConnections = container "Connections Domain" "4 tools: list/create data connections" "Python Plugin"
            domainStorage = container "Storage Domain" "3 tools: list/create storage" "Python Plugin"
            domainTraining = container "Training Domain" "21 tools: train, monitor, resume, estimate resources" "Python Plugin"
            domainModelRegistry = container "Model Registry Domain" "10 tools: list models, benchmarks, artifacts" "Python Plugin"
            domainQuickstarts = container "Quickstarts Domain" "3 tools: list, deploy quickstarts" "Python Plugin"

            compositeCluster = container "Cluster Composite" "9 tools: cluster_summary, explore_cluster, diagnose_resource" "Python Plugin"
            compositeTraining = container "Training Composite" "Orchestrates multi-step training workflows" "Python Plugin"
            compositeMeta = container "Meta Composite" "2 tools: suggest_tools, list_tool_categories" "Python Plugin"
            compositeNeuralNav = container "Neural Navigator Composite" "2 tools: recommend_model, get_deployment_config" "Python Plugin"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "OpenShift cluster API for all resource operations" "External" {
            tags "External"
        }

        modelRegistrySvc = softwareSystem "Model Registry" "Kubeflow Model Registry for model metadata, versions, artifacts" "Internal RHOAI" {
            tags "Internal RHOAI"
        }

        modelCatalogSvc = softwareSystem "Model Catalog" "Red Hat AI Model Catalog for catalog models and sources" "Internal RHOAI" {
            tags "Internal RHOAI"
        }

        neuralNavigatorBE = softwareSystem "Neural Navigator" "AI-powered model recommendation and deployment config generation" "Internal RHOAI" {
            tags "Internal RHOAI"
        }

        github = softwareSystem "GitHub" "External repository for quickstart templates" "External" {
            tags "External"
        }

        imageRegistry = softwareSystem "Container Image Registry" "OpenShift internal registry for notebook images" "External" {
            tags "External"
        }

        # Person relationships
        dataScientist -> agent "Instructs to manage RHOAI resources"
        agent -> rhoaiMcp "Invokes MCP tools via stdio or SSE/HTTP" "MCP JSON-RPC"

        # Internal container relationships
        fastmcpServer -> pluginManager "Loads and registers plugins"
        pluginManager -> domainProjects "Registers"
        pluginManager -> domainNotebooks "Registers"
        pluginManager -> domainInference "Registers"
        pluginManager -> domainPipelines "Registers"
        pluginManager -> domainConnections "Registers"
        pluginManager -> domainStorage "Registers"
        pluginManager -> domainTraining "Registers"
        pluginManager -> domainModelRegistry "Registers"
        pluginManager -> domainQuickstarts "Registers"
        pluginManager -> compositeCluster "Registers"
        pluginManager -> compositeTraining "Registers"
        pluginManager -> compositeMeta "Registers"
        pluginManager -> compositeNeuralNav "Registers"

        compositeCluster -> domainProjects "Orchestrates"
        compositeCluster -> domainNotebooks "Orchestrates"
        compositeCluster -> domainInference "Orchestrates"
        compositeTraining -> domainTraining "Orchestrates"
        compositeTraining -> domainStorage "Orchestrates"
        compositeTraining -> domainConnections "Orchestrates"

        domainProjects -> k8sClient "Uses"
        domainNotebooks -> k8sClient "Uses"
        domainInference -> k8sClient "Uses"
        domainPipelines -> k8sClient "Uses"
        domainTraining -> k8sClient "Uses"
        domainModelRegistry -> portForwardManager "Uses for out-of-cluster access"

        # External system relationships
        rhoaiMcp -> k8sApiServer "All K8s resource CRUD operations" "HTTPS/6443, Bearer Token"
        rhoaiMcp -> modelRegistrySvc "List models, versions, artifacts, benchmarks" "HTTP/8080 or HTTPS/8443"
        rhoaiMcp -> modelCatalogSvc "List catalog models, sources, artifacts" "HTTP/8080 or HTTPS/8443"
        rhoaiMcp -> neuralNavigatorBE "Model recommendations and deployment configs" "HTTP/8000"
        rhoaiMcp -> github "Clone quickstart repositories" "HTTPS/443"
        rhoaiMcp -> imageRegistry "Discover notebook container images" "HTTPS/5000"
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
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
