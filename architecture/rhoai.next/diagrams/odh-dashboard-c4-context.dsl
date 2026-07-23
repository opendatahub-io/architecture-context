workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, runs experiments"
        mlEngineer = person "ML Engineer" "Manages model serving, pipelines, and infrastructure"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform settings and user access"

        // The ODH Dashboard system
        odhDashboard = softwareSystem "ODH Dashboard" "Web dashboard providing the primary UI for Red Hat OpenShift AI" {
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination + RBAC authorization sidecar" "Go Sidecar" "Auth"
            dashboardFrontend = container "Dashboard Frontend" "React SPA with Module Federation shell" "TypeScript/React/PatternFly"
            dashboardBFF = container "Dashboard BFF" "Legacy Node.js BFF serving UI and proxying K8s API" "Node.js/Express"
            coreBFF = container "Core BFF" "Next-gen Go BFF replacing Node.js backend" "Go"
            dashboardOperator = container "Dashboard Operator" "Manages Dashboard CR lifecycle, module deployment, federation config" "Go/controller-runtime"
            genAIModule = container "Gen AI Module" "GenAI playground: chat, guardrails, OTel tracing, pgvector" "Go BFF + React"
            modelRegistryModule = container "Model Registry Module" "Browse and manage registered models and versions" "Go BFF + React"
            maasModule = container "MaaS Module" "Model-as-a-Service: external model endpoints, LLM configs" "Go BFF + React"
            mlflowModule = container "MLflow Module" "MLflow experiment tracking integration" "Go BFF + React"
            evalHubModule = container "Eval Hub Module" "TrustyAI model evaluation runs and metrics" "Go BFF + React"
            automlModule = container "AutoML Module" "Automated ML experiment creation and monitoring" "Go BFF + React"
            autoragModule = container "AutoRAG Module" "Automated RAG optimization workflows" "Go BFF + React"
            agentOpsModule = container "Agent Ops Module" "Agent sandbox management and MCP server discovery" "Go BFF + React"
        }

        // Internal ODH/RHOAI Systems
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator managing RHOAI component lifecycle" "Internal ODH"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (InferenceService, ServingRuntime)" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry Operator" "Stores and manages ML model metadata" "Internal ODH"
        notebooks = softwareSystem "Kubeflow Notebooks" "Notebook server lifecycle management" "Internal ODH"
        trustyAI = softwareSystem "TrustyAI" "ML model evaluation and fairness platform" "Internal ODH"
        mlflowOperator = softwareSystem "MLflow Operator" "MLflow experiment tracking server management" "Internal ODH"
        feast = softwareSystem "Feast" "Feature store for ML pipelines" "Internal ODH"
        nimOperator = softwareSystem "NIM Operator" "NVIDIA NIM model deployment management" "Internal ODH"
        agentOps = softwareSystem "Agent Ops" "AI agent sandbox and MCP server management" "Internal ODH"
        otelOperator = softwareSystem "OpenTelemetry Operator" "Distributed tracing infrastructure" "Internal ODH"
        perses = softwareSystem "Perses" "Observability dashboards (Cluster Observability Operator)" "Internal ODH"

        // External Systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Ingress gateway (data-science-gateway)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and query" "External"
        openShiftConsole = softwareSystem "OpenShift Console" "OpenShift web console (ConsoleLink integration)" "External"
        externalModels = softwareSystem "External Model Services" "MaaS endpoints, MLflow servers, LlamaStack" "External"

        // Relationships - People to Dashboard
        dataScientist -> odhDashboard "Creates notebooks, deploys models, runs experiments via" "HTTPS/443"
        mlEngineer -> odhDashboard "Manages model serving and pipelines via" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures platform settings via" "HTTPS/443"

        // Relationships - Dashboard internal
        kubeRbacProxy -> dashboardBFF "Forwards authenticated requests" "HTTP/8080"
        kubeRbacProxy -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"
        dashboardBFF -> dashboardFrontend "Serves SPA assets" "HTTP"
        dashboardBFF -> genAIModule "Proxies /gen-ai/api/*" "HTTPS/8143"
        dashboardBFF -> modelRegistryModule "Proxies /model-registry/api/*" "HTTPS/8043"
        dashboardBFF -> maasModule "Proxies /maas/api/*" "HTTPS/8243"
        dashboardBFF -> mlflowModule "Proxies /_bff/mlflow/api/*" "HTTPS/8343"
        dashboardBFF -> evalHubModule "Proxies /eval-hub/api/*" "HTTPS/8543"
        dashboardBFF -> automlModule "Proxies /automl/api/*" "HTTPS/8643"
        dashboardBFF -> autoragModule "Proxies /autorag/api/*" "HTTPS/8743"
        dashboardBFF -> agentOpsModule "Proxies /agent-ops/api/*" "HTTPS/8843"
        genAIModule -> maasModule "Model endpoint discovery" "HTTPS/8243"
        genAIModule -> mlflowModule "Experiment tracking" "HTTPS/8343"
        dashboardOperator -> odhDashboard "Deploys and manages" "K8s API"

        // Relationships - External
        gatewayAPI -> odhDashboard "Routes external traffic to dashboard" "HTTPS/8443"
        odhDashboard -> k8sAPI "Proxies K8s API requests with user impersonation" "HTTPS/6443"
        odhDashboard -> kserve "Manages InferenceServices and ServingRuntimes" "HTTPS/6443 via K8s API"
        odhDashboard -> modelRegistry "Manages model registry instances" "HTTPS/6443 via K8s API"
        odhDashboard -> notebooks "Manages notebook lifecycle" "HTTPS/6443 via K8s API"
        odhDashboard -> trustyAI "Integrates evaluation hub" "HTTPS/6443 via K8s API"
        odhDashboard -> mlflowOperator "Auto-discovers MLflow instances" "HTTPS/6443 via K8s API"
        odhDashboard -> feast "Discovers feature stores" "HTTPS/6443 via K8s API"
        odhDashboard -> nimOperator "NVIDIA NIM account integration" "HTTPS/6443 via K8s API"
        odhDashboard -> agentOps "Agent sandbox and MCP server discovery" "HTTPS/6443 via K8s API"
        odhDashboard -> otelOperator "Per-namespace OTel collector for LLM tracing" "HTTPS/6443 via K8s API"
        odhDashboard -> perses "Observability dashboard deployment and API proxy" "HTTP/8080"
        odhDashboard -> prometheus "Metrics query proxy" "HTTP/9090"
        odhDashboard -> externalModels "MaaS, MLflow, LlamaStack external calls" "HTTPS/443"
        rhodsOperator -> odhDashboard "Creates Dashboard CR" "K8s API"
        openShiftConsole -> odhDashboard "Links via ConsoleLink CR" "HTTPS"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Auth" {
                background #e74c3c
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
        }
    }
}
