workspace {
    model {
        user = person "Data Scientist" "Creates notebooks, deploys models, manages ML workflows"
        admin = person "Platform Admin" "Configures platform settings, manages hardware profiles"

        odhDashboard = softwareSystem "ODH Dashboard" "Unified web UI and API gateway for RHOAI platform management" {
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination and OpenShift authentication enforcement" "Go Sidecar" "Auth Proxy"
            nodejsBackend = container "Node.js Backend" "API proxy, static asset server, CRD-based service discovery" "Fastify 4.29"
            reactFrontend = container "React Frontend" "Module federation host app with PatternFly 6 UI" "React 18.3 / TypeScript"
            coreBff = container "Core BFF" "Core dashboard backend-for-frontend API" "Go BFF"
            genAiBff = container "Gen-AI BFF" "Generative AI workflows, LLM inference, guardrails" "Go BFF"
            maasBff = container "MaaS BFF" "Model-as-a-Service API keys, models, subscriptions" "Go BFF"
            mlflowBff = container "MLflow BFF" "Experiment and prompt management" "Go BFF"
            evalHubBff = container "Eval-Hub BFF" "Model evaluation workflows" "Go BFF"
            automlBff = container "AutoML BFF" "Automated machine learning workflows" "Go BFF"
            autoragBff = container "AutoRAG BFF" "Automated RAG pipeline workflows" "Go BFF"
            agentOpsBff = container "Agent-Ops BFF" "Agent orchestration and sandbox management" "Go BFF"
            dashboardOperator = container "Dashboard Operator" "Reconciles Dashboard CR, manages deployment lifecycle" "Go Operator (controller-runtime)"
            workspaceController = container "Workspace Controller" "Reconciles Workspace and WorkspaceKind CRs" "Go Controller"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster resource management and RBAC enforcement" "Infrastructure"
        gatewayApi = softwareSystem "Gateway API" "Platform ingress and traffic routing" "Infrastructure"
        dsPipelines = softwareSystem "DataScience Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model version tracking and metadata" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving (KServe)" "Serverless ML inference platform" "Internal RHOAI"
        mlMetadata = softwareSystem "ML Metadata (MLMD)" "Artifact and execution tracking" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "Fairness, explainability, and evaluation" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workbenches" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store management" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model management" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / Thanos" "Metrics and monitoring" "Internal RHOAI"
        perses = softwareSystem "Perses" "Observability dashboards" "Internal RHOAI"
        llamaStack = softwareSystem "Llama Stack Server" "LLM inference and vector stores" "External"
        maasApi = softwareSystem "MaaS API Server" "Model-as-a-Service platform" "External"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation and safety" "External"
        rhodsOperator = softwareSystem "RHODS Operator" "Creates and owns Dashboard custom resource" "Internal RHOAI"

        user -> odhDashboard "Accesses via browser" "HTTPS/8443"
        admin -> odhDashboard "Configures platform settings" "HTTPS/8443"
        odhDashboard -> k8sApi "Resource CRUD, watches, RBAC" "HTTPS/6443"
        odhDashboard -> gatewayApi "Ingress routing" "HTTPRoute"
        odhDashboard -> dsPipelines "Pipeline execution proxy" "HTTPS/8443"
        odhDashboard -> modelRegistry "Model version tracking proxy" "HTTPS/8443"
        odhDashboard -> modelServing "Inference service management" "HTTPS"
        odhDashboard -> mlMetadata "Artifact tracking proxy" "gRPC-web/8443"
        odhDashboard -> trustyai "Fairness and explainability" "HTTPS/443"
        odhDashboard -> kubeflowNotebooks "Notebook management" "CRD CRUD"
        odhDashboard -> feast "Feature store status" "CRD Watch"
        odhDashboard -> mlflow "Experiment tracking" "CRD Watch + REST"
        odhDashboard -> prometheus "Metrics queries" "HTTPS/9092"
        odhDashboard -> perses "Observability dashboards" "HTTP/8080"
        odhDashboard -> llamaStack "LLM inference" "HTTPS"
        odhDashboard -> maasApi "MaaS management" "HTTPS"
        odhDashboard -> nemoGuardrails "Content moderation" "HTTPS"
        rhodsOperator -> odhDashboard "Creates Dashboard CR" "CRD"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #e74c3c
                color #ffffff
            }
            element "Auth Proxy" {
                background #e8a838
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}
