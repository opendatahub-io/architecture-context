workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, tracks experiments"
        mlEngineer = person "ML Engineer" "Manages model serving, pipelines, and model registry"
        platformAdmin = person "Platform Admin" "Configures the AI platform and manages resources"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI" {
            frontend = container "React Frontend" "PatternFly SPA with Webpack Module Federation host loading domain-specific UI modules" "React/TypeScript"
            nodeBackend = container "Node.js Backend" "Fastify server serving static assets, proxying K8s API calls via user impersonation" "Node.js/Fastify"
            kubeRbacProxy = container "kube-rbac-proxy" "Auth proxy validating OpenShift OAuth tokens and injecting identity headers" "Go"
            dashOperator = container "Dashboard Operator" "Reconciles Dashboard CRs, manages console deployment lifecycle, RBAC, routes, sidecars" "Go/controller-runtime"
            workspaceController = container "Workspace Controller" "Reconciles Workspace and WorkspaceKind CRs with webhooks" "Go/controller-runtime"

            genAiBff = container "gen-ai BFF" "Backend-for-frontend for generative AI operations (Llama Stack, MCP, NeMo)" "Go" "BFF Sidecar"
            modelRegBff = container "model-registry BFF" "Backend-for-frontend for model registry operations" "Go" "BFF Sidecar"
            evalHubBff = container "eval-hub BFF" "Backend-for-frontend for evaluation hub operations" "Go" "BFF Sidecar"
            agentOpsBff = container "agent-ops BFF" "Backend-for-frontend for agent operations with per-agent RBAC" "Go" "BFF Sidecar"
            maasBff = container "maas BFF" "Backend-for-frontend for model-as-a-service operations" "Go" "BFF Sidecar"
            mlflowBff = container "mlflow BFF" "Backend-for-frontend for MLflow experiment tracking" "Go" "BFF Sidecar"
            automlBff = container "automl BFF" "Backend-for-frontend for AutoML operations" "Go" "BFF Sidecar"
            autoragBff = container "autorag BFF" "Backend-for-frontend for AutoRAG operations" "Go" "BFF Sidecar"
            coreBff = container "core-bff" "Core dashboard backend-for-frontend API" "Go" "BFF Sidecar"
        }

        k8sApi = softwareSystem "Kubernetes API" "OpenShift/Kubernetes API server for cluster resource management" "External"
        rhodsOperator = softwareSystem "RHODS Operator" "Creates and manages Dashboard custom resources" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform for ML inference" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versions" "Internal RHOAI"
        dsPipelines = softwareSystem "DataScience Pipelines" "Pipeline execution and management" "Internal RHOAI"
        trustyAI = softwareSystem "TrustyAI" "Fairness and explainability services" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking and prompt management" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store management" "Internal RHOAI"
        llamaStack = softwareSystem "Llama Stack" "LLM inference, vector stores, and file management" "External"
        maasApi = softwareSystem "MaaS API" "Model-as-a-Service API for model subscriptions" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation for AI applications" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol servers for tool discovery" "External"
        prometheus = softwareSystem "Prometheus/Thanos" "Metrics collection and querying" "Internal"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"

        # User interactions
        dataScientist -> odhDashboard "Creates notebooks, tracks experiments, deploys models via" "HTTPS/443"
        mlEngineer -> odhDashboard "Manages model serving, model registry, pipelines via" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures platform, manages resources via" "HTTPS/443"

        # Internal container flows
        kubeRbacProxy -> nodeBackend "Forwards authenticated requests" "HTTP/8080"
        nodeBackend -> genAiBff "Routes /gen-ai/api/*" "HTTPS/8143"
        nodeBackend -> modelRegBff "Routes /model-registry/api/*" "HTTPS/8043"
        nodeBackend -> evalHubBff "Routes /eval-hub/api/*" "HTTPS/8543"
        nodeBackend -> agentOpsBff "Routes /agent-ops/api/*" "HTTPS/8843"
        nodeBackend -> maasBff "Routes /maas/api/*" "HTTPS/8243"
        nodeBackend -> mlflowBff "Routes /mlflow/api/*" "HTTPS/8343"
        nodeBackend -> automlBff "Routes /automl/api/*" "HTTPS/8643"
        nodeBackend -> autoragBff "Routes /autorag/api/*" "HTTPS/8743"

        # External dependencies
        odhDashboard -> k8sApi "CRUD operations, watch, impersonation" "HTTPS/6443"
        rhodsOperator -> odhDashboard "Creates Dashboard CR" "Kubernetes API"
        odhDashboard -> kserve "Reads InferenceService state" "HTTPS"
        odhDashboard -> modelRegistry "Manages model versions" "HTTPS/8443"
        odhDashboard -> dsPipelines "Pipeline execution" "HTTPS/8443"
        odhDashboard -> trustyAI "Fairness and explainability" "HTTPS/443"
        odhDashboard -> mlflow "Experiment tracking" "HTTPS"
        odhDashboard -> feast "Reads feature store state" "Kubernetes API"
        odhDashboard -> llamaStack "LLM inference" "HTTPS"
        odhDashboard -> maasApi "Model subscriptions" "HTTPS"
        odhDashboard -> nemoGuardrails "Content moderation" "HTTPS"
        odhDashboard -> mcpServers "Tool discovery" "SSE/HTTP"
        odhDashboard -> prometheus "Metrics queries" "HTTPS/9092"
        certManager -> odhDashboard "Provisions TLS certificates" "Kubernetes API"
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
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "BFF Sidecar" {
                background #3498db
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
