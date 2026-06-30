workspace {
    model {
        datascientist = person "Data Scientist" "Creates notebooks, deploys models, runs experiments"
        mlops = person "MLOps Engineer" "Manages ML pipelines, model registry, serving infrastructure"
        admin = person "Platform Admin" "Configures cluster settings, manages user access"

        odhDashboard = softwareSystem "ODH Dashboard" "Unified web UI and API gateway for Red Hat OpenShift AI" {
            frontend = container "React SPA" "PatternFly 6 UI with Module Federation host" "TypeScript/React"
            backend = container "Node.js Backend" "Fastify API proxy, K8s pass-through, WebSocket relay, static serving" "Node.js 22"
            kubeRbacProxy = container "kube-rbac-proxy" "TLS-terminating authentication sidecar, enforces OpenShift project list access" "Go"
            genAiBff = container "gen-ai BFF" "LlamaStack integration, chatbot, prompts, vector stores, MCP tools, agent profiles" "Go"
            maasBff = container "maas BFF" "API key management, model subscriptions, policies" "Go"
            modelRegistryBff = container "model-registry BFF" "Model catalog browsing, version management" "Go"
            mlflowBff = container "mlflow BFF" "Experiment tracking, run management" "Go"
            evalHubBff = container "eval-hub BFF" "TrustyAI evaluation management" "Go"
            automlBff = container "automl BFF" "AutoML pipeline creation and management" "Go"
            autoragBff = container "autorag BFF" "AutoRAG pipeline creation and management" "Go"
            agentOpsBff = container "agent-ops BFF" "Agent runtime monitoring and management" "Go"
            dashboardOperator = container "Dashboard Operator" "Manages Dashboard CR lifecycle, module enablement, kustomize rendering" "Go Operator"
            pluginCore = container "plugin-core" "Shared plugin SDK: extension points, PluginStore, navigation/route APIs" "TypeScript Library"
        }

        gatewayApi = softwareSystem "Gateway API" "data-science-gateway for external ingress" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource operations" "External"
        rhodsOperator = softwareSystem "RHOAI Operator" "Deploys and manages Dashboard CR lifecycle" "Internal Platform"
        dspApi = softwareSystem "DataScience Pipelines" "Pipeline execution and management" "Internal Platform"
        modelRegistryApi = softwareSystem "Model Registry" "Model version tracking and catalog" "Internal Platform"
        kserve = softwareSystem "KServe" "Model serving and inference" "Internal Platform"
        mlmd = softwareSystem "ML Metadata" "Artifact and execution tracking" "Internal Platform"
        trustyai = softwareSystem "TrustyAI" "AI fairness, explainability, and evaluation" "Internal Platform"
        llamaStack = softwareSystem "LlamaStack Server" "LLM inference, vector stores, file management" "External"
        maasApi = softwareSystem "MaaS API Server" "Model-as-a-Service API keys and subscriptions" "External"
        mlflowServer = softwareSystem "MLflow Tracking" "Experiment and prompt management" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation" "External"
        prometheus = softwareSystem "Prometheus/Thanos" "Metrics queries" "Internal Platform"
        perses = softwareSystem "Perses" "Observability dashboards" "Internal Platform"
        mcpServers = softwareSystem "MCP Servers" "Tool discovery for AI agents" "External"

        # User interactions
        datascientist -> odhDashboard "Uses dashboard for notebooks, model serving, experiments" "HTTPS/443"
        mlops -> odhDashboard "Manages pipelines, model registry, AutoML" "HTTPS/443"
        admin -> odhDashboard "Configures cluster settings, manages access" "HTTPS/443"

        # External ingress
        gatewayApi -> kubeRbacProxy "Routes external traffic" "HTTPS/8443 TLS"
        kubeRbacProxy -> backend "Forwards authenticated requests" "HTTP/8080"
        backend -> frontend "Serves SPA and module federation remotes"

        # Backend to BFF sidecars
        backend -> genAiBff "Proxies gen-ai requests" "HTTPS/8143 TLS"
        backend -> maasBff "Proxies MaaS requests" "HTTPS/8243 TLS"
        backend -> modelRegistryBff "Proxies model registry requests" "HTTPS/8043 TLS"
        backend -> mlflowBff "Proxies MLflow requests" "HTTPS/8343 TLS"
        backend -> evalHubBff "Proxies eval-hub requests" "HTTPS/8543 TLS"
        backend -> automlBff "Proxies AutoML requests" "HTTPS/8643 TLS"
        backend -> autoragBff "Proxies AutoRAG requests" "HTTPS/8743 TLS"
        backend -> agentOpsBff "Proxies agent-ops requests" "HTTPS/8843 TLS"

        # Inter-BFF
        genAiBff -> maasBff "Token management" "HTTPS/8243 TLS"

        # Operator
        rhodsOperator -> odhDashboard "Creates Dashboard CR" "K8s API"
        dashboardOperator -> k8sApi "Reconciles Dashboard, deploys manifests" "HTTPS/6443"

        # Backend upstream
        backend -> k8sApi "K8s resource CRUD, impersonation, WebSocket watch" "HTTPS/6443"
        backend -> dspApi "Pipeline management proxy" "HTTPS/8443"
        backend -> modelRegistryApi "Model registry proxy" "HTTPS/8443"
        backend -> kserve "Model serving proxy" "HTTPS"
        backend -> mlmd "Artifact tracking proxy" "gRPC-web/8443"
        backend -> trustyai "Fairness metrics proxy" "HTTPS"
        backend -> prometheus "Metrics queries" "HTTPS/9091"
        backend -> perses "Observability dashboards" "HTTP/8080"

        # BFF upstream
        genAiBff -> llamaStack "LLM inference, vector stores" "HTTPS"
        genAiBff -> mlflowServer "Prompt registry" "HTTPS"
        genAiBff -> nemoGuardrails "Content moderation" "HTTPS"
        genAiBff -> mcpServers "Tool discovery" "Stdio/HTTP"
        genAiBff -> k8sApi "Resource operations" "HTTPS/6443"
        maasBff -> maasApi "API keys, models, subscriptions" "HTTPS"
        maasBff -> k8sApi "Resource operations" "HTTPS/6443"
        agentOpsBff -> k8sApi "Agent resource queries with SSAR" "HTTPS/6443"

        # Plugin
        frontend -> pluginCore "Uses extension point APIs"
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
            element "Internal Platform" {
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
