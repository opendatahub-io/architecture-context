workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML models, notebooks, pipelines, and experiments"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform features, manages user access"

        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI web console for managing data science projects, model serving, notebooks, pipelines, and AI/ML platform features" {
            frontend = container "React Frontend" "PatternFly 6 SPA with Module Federation — host application shell loading feature-specific micro-frontends" "TypeScript/React"
            backend = container "Fastify Backend" "Primary BFF — serves frontend static assets, proxies K8s API, manages WebSocket connections, routes to upstream services" "Node.js/Fastify"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication/authorization sidecar enforcing OpenShift RBAC before forwarding to backend" "Go"
            dashboardOperator = container "Dashboard Operator" "Manages Dashboard CR lifecycle, renders kustomize manifests, resolves module dependencies" "Go/controller-runtime"

            genAiBFF = container "gen-ai BFF" "GenAI Studio API proxy — LlamaStack, MaaS tokens, MLflow prompts, NeMo guardrails, MCP tools, agent profiles" "Go HTTP Server" "Sidecar 8143/TCP"
            modelRegistryBFF = container "model-registry BFF" "Model Registry API proxy — registered models, catalog, MCP servers, transfer jobs" "Go HTTP Server" "Sidecar 8043/TCP"
            maasBFF = container "maas BFF" "MaaS API proxy — API keys, subscriptions, policies, model references" "Go HTTP Server" "Sidecar 8243/TCP"
            mlflowBFF = container "mlflow BFF" "MLflow API proxy — experiments, prompts, tracking status" "Go HTTP Server" "Sidecar 8343/TCP"
            evalHubBFF = container "eval-hub BFF" "Evaluation Hub API proxy — evaluation jobs, benchmark collections" "Go HTTP Server" "Sidecar 8543/TCP"
            automlBFF = container "automl BFF" "AutoML API proxy — pipeline runs, S3 artifacts, model registration" "Go HTTP Server" "Sidecar 8643/TCP"
            autoragBFF = container "autorag BFF" "AutoRAG API proxy — RAG pipeline runs, OGX models/vector stores" "Go HTTP Server" "Sidecar 8743/TCP"
            agentOpsBFF = container "agent-ops BFF" "Agent Operations API proxy — AgentRuntime CRs, agent deployments" "Go HTTP Server" "Sidecar 8843/TCP"
        }

        # Platform Dependencies
        k8sAPI = softwareSystem "Kubernetes API" "OpenShift Kubernetes API Server" "External"
        rhodsOperator = softwareSystem "RHODS Operator" "Creates and manages Dashboard CR, projects component availability" "Internal RHOAI"
        gateway = softwareSystem "OpenShift Gateway" "HTTPRoute-based ingress for external access" "External"

        # Data Science Services
        dsPipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflow orchestration" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and artifacts" "Internal RHOAI"
        trustyAI = softwareSystem "TrustyAI" "Bias monitoring and model explainability" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML model serving platform" "Internal RHOAI"
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook lifecycle management" "Internal RHOAI"

        # AI/ML Services
        llamaStack = softwareSystem "LlamaStack" "GenAI inference, RAG, and file management" "AI Service"
        maasGateway = softwareSystem "MaaS Gateway" "Model-as-a-Service API for managed models" "AI Service"
        mlflowServer = softwareSystem "MLflow Tracking" "Experiment tracking and prompt management" "AI Service"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation for GenAI" "AI Service"
        ogx = softwareSystem "OGX" "Open GenAI Stack — models and vector stores" "AI Service"
        evalHubAPI = softwareSystem "EvalHub" "LM evaluation and benchmarking" "AI Service"
        feastRegistry = softwareSystem "Feast Registry" "Feature store management" "AI Service"

        # Monitoring
        thanosQuerier = softwareSystem "Thanos Querier" "Prometheus metrics aggregation and querying" "External"

        # External Services
        s3 = softwareSystem "AWS S3 / MinIO" "Object storage for ML artifacts and documents" "External"

        # Relationships - Users
        dataScientist -> odhDashboard "Manages ML projects, deploys models, runs pipelines via" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures platform features, manages access via" "HTTPS/443"

        # Relationships - Internal container
        dataScientist -> frontend "Interacts with" "HTTPS"
        frontend -> backend "API calls" "HTTP/8080"
        gateway -> kubeRbacProxy "Routes external traffic" "HTTPS/8443"
        kubeRbacProxy -> backend "Forwards authenticated requests" "HTTP/8080"
        kubeRbacProxy -> k8sAPI "SubjectAccessReview" "HTTPS/6443"
        backend -> genAiBFF "Proxies GenAI API" "HTTPS/8143"
        backend -> modelRegistryBFF "Proxies Model Registry API" "HTTPS/8043"
        backend -> maasBFF "Proxies MaaS API" "HTTPS/8243"
        backend -> mlflowBFF "Proxies MLflow API" "HTTPS/8343"
        backend -> evalHubBFF "Proxies EvalHub API" "HTTPS/8543"
        backend -> automlBFF "Proxies AutoML API" "HTTPS/8643"
        backend -> autoragBFF "Proxies AutoRAG API" "HTTPS/8743"
        backend -> agentOpsBFF "Proxies Agent Ops API" "HTTPS/8843"
        genAiBFF -> maasBFF "Token management" "HTTPS/8243"

        # Relationships - Platform
        rhodsOperator -> odhDashboard "Creates Dashboard CR, projects availability"
        dashboardOperator -> k8sAPI "Reconciles Dashboard CR" "HTTPS/6443"
        backend -> k8sAPI "All K8s resource operations" "HTTPS/6443"

        # Relationships - Data Science
        backend -> dsPipelines "Pipeline CRUD" "HTTPS/8443"
        backend -> modelRegistry "Model CRUD" "HTTP/8080"
        backend -> trustyAI "Bias monitoring" "HTTPS/443"
        backend -> thanosQuerier "Prometheus metrics" "HTTPS/443"
        backend -> feastRegistry "Feature store" "HTTPS"

        # Relationships - AI/ML BFF egress
        genAiBFF -> llamaStack "GenAI inference" "HTTPS/443"
        genAiBFF -> nemoGuardrails "Content moderation" "HTTPS/443"
        genAiBFF -> mlflowServer "Prompt tracking" "HTTPS/443"
        maasBFF -> maasGateway "Model-as-a-Service" "HTTPS/443"
        mlflowBFF -> mlflowServer "Experiment tracking" "HTTPS/443"
        evalHubBFF -> evalHubAPI "Evaluation jobs" "HTTPS/443"
        automlBFF -> dsPipelines "Pipeline runs" "HTTPS/8443"
        automlBFF -> s3 "Artifact storage" "HTTPS/443"
        autoragBFF -> ogx "Models/vector stores" "HTTPS/8443"
        autoragBFF -> s3 "Document storage" "HTTPS/443"
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
            element "AI Service" {
                background #9b59b6
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
