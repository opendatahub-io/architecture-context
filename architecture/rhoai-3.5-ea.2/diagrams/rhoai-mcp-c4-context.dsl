workspace {
    model {
        agent = person "AI Agent" "Claude, GPT, or Llama-based agent that manages ML lifecycle through natural language"
        dataScientist = person "Data Scientist" "Configures AI agent with MCP server connection to manage RHOAI resources"
        platformAdmin = person "Platform Admin" "Deploys and configures RHOAI MCP server, manages RBAC policies"

        rhoaiMcp = softwareSystem "RHOAI MCP Server" "MCP server bridging AI agents to OpenShift AI platform management" {
            transport = container "Transport Layer" "SSE, Streamable HTTP, stdio endpoints" "Python FastMCP"
            oidcAuth = container "OIDC Auth Middleware" "JWT/TokenReview validation, SubjectAccessReview RBAC filtering" "Python ASGI"
            pluginManager = container "Plugin Manager" "Discovers, loads, and manages domain and composite plugins" "Python pluggy"
            notebooksPlugin = container "Notebooks Plugin" "Workbench lifecycle management via kubeflow.org/Notebook CRDs" "Python"
            inferencePlugin = container "Inference Plugin" "Model serving via serving.kserve.io/InferenceService CRDs" "Python"
            pipelinesPlugin = container "Pipelines Plugin" "Pipeline server provisioning via DSPA CRDs" "Python"
            trainingPlugin = container "Training Plugin" "Training job management via trainer.kubeflow.org/TrainJob CRDs" "Python"
            connectionsPlugin = container "Connections Plugin" "Data connection (S3 secrets) management" "Python"
            storagePlugin = container "Storage Plugin" "PVC and StorageClass management" "Python"
            modelRegPlugin = container "Model Registry Plugin" "Model registration and catalog browsing via REST APIs" "Python"
            quickstartsPlugin = container "Quickstarts Plugin" "Helm-based quickstart deployments" "Python"
            projectsPlugin = container "Projects Plugin" "OpenShift project management" "Python"
            compositePlugins = container "Composite Plugins" "Cluster/training composites, meta tools, planner integration" "Python"
            k8sClient = container "K8s Client" "Kubernetes API client with CRD support and user impersonation" "Python kubernetes"
            config = container "Config Manager" "Environment-based settings, safety gates (read-only, dangerous ops)" "Python pydantic-settings"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane" "External"
        kserve = softwareSystem "KServe / Model Serving" "Serverless ML inference platform managing InferenceService resources" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Workbench (Jupyter) lifecycle controller" "Internal RHOAI"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Training job orchestration (TrainJob, ClusterTrainingRuntime)" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines Operator" "ML pipeline server provisioning and management" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform lifecycle operator (DataScienceCluster, DSCInitialization)" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage, versioning, and artifact tracking" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Curated model catalog with multiple sources" "Internal RHOAI"
        plannerService = softwareSystem "Planner Service" "Model recommendation and deployment config generation" "Internal RHOAI"
        oidcProvider = softwareSystem "OIDC Provider" "OpenID Connect identity provider (OpenShift OAuth or external)" "External"
        github = softwareSystem "GitHub" "Source code and quickstart content hosting" "External"
        helmRepos = softwareSystem "Helm Repositories" "Helm chart hosting for quickstart deployments" "External"

        # Person → System relationships
        agent -> rhoaiMcp "Sends MCP tool calls via SSE/HTTP/stdio" "MCP Protocol"
        dataScientist -> agent "Configures with MCP server URL and credentials"
        platformAdmin -> rhoaiMcp "Deploys via Kustomize, configures RBAC and auth"

        # Internal container relationships
        transport -> oidcAuth "Passes requests for auth" ""
        oidcAuth -> pluginManager "Routes authenticated requests" ""
        pluginManager -> notebooksPlugin "Loads and delegates" ""
        pluginManager -> inferencePlugin "Loads and delegates" ""
        pluginManager -> pipelinesPlugin "Loads and delegates" ""
        pluginManager -> trainingPlugin "Loads and delegates" ""
        pluginManager -> connectionsPlugin "Loads and delegates" ""
        pluginManager -> storagePlugin "Loads and delegates" ""
        pluginManager -> modelRegPlugin "Loads and delegates" ""
        pluginManager -> quickstartsPlugin "Loads and delegates" ""
        pluginManager -> projectsPlugin "Loads and delegates" ""
        pluginManager -> compositePlugins "Loads and delegates" ""
        notebooksPlugin -> k8sClient "CRD operations" ""
        inferencePlugin -> k8sClient "CRD operations" ""
        pipelinesPlugin -> k8sClient "CRD operations" ""
        trainingPlugin -> k8sClient "CRD operations" ""
        connectionsPlugin -> k8sClient "Secret operations" ""
        storagePlugin -> k8sClient "PVC operations" ""
        projectsPlugin -> k8sClient "Project operations" ""

        # System → External System relationships
        rhoaiMcp -> k8sApi "All cluster operations (CRD CRUD, RBAC, impersonation)" "HTTPS/443 Bearer Token"
        rhoaiMcp -> modelRegistry "Model registration, versioning, artifact retrieval" "HTTP/8080 or HTTPS/8443"
        rhoaiMcp -> modelCatalog "Model catalog browsing and artifact retrieval" "HTTP/8080 or HTTPS/8443"
        rhoaiMcp -> plannerService "Model recommendation, deployment config generation" "HTTP/8000"
        rhoaiMcp -> oidcProvider "JWKS key fetching for JWT validation" "HTTPS/443"
        rhoaiMcp -> github "Quickstart README content" "HTTPS/443"
        rhoaiMcp -> helmRepos "Helm chart downloads" "HTTPS/443"

        # CRD interactions (via K8s API)
        rhoaiMcp -> kserve "Manages InferenceService and ServingRuntime resources" "CRD via K8s API"
        rhoaiMcp -> kubeflowNotebooks "Manages Notebook (workbench) resources" "CRD via K8s API"
        rhoaiMcp -> kubeflowTraining "Manages TrainJob and ClusterTrainingRuntime resources" "CRD via K8s API"
        rhoaiMcp -> dsPipelines "Manages DataSciencePipelinesApplication resources" "CRD via K8s API"
        rhoaiMcp -> rhoaiOperator "Reads DataScienceCluster, DSCInitialization for platform status" "CRD via K8s API"
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
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
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
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
