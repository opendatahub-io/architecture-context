workspace {
    model {
        dataScientist = person "Data Scientist / ML Engineer" "Creates projects, trains models, deploys inference services via AI agent"
        aiAgent = person "AI Agent" "Claude Desktop or Claude Code interacting with RHOAI via MCP protocol"

        rhoaiMcp = softwareSystem "RHOAI MCP Server" "MCP server exposing RHOAI operations as tools, resources, and prompts to AI agents" {
            mcpServer = container "FastMCP Server" "Handles MCP protocol transport (stdio/SSE/HTTP), tool dispatch, response formatting" "Python / FastMCP"
            pluginManager = container "Plugin Manager" "Discovers, registers, and manages domain/composite plugins via hook-based architecture" "Python / pluggy"
            k8sClient = container "K8sClient" "Kubernetes API abstraction with dynamic resource discovery, CRD caching, multi-auth" "Python / kubernetes-client"
            domainPlugins = container "Domain Plugins (9)" "CRUD operations: projects, notebooks, inference, pipelines, connections, storage, training, model-registry, quickstarts" "Python Modules"
            compositePlugins = container "Composite Plugins (4)" "Cross-cutting tools: cluster exploration, training orchestration, tool discovery, neural navigator" "Python Modules"
            portForwardMgr = container "Port-Forward Manager" "Manages oc port-forward subprocesses for accessing internal K8s services" "Python / asyncio"
        }

        kubernetesApi = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane for all resource operations" "External" {
            tags "External"
        }
        openshiftApi = softwareSystem "OpenShift API" "RBAC-filtered project listing via project.openshift.io" "External" {
            tags "External"
        }

        kserve = softwareSystem "KServe" "Model serving controller — manages InferenceService and ServingRuntime CRDs" "Internal RHOAI" {
            tags "Internal"
        }
        kubeflowNotebook = softwareSystem "Kubeflow Notebook Controller" "Manages Notebook CRDs for workbenches" "Internal RHOAI" {
            tags "Internal"
        }
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Manages TrainJob and ClusterTrainingRuntime CRDs" "Internal RHOAI" {
            tags "Internal"
        }
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Manages DataSciencePipelinesApplication CRDs" "Internal RHOAI" {
            tags "Internal"
        }
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, artifacts, and benchmarks" "Internal RHOAI" {
            tags "Internal"
        }
        modelCatalog = softwareSystem "Model Catalog" "Catalog of available models, sources, and deployment intents" "Internal RHOAI" {
            tags "Internal"
        }
        neuralNavigator = softwareSystem "Neural Navigator" "ML recommendation engine — resource estimation, SLO-based ranking, deployment YAML" "Internal RHOAI" {
            tags "Internal"
        }
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for RHOAI — MCP server creates dashboard-compatible resources" "Internal RHOAI" {
            tags "Internal"
        }

        huggingFace = softwareSystem "HuggingFace Hub" "Model and dataset downloads" "External SaaS" {
            tags "External"
        }
        s3Storage = softwareSystem "S3-compatible Object Store" "Pipeline artifacts and model storage" "External SaaS" {
            tags "External"
        }

        # Relationships
        dataScientist -> aiAgent "Instructs agent to perform RHOAI operations"
        aiAgent -> rhoaiMcp "MCP Protocol (stdio/SSE/HTTP)" "MCP"

        mcpServer -> pluginManager "Loads plugins at startup"
        pluginManager -> domainPlugins "Registers domain hooks"
        pluginManager -> compositePlugins "Registers composite hooks"
        domainPlugins -> k8sClient "All K8s resource operations"
        compositePlugins -> domainPlugins "Orchestrates multiple domains"
        domainPlugins -> portForwardMgr "Port-forward for Model Registry"

        rhoaiMcp -> kubernetesApi "HTTPS/6443 — CRD CRUD, pod logs, node discovery" "HTTPS + Bearer Token"
        rhoaiMcp -> openshiftApi "HTTPS/6443 — Project listing" "HTTPS + Bearer Token"
        rhoaiMcp -> modelRegistry "HTTP/8080 — Model listing, versions, benchmarks" "HTTP (in-cluster)"
        rhoaiMcp -> modelCatalog "HTTP/8080 — Catalog models, sources" "HTTP"
        rhoaiMcp -> neuralNavigator "HTTP/8000 — Model recommendation, deployment config" "HTTP"
        rhoaiMcp -> huggingFace "HTTPS/443 — Model/dataset downloads" "HTTPS + Bearer Token"
        rhoaiMcp -> s3Storage "HTTPS/443 — Artifact storage" "HTTPS + AWS IAM"

        kserve -> kubernetesApi "Watches InferenceService CRDs"
        kubeflowNotebook -> kubernetesApi "Watches Notebook CRDs"
        trainingOperator -> kubernetesApi "Watches TrainJob CRDs"
        dspOperator -> kubernetesApi "Watches DSPA CRDs"

        rhoaiDashboard -> kubernetesApi "Dashboard UI operations"
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
