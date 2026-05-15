workspace {
    model {
        // Personas
        dataScientist = person "Data Scientist" "Creates and manages AI/ML workloads, notebooks, and model deployments"
        mlEngineer = person "ML Engineer" "Builds and manages ML pipelines, model serving, and feature stores"
        platformAdmin = person "Platform Admin" "Administers platform settings, hardware profiles, RBAC, and connection types"

        // Main System
        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI providing unified UI for AI/ML workloads" {
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar injecting user identity headers" "Go Sidecar" "Auth"
            dashboardBackend = container "Dashboard Backend" "API gateway proxying K8s API calls, WebSocket watch streams, and downstream services; serves frontend assets" "Node.js Fastify"
            dashboardFrontend = container "Dashboard Frontend" "Host application with module federation, PatternFly UI, Redux state management" "React 18 SPA"
            genAiBff = container "Gen-AI BFF" "Proxies LlamaStack, MaaS, MLflow prompts, NeMo Guardrails, and MCP server interactions" "Go HTTP Server"
            maasBff = container "MaaS BFF" "Manages MaaS subscriptions, auth policies, API keys, model references, and tiers" "Go HTTP Server"
            modelRegistryBff = container "Model Registry BFF" "Proxies Model Registry and Model Catalog APIs; manages catalog sources and transfer jobs" "Go HTTP Server"
            automlBff = container "AutoML BFF" "Orchestrates AutoML pipeline runs with S3 data management and model registration" "Go HTTP Server"
            autoragBff = container "AutoRAG BFF" "Orchestrates AutoRAG pipeline runs with LlamaStack integration for RAG optimization" "Go HTTP Server"
            evalHubBff = container "Eval-Hub BFF" "Proxies EvalHub evaluation framework for model evaluation jobs" "Go HTTP Server"
            mlflowBff = container "MLflow BFF" "Proxies MLflow tracking server for experiment management" "Go HTTP Server"
        }

        // Internal Platform Systems
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD, RBAC, and watch streams" "Internal Platform"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration and management" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model registration, versioning, and artifact management" "Internal ODH"
        modelCatalog = softwareSystem "Model Catalog" "Model catalog browsing and MCP server catalog" "Internal ODH"
        trustyAI = softwareSystem "TrustyAI" "Model explainability, fairness, and bias analysis" "Internal ODH"
        llamaStack = softwareSystem "LlamaStack (OGXServer)" "LLM inference, embeddings, RAG, and vector stores" "Internal ODH"
        maasController = softwareSystem "MaaS Controller" "Model-as-a-Service management and API key issuance" "Internal ODH"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Input/output content moderation" "Internal ODH"
        mlflowServer = softwareSystem "MLflow Tracking Server" "Experiment tracking and prompt registry" "Internal ODH"
        evalHubServer = softwareSystem "EvalHub API" "Model evaluation framework" "Internal ODH"
        feast = softwareSystem "Feast Registry" "Feature store registry" "Internal ODH"
        notebookCtrl = softwareSystem "Notebook Controller" "Notebook/workbench lifecycle management" "Internal ODH"
        platformGateway = softwareSystem "Platform Gateway (Envoy)" "Ingress traffic routing via Gateway API" "Internal Platform"
        prometheus = softwareSystem "Prometheus / Thanos" "Metrics collection and querying" "Internal Platform"
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform status, component enablement" "Internal Platform"

        // External Systems
        s3 = softwareSystem "S3 Storage (AWS/MinIO)" "Object storage for data files" "External"
        mcpServers = softwareSystem "MCP Servers" "Tool definitions and function calling" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "OpenShift web console" "Internal Platform"

        // User relationships
        dataScientist -> odhDashboard "Manages notebooks, models, and pipelines via"
        mlEngineer -> odhDashboard "Deploys models, manages pipelines, and tracks experiments via"
        platformAdmin -> odhDashboard "Configures platform settings, RBAC, and hardware profiles via"

        // Internal container relationships
        platformGateway -> kubeRbacProxy "Routes traffic" "HTTPS/8443 TLS"
        kubeRbacProxy -> dashboardBackend "Injects identity" "HTTP/8080"
        dashboardBackend -> dashboardFrontend "Serves" "Static Assets"
        dashboardBackend -> genAiBff "Proxies" "HTTPS/8143"
        dashboardBackend -> maasBff "Proxies" "HTTPS/8243"
        dashboardBackend -> modelRegistryBff "Proxies" "HTTPS/8043"
        dashboardBackend -> automlBff "Proxies" "HTTPS/8643"
        dashboardBackend -> autoragBff "Proxies" "HTTPS/8743"
        dashboardBackend -> evalHubBff "Proxies" "HTTPS/8543"
        dashboardBackend -> mlflowBff "Proxies" "HTTPS/8343"
        genAiBff -> maasBff "Token delegation" "HTTPS/8243"

        // System-level relationships
        odhDashboard -> k8sApi "Resource CRUD, RBAC, watch streams" "HTTPS/443"
        odhDashboard -> kserve "Manages InferenceService, ServingRuntime CRDs" "HTTPS/443"
        odhDashboard -> dsPipelines "Pipeline management via DSPA CR" "HTTPS/dynamic"
        odhDashboard -> modelRegistry "Model registration and versioning" "HTTPS/8080"
        odhDashboard -> modelCatalog "Model catalog browsing" "HTTPS/8081"
        odhDashboard -> trustyAI "Bias and fairness analysis" "HTTPS/443"
        odhDashboard -> llamaStack "LLM inference, RAG, embeddings" "HTTPS/dynamic"
        odhDashboard -> maasController "MaaS subscriptions, API keys" "HTTPS/dynamic"
        odhDashboard -> nemoGuardrails "Content moderation" "HTTPS/dynamic"
        odhDashboard -> mlflowServer "Experiment tracking, prompts" "HTTPS/dynamic"
        odhDashboard -> evalHubServer "Model evaluation" "HTTPS/dynamic"
        odhDashboard -> feast "Feature store management" "HTTPS/8443"
        odhDashboard -> prometheus "Metrics queries" "HTTPS/443"
        odhDashboard -> notebookCtrl "Notebook lifecycle" "HTTPS/443"
        odhDashboard -> rhodsOperator "Platform status via CRD watch" "HTTPS/443"
        odhDashboard -> s3 "Data file upload/download" "HTTPS/443"
        odhDashboard -> mcpServers "Tool definitions, function calling" "HTTP/HTTPS"
        odhDashboard -> openshiftConsole "ConsoleLink integration" "CRD"
    }

    views {
        systemContext odhDashboard "SystemContext" {
            include *
            autoLayout
        }

        container odhDashboard "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Auth" {
                background #e74c3c
                color #ffffff
            }
        }
    }
}
