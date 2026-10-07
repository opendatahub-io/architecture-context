workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, manages experiments and notebooks"
        admin = person "Platform Admin" "Configures and manages the RHOAI platform"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI" {
            frontend = container "React SPA" "PatternFly 6 UI for ML/AI workload management" "TypeScript / React"
            nodeBackend = container "Node.js Backend" "API proxy and SPA server using Fastify" "Node.js / TypeScript"
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination and OpenShift auth enforcement" "Go Sidecar"
            coreBff = container "Core BFF" "Core backend-for-frontend APIs" "Go Service"
            dashboardOperator = container "Dashboard Operator" "Manages deployment lifecycle of all dashboard components" "Go controller-runtime Operator"
            workspaceController = container "Workspace Controller" "Reconciles Kubeflow Workspace and WorkspaceKind resources" "Go Controller"

            genAiBff = container "Gen AI BFF" "LLM features backend (Llama Stack, MCP, NeMo)" "Go BFF + React Module"
            modelRegBff = container "Model Registry BFF" "Model Registry UI backend" "Go BFF + React Module"
            maasBff = container "MaaS BFF" "Model-as-a-Service backend" "Go BFF + React Module"
            evalHubBff = container "Eval Hub BFF" "Evaluation Hub backend (TrustyAI)" "Go BFF + React Module"
            mlflowBff = container "MLflow BFF" "MLflow experiment tracking backend" "Go BFF + React Module"
            notebooksBff = container "Notebooks BFF" "Kubeflow Workspaces notebook management" "Go BFF + React Module"
            agentOpsBff = container "Agent Ops BFF" "Agent operations backend" "Go BFF + React Module"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that creates Dashboard CR" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versions" "Internal RHOAI"
        dsPipelines = softwareSystem "DataScience Pipelines" "ML pipeline execution engine" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "Fairness and explainability services" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workspace management" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store for ML" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking server" "Internal RHOAI"

        gatewayApi = softwareSystem "Gateway API" "Platform ingress via data-science-gateway" "Infrastructure"
        istio = softwareSystem "Service Mesh" "Istio-based service mesh" "Infrastructure"
        prometheus = softwareSystem "Prometheus / Thanos" "Monitoring and metrics" "Infrastructure"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "Infrastructure"
        kubeApi = softwareSystem "Kubernetes API" "Cluster API server" "Infrastructure"

        llamaStack = softwareSystem "Llama Stack" "LLM inference, vector stores, and files" "External"
        maasApi = softwareSystem "MaaS API Server" "Model-as-a-Service API" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool servers" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation" "External"

        dataScientist -> odhDashboard "Manages experiments, models, notebooks via browser" "HTTPS/443"
        admin -> odhDashboard "Configures platform, manages resources" "HTTPS/443"

        odhDashboard -> kubeApi "CRUD Kubernetes resources" "HTTPS/6443"
        odhDashboard -> rhodsOperator "Dashboard CR lifecycle" "CRD Watch"
        odhDashboard -> kserve "Manage InferenceServices" "HTTPS/6443 CRD CRUD"
        odhDashboard -> modelRegistry "Manage model versions" "HTTPS/8443"
        odhDashboard -> dsPipelines "Execute and manage pipelines" "HTTPS/8443"
        odhDashboard -> trustyai "Fairness and explainability" "HTTPS/443"
        odhDashboard -> kubeflowNotebooks "Create and manage workspaces" "HTTPS/6443 CRD CRUD"
        odhDashboard -> feast "Read feature store instances" "HTTPS/6443 CRD Watch"
        odhDashboard -> mlflow "Experiment and prompt tracking" "HTTPS"
        odhDashboard -> gatewayApi "Platform ingress routing" "HTTPRoute CRUD"
        odhDashboard -> prometheus "Metrics queries" "HTTPS/9092"
        odhDashboard -> certManager "Webhook TLS certificates" "Certificate CR"
        odhDashboard -> llamaStack "LLM inference and vector stores" "HTTPS"
        odhDashboard -> maasApi "API keys, models, subscriptions" "HTTPS"
        odhDashboard -> mcpServers "Tool discovery and invocation" "SSE/HTTP"
        odhDashboard -> nemoGuardrails "Content moderation" "HTTPS"
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
                background #1168bd
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
            element "Infrastructure" {
                background #999999
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
