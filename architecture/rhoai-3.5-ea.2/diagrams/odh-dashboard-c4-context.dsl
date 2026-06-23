workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, runs pipelines, and manages ML workloads"
        platformAdmin = person "Platform Admin" "Configures dashboard features, manages platform settings"

        odhDashboard = softwareSystem "ODH Dashboard" "Unified web management console for Red Hat OpenShift AI / Open Data Hub" {
            frontend = container "React/PatternFly 6 SPA" "Module Federation host with dynamic plugin loading" "TypeScript, React 18, PatternFly 6, Webpack Module Federation"
            backend = container "Node.js/Fastify BFF" "Serves frontend, proxies K8s API, routes module federation requests to BFF sidecars" "Node.js 22, Fastify 4.29"
            kubeRbacProxy = container "kube-rbac-proxy" "Authenticates and authorizes requests via K8s TokenReview/SAR" "Go, 8443/TCP"
            modelRegistryBFF = container "model-registry BFF" "Proxies Model Registry REST API, Model Catalog API" "Go, 8043/TCP"
            genAiBFF = container "gen-ai BFF" "Proxies OGX, LlamaStack, MLflow, Guardrails" "Go, 8143/TCP"
            maasBFF = container "maas BFF" "Proxies MaaS Controllers, API Keys, Subscriptions" "Go, 8243/TCP"
            mlflowBFF = container "mlflow BFF" "Proxies MLflow API for prompt management" "Go, 8343/TCP"
            evalHubBFF = container "eval-hub BFF" "Proxies EvalHub REST API, InferenceServices" "Go, 8543/TCP"
            automlBFF = container "automl BFF" "Proxies Pipeline Server, S3, Model Registry" "Go, 8643/TCP"
            autoragBFF = container "autorag BFF" "Proxies OGX, Pipeline Server, S3" "Go, 8743/TCP"
            agentOpsBFF = container "agent-ops BFF" "Proxies K8s API for AgentRuntime CRs, MCP tools" "Go, 8843/TCP"
            dashboardOperator = container "dashboard-operator" "Reconciles Dashboard CR, deploys manifests via kustomize, manages module lifecycle" "Go, controller-runtime"
        }

        # Internal Platform Components
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that manages RHOAI component lifecycle" "Internal RHOAI"
        notebooksController = softwareSystem "Notebooks Controller" "Manages Jupyter notebook workbenches (kubeflow.org)" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform (serving.kserve.io)" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores and manages ML model artifacts and metadata" "Internal RHOAI"
        dspPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (Kubeflow Pipelines)" "Internal RHOAI"
        trustyAI = softwareSystem "TrustyAI" "AI fairness, explainability, and guardrails" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and prompt management" "Internal RHOAI"
        ogx = softwareSystem "OGX" "Open GenAI Stack server management" "Internal RHOAI"
        llamaStack = softwareSystem "LlamaStack" "LLM inference API" "Internal RHOAI"
        maasController = softwareSystem "MaaS Controller" "Model-as-a-Service management" "Internal RHOAI"
        evalHub = softwareSystem "EvalHub" "Model evaluation and benchmarking" "Internal RHOAI"
        perses = softwareSystem "Perses" "Observability dashboards" "Internal RHOAI"

        # External Systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for all resource operations" "External"
        platformGateway = softwareSystem "Platform Gateway" "Envoy-based ingress via Gateway API" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for data files" "External"
        segmentAnalytics = softwareSystem "Segment Analytics" "Usage telemetry collection" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "Platform web console with application launcher" "External"

        # Relationships - Users
        dataScientist -> odhDashboard "Manages notebooks, models, pipelines, and AI workloads via" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures dashboard features, manages platform settings via" "HTTPS/443"

        # Relationships - Internal containers
        frontend -> backend "API calls, module federation loading" "HTTP/8080"
        kubeRbacProxy -> backend "Proxies authenticated requests" "HTTP/8080 (localhost)"
        backend -> modelRegistryBFF "Routes /_mf/model-registry/*" "HTTPS/8043"
        backend -> genAiBFF "Routes /_mf/gen-ai/*" "HTTPS/8143"
        backend -> maasBFF "Routes /_mf/maas/*" "HTTPS/8243"
        backend -> mlflowBFF "Routes /_mf/mlflow/*" "HTTPS/8343"
        backend -> evalHubBFF "Routes /_mf/eval-hub/*" "HTTPS/8543"
        backend -> automlBFF "Routes /_mf/automl/*" "HTTPS/8643"
        backend -> autoragBFF "Routes /_mf/autorag/*" "HTTPS/8743"
        backend -> agentOpsBFF "Routes /_mf/agent-ops/*" "HTTPS/8843"
        genAiBFF -> maasBFF "Inter-BFF: model deployment status" "HTTPS/8243"

        # Relationships - Platform
        platformGateway -> odhDashboard "Routes external traffic via HTTPRoute" "HTTPS/8443"
        rhodsOperator -> odhDashboard "Creates Dashboard CR, projects component availability" "K8s API"
        dashboardOperator -> k8sAPI "Reconciles Dashboard CR, deploys manifests" "HTTPS/6443"

        # Relationships - Upstream services
        odhDashboard -> k8sAPI "All K8s resource CRUD, CRD watches, TokenReview, SAR" "HTTPS/6443"
        odhDashboard -> notebooksController "Notebook lifecycle management" "K8s API"
        odhDashboard -> kserve "InferenceService display, ServingRuntime management" "K8s API"
        odhDashboard -> modelRegistry "Model artifact CRUD, catalog browsing" "HTTP/8080"
        odhDashboard -> dspPipelines "Pipeline management and execution" "HTTPS"
        odhDashboard -> trustyAI "Fairness metrics, guardrails" "HTTPS/443"
        odhDashboard -> mlflow "Experiment tracking, prompt management" "HTTPS/8443"
        odhDashboard -> ogx "GenAI Stack server management" "HTTPS"
        odhDashboard -> llamaStack "LLM inference" "HTTP/8321"
        odhDashboard -> maasController "MaaS management" "HTTPS"
        odhDashboard -> evalHub "Model evaluation" "HTTPS"
        odhDashboard -> perses "Observability dashboards" "HTTP/8080"
        odhDashboard -> s3Storage "Data file browsing (automl, autorag)" "HTTPS/443"
        odhDashboard -> segmentAnalytics "Usage telemetry (optional)" "HTTPS/443"
        odhDashboard -> openshiftConsole "Application launcher link (ConsoleLink)" "K8s API"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
