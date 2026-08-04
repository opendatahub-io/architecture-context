workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML workloads through the RHOAI web console"
        admin = person "Platform Admin" "Configures and manages the RHOAI platform"

        odhDashboard = softwareSystem "ODH Dashboard" "Unified web console for Red Hat OpenShift AI with federated micro-frontend architecture" {
            operator = container "Dashboard Operator" "Reconciles Dashboard, Workspace, and WorkspaceKind CRs; manages deployment topology" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and converts Dashboard, Workspace, WorkspaceKind resources" "Go Admission Webhooks"
            nodeBackend = container "Fastify Backend" "Serves React SPA, proxies K8s API requests, routes to BFF sidecars" "Node.js (Fastify)"
            reactSPA = container "React SPA" "PatternFly-based single-page application with Webpack Module Federation" "React/TypeScript"
            genAiBff = container "gen-ai BFF" "GenAI domain API: LLM inference, MCP tool integration, vector stores" "Go BFF Sidecar (8143/TLS)"
            modelRegBff = container "model-registry BFF" "Model Registry domain API: model version management" "Go BFF Sidecar (8043/TLS)"
            maasBff = container "maas BFF" "MaaS domain API: API keys, models, subscriptions" "Go BFF Sidecar (8243/TLS)"
            mlflowBff = container "mlflow BFF" "MLflow domain API: experiment and prompt management" "Go BFF Sidecar (8343/TLS)"
            evalHubBff = container "eval-hub BFF" "Eval Hub domain API: model evaluation" "Go BFF Sidecar (8543/TLS)"
            automlBff = container "automl BFF" "AutoML domain API" "Go BFF Sidecar (8643/TLS)"
            autoragBff = container "autorag BFF" "AutoRAG domain API" "Go BFF Sidecar (8743/TLS)"
            agentOpsBff = container "agent-ops BFF" "Agent Ops domain API: agent lifecycle, per-agent RBAC" "Go BFF Sidecar (8843/TLS)"
        }

        rhodsOperator = softwareSystem "RHODS Operator" "Creates and owns the Dashboard custom resource" "Internal ODH"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster resource management, RBAC enforcement" "Infrastructure"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and version tracking" "Internal ODH"
        trustyAI = softwareSystem "TrustyAI" "Fairness and explainability services" "Internal ODH"
        mlflow = softwareSystem "MLflow" "Experiment tracking and prompt management" "Internal ODH"
        feast = softwareSystem "Feast" "Feature store management" "Internal ODH"
        dsPipelines = softwareSystem "DataScience Pipelines" "Pipeline execution and management" "Internal ODH"
        notebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workbenches" "Internal ODH"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "Infrastructure"
        prometheus = softwareSystem "Prometheus / Thanos" "Metrics collection and querying" "Infrastructure"
        llamaStack = softwareSystem "Llama Stack Server" "LLM inference, vector stores, and files" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool servers" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation" "External"

        # User interactions
        user -> odhDashboard "Manages ML workloads via web console" "HTTPS/443"
        admin -> odhDashboard "Configures platform via web console" "HTTPS/443"

        # Internal relationships
        reactSPA -> nodeBackend "Served by and API calls to" "HTTPS/8443"
        nodeBackend -> genAiBff "Routes gen-ai API requests" "TLS/8143"
        nodeBackend -> modelRegBff "Routes model-registry API requests" "TLS/8043"
        nodeBackend -> maasBff "Routes maas API requests" "TLS/8243"
        nodeBackend -> mlflowBff "Routes mlflow API requests" "TLS/8343"
        nodeBackend -> evalHubBff "Routes eval-hub API requests" "TLS/8543"
        nodeBackend -> automlBff "Routes automl API requests" "TLS/8643"
        nodeBackend -> autoragBff "Routes autorag API requests" "TLS/8743"
        nodeBackend -> agentOpsBff "Routes agent-ops API requests" "TLS/8843"
        operator -> webhookServer "Delegates validation" "HTTPS/9443"

        # External relationships
        rhodsOperator -> odhDashboard "Creates Dashboard CR" "Kubernetes API"
        odhDashboard -> kubernetesAPI "Resource CRUD, RBAC, impersonation" "HTTPS/6443"
        odhDashboard -> kserve "Reads InferenceService state" "HTTPS"
        odhDashboard -> modelRegistry "Manages model registries" "HTTPS/8443"
        odhDashboard -> trustyAI "Reads TrustyAI resources" "HTTPS/443"
        odhDashboard -> mlflow "Reads MLflow instances" "HTTPS"
        odhDashboard -> feast "Reads FeatureStore instances" "HTTPS"
        odhDashboard -> dsPipelines "Pipeline execution proxy" "HTTPS/8443"
        odhDashboard -> notebooks "Manages notebook workbenches" "HTTPS"
        odhDashboard -> certManager "TLS certificate provisioning" "Kubernetes API"
        odhDashboard -> prometheus "Metrics queries" "HTTPS/9092"
        genAiBff -> llamaStack "LLM inference requests" "HTTPS"
        genAiBff -> mcpServers "Tool discovery and invocation" "SSE/HTTP"
        genAiBff -> nemoGuardrails "Content moderation" "HTTPS"
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
            element "External" {
                background #f8cecc
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
