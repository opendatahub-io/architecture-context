workspace {
    model {
        datascientist = person "Data Scientist" "Creates projects, deploys models, runs experiments, builds AI agents"
        mlops = person "MLOps Engineer" "Manages model serving, pipelines, and platform configuration"
        admin = person "Platform Admin" "Configures dashboard features, manages user access, platform settings"

        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI web console — unified UI for data science projects, model serving, notebooks, pipelines, and generative AI" {
            frontend = container "React Frontend" "PatternFly 6 shell application with Webpack Module Federation" "TypeScript/React"
            legacyBackend = container "Legacy Backend" "Monolithic BFF — K8s API proxy, WebSocket watches, auth, static file serving" "Node.js/Fastify"
            kubeRbacProxy = container "kube-rbac-proxy" "OAuth token validation sidecar, header injection" "Go Sidecar"
            coreBff = container "core-bff" "Next-gen core BFF for base dashboard features" "Go"
            genAiBff = container "gen-ai BFF" "LLM playground, RAG, guardrails, MCP integration" "Go"
            maasBff = container "maas BFF" "Managed model deployment, gateway-backed inference" "Go"
            modelRegBff = container "model-registry BFF" "Model catalog browsing, registration, versioning" "Go"
            mlflowBff = container "mlflow BFF" "MLflow experiment tracking UI" "Go"
            evalHubBff = container "eval-hub BFF" "LM evaluation jobs and results" "Go"
            automlBff = container "automl BFF" "Automated tabular/time-series ML pipelines" "Go"
            autoragBff = container "autorag BFF" "Automated RAG optimization pipelines" "Go"
            agentOpsBff = container "agent-ops BFF" "AI agent lifecycle management" "Go"
            dashboardOperator = container "Dashboard Operator" "Reconciles Dashboard CR, manages module deployment lifecycle" "Go/controller-runtime"
        }

        # Platform components (Internal RHOAI)
        rhodsOperator = softwareSystem "RHOAI Operator" "Creates Dashboard CR, manages platform lifecycle" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes API Server" "Resource CRUD, RBAC, watch" "Platform"
        kserve = softwareSystem "KServe" "Model serving with InferenceService" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model catalog and versioning" "Internal RHOAI"
        kfPipelines = softwareSystem "Kubeflow Pipelines" "ML workflow orchestration" "Internal RHOAI"
        mlflowServer = softwareSystem "MLflow Tracking Server" "Experiment and run tracking" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "Bias and explainability metrics" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queue management" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store management" "Internal RHOAI"

        # External services
        llamaStack = softwareSystem "Llama Stack" "LLM inference and agent runtime" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation and safety guardrails" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for models, data, artifacts" "External"
        openaiApi = softwareSystem "OpenAI API" "Fallback LLM provider" "External"
        ogx = softwareSystem "OGX" "Open GenAI Stack — RAG optimization orchestration" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool servers" "External"
        thanosQuerier = softwareSystem "Thanos Querier" "Prometheus metrics" "Platform"
        platformGateway = softwareSystem "Platform Gateway" "Envoy-based ingress routing" "Platform"

        # Relationships - Users
        datascientist -> odhDashboard "Creates projects, deploys models, runs experiments via" "HTTPS/443"
        mlops -> odhDashboard "Manages serving endpoints, monitors pipelines via" "HTTPS/443"
        admin -> odhDashboard "Configures features, manages access via" "HTTPS/443"

        # Relationships - Internal containers
        frontend -> legacyBackend "Served by and API calls to" "HTTP/8080"
        kubeRbacProxy -> legacyBackend "Forwards authenticated requests" "HTTP/8080"
        legacyBackend -> genAiBff "Proxies /gen-ai/api requests" "HTTPS/8143"
        legacyBackend -> maasBff "Proxies /maas/api requests" "HTTPS/8243"
        legacyBackend -> modelRegBff "Proxies /model-registry/api requests" "HTTPS/8043"
        legacyBackend -> mlflowBff "Proxies /_bff/mlflow/api requests" "HTTPS/8343"
        legacyBackend -> evalHubBff "Proxies /eval-hub/api requests" "HTTPS/8543"
        legacyBackend -> automlBff "Proxies /automl/api requests" "HTTPS/8643"
        legacyBackend -> autoragBff "Proxies /autorag/api requests" "HTTPS/8743"
        legacyBackend -> agentOpsBff "Proxies /agent-ops/api requests" "HTTPS/8843"
        genAiBff -> maasBff "Inter-BFF: model catalog queries" "HTTPS/8243"
        genAiBff -> mlflowBff "Inter-BFF: experiment tracking" "HTTPS/8343"
        evalHubBff -> modelRegBff "Inter-BFF: model lookups" "HTTPS/8043"
        dashboardOperator -> k8sApi "Reconciles Dashboard CR, deploys modules" "HTTPS/6443"

        # Relationships - External dependencies
        odhDashboard -> k8sApi "All K8s resource operations" "HTTPS/6443"
        odhDashboard -> platformGateway "Exposed via HTTPRoute" "HTTPS/443"
        platformGateway -> kubeRbacProxy "Routes traffic to dashboard" "HTTPS/8443"
        rhodsOperator -> odhDashboard "Creates Dashboard CR" "CRD"
        odhDashboard -> kserve "Watches InferenceService CRs" "CRD Watch"
        odhDashboard -> modelRegistry "Model catalog CRUD" "HTTP/8080"
        odhDashboard -> kfPipelines "Pipeline execution" "HTTPS"
        odhDashboard -> mlflowServer "Experiment tracking" "HTTPS"
        odhDashboard -> trustyai "Bias metrics" "HTTP/8080"
        odhDashboard -> kueue "Workload queue status" "CRD Watch"
        odhDashboard -> feast "Feature store status" "CRD Watch"
        odhDashboard -> thanosQuerier "Prometheus metrics" "HTTPS/9092"
        genAiBff -> llamaStack "LLM inference" "HTTPS/443"
        genAiBff -> nemoGuardrails "Content moderation" "HTTPS/443"
        genAiBff -> openaiApi "Fallback LLM" "HTTPS/443"
        genAiBff -> mcpServers "MCP tools" "HTTPS"
        automlBff -> s3Storage "Data source access" "HTTPS/443"
        automlBff -> kfPipelines "Pipeline execution" "HTTPS"
        autoragBff -> ogx "RAG optimization" "HTTPS/443"
        autoragBff -> s3Storage "Document source access" "HTTPS/443"
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
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
