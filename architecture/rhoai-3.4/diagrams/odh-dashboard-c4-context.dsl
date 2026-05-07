workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, runs pipelines, manages ML workflows"
        mlEngineer = person "ML Engineer" "Manages model serving, monitors inference services, configures pipelines"
        platformAdmin = person "Platform Admin" "Configures platform settings, manages model registries, NVIDIA NIM integration"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI (RHOAI)" {
            frontend = container "Frontend SPA" "React/PatternFly 6 single-page application with Module Federation" "TypeScript, Webpack"
            backend = container "Backend BFF" "Proxies K8s API calls, serves frontend, manages WebSocket connections" "Node.js, Fastify"
            kubeRbacProxy = container "kube-rbac-proxy" "RBAC-based authentication proxy validating OAuth tokens" "Go Sidecar"

            genAiBff = container "Gen AI BFF" "LLM orchestration, Llama Stack, MCP, prompt management" "Go 1.24"
            modelRegistryBff = container "Model Registry BFF" "Model versioning and catalog integration UI" "Go 1.25"
            maasBff = container "MaaS BFF" "Model marketplace, API key management, tier access control" "Go 1.24"
            mlflowBff = container "MLflow BFF" "Experiment tracking and run management" "Go 1.24"
            evalHubBff = container "Eval Hub BFF" "Model evaluation hub for TrustyAI" "Go 1.24"
            automlBff = container "AutoML BFF" "Automated ML pipeline management" "Go 1.24"
            autoragBff = container "AutoRAG BFF" "RAG pipeline automation" "Go 1.24"
        }

        # Internal Platform Dependencies
        kubeApi = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "Internal Platform"
        kserve = softwareSystem "KServe" "Model serving via InferenceService CRDs" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline execution and management (Kubeflow)" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model versioning, artifacts, and catalog" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "Model explainability, bias monitoring, evaluations" "Internal ODH"
        notebookController = softwareSystem "Kubeflow Notebook Controller" "Notebook lifecycle management" "Internal ODH"
        llamaStack = softwareSystem "Llama Stack" "LLM inference, vector stores, file management" "Internal ODH"
        mlflowOperator = softwareSystem "MLflow Operator" "Experiment tracking server management" "Internal ODH"
        feastOperator = softwareSystem "Feast Operator" "Feature store management" "Internal ODH"
        nimIntegration = softwareSystem "NVIDIA NIM" "NVIDIA inference model integration" "External"
        rhoodsOperator = softwareSystem "RHOAI Operator" "Deploys and manages dashboard via component manifests" "Internal Platform"

        # External Services
        prometheus = softwareSystem "Prometheus / Thanos" "Metrics collection and querying" "Internal Platform"
        gatewayApi = softwareSystem "Gateway API" "Ingress routing via data-science-gateway" "Internal Platform"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for ML artifacts and RAG files" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol tool integration" "External"
        maasBackend = softwareSystem "MaaS Backend" "Model marketplace service" "External"

        # Relationships - Users
        dataScientist -> odhDashboard "Manages notebooks, models, pipelines via" "HTTPS/443"
        mlEngineer -> odhDashboard "Deploys and monitors model serving via" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures platform settings via" "HTTPS/443"

        # Relationships - Internal containers
        frontend -> backend "API calls and WebSocket" "HTTP/8080"
        kubeRbacProxy -> backend "Forwards authenticated requests" "HTTP/8080 x-forwarded-access-token"
        backend -> genAiBff "Proxies /gen-ai/api/* requests" "HTTPS/8143"
        backend -> modelRegistryBff "Proxies /model-registry/api/* requests" "HTTPS/8043"
        backend -> maasBff "Proxies /maas/api/* requests" "HTTPS/8243"
        backend -> mlflowBff "Proxies /_bff/mlflow/api/* requests" "HTTPS/8343"
        backend -> evalHubBff "Proxies /eval-hub/api/* requests" "HTTPS/8543"
        backend -> automlBff "Proxies /automl/api/* requests" "HTTPS/8643"
        backend -> autoragBff "Proxies /autorag/api/* requests" "HTTPS/8743"

        # Relationships - External systems
        odhDashboard -> kubeApi "All K8s resource CRUD and CRD watches" "HTTPS/443 SA Token"
        odhDashboard -> kserve "Monitors InferenceService CRDs" "HTTPS/443"
        odhDashboard -> dsp "Pipeline creation, runs, monitoring" "HTTPS/8443"
        odhDashboard -> modelRegistry "Model versioning and artifact management" "HTTPS/443"
        odhDashboard -> trustyai "Model explainability and evaluation" "HTTPS/443"
        odhDashboard -> notebookController "Notebook lifecycle (create, start, stop)" "HTTPS/443 via K8s API"
        odhDashboard -> prometheus "Metrics queries via PromQL" "HTTPS/9092"
        odhDashboard -> llamaStack "LLM inference, vector stores, RAG" "HTTPS/443"
        odhDashboard -> mlflowOperator "MLflow tracking server discovery" "HTTPS/443 via K8s API"
        odhDashboard -> feastOperator "Feature store discovery" "HTTPS/443 via K8s API"
        odhDashboard -> nimIntegration "NVIDIA NIM model integration" "HTTPS/443"
        odhDashboard -> s3Storage "File upload/download for AutoML/AutoRAG" "HTTPS/443"
        odhDashboard -> mcpServers "AI agent tool integration" "HTTPS"
        odhDashboard -> maasBackend "Model marketplace, subscriptions" "HTTPS"
        rhoodsOperator -> odhDashboard "Deploys via kustomize manifests"
        gatewayApi -> odhDashboard "Routes external traffic" "HTTPS/8443"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal Platform" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
