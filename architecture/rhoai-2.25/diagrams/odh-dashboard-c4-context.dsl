workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, manages ML workflows"
        platformAdmin = person "Platform Admin" "Configures platform settings, manages accelerators, hardware profiles, serving runtimes"

        odhDashboard = softwareSystem "ODH Dashboard" "Web dashboard providing the primary UI for Red Hat OpenShift AI" {
            oauthProxy = container "oauth-proxy" "OpenShift OAuth proxy providing authentication and TLS termination" "Go Sidecar" "Sidecar"
            backend = container "Dashboard Backend" "API gateway proxying K8s API calls, service proxies, WebSocket tunnels" "Node.js 20 / Fastify 4"
            frontend = container "Dashboard Frontend" "Plugin-extensible web UI with PatternFly 6 and Module Federation" "React / TypeScript SPA"
            modelRegistryBFF = container "Model Registry BFF" "Go BFF for model registry operations with SAR/SSAR auth" "Go 1.25"
            modelRegistryUI = container "Model Registry UI" "Federated React module for model lifecycle management" "React / TypeScript Module"
            genAiBFF = container "Gen AI BFF (future)" "Go BFF for LlamaStack/MCP integration" "Go 1.25" "Future"
            genAiUI = container "Gen AI UI (future)" "Federated React module for chat, RAG, and MCP tools" "React / TypeScript Module" "Future"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OAuth 2.0 authentication provider" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "OpenShift web console (receives ConsoleLink)" "External"
        notebookController = softwareSystem "Notebook Controller" "Kubeflow notebook lifecycle manager" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving and inference platform" "Internal RHOAI"
        modelRegistryOperator = softwareSystem "Model Registry" "Model lifecycle management service" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Catalog of available ML models" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        trustyAI = softwareSystem "TrustyAI" "AI explainability and bias monitoring" "Internal RHOAI"
        mlmd = softwareSystem "ML Metadata" "Metadata tracking for ML artifacts" "Internal RHOAI"
        feast = softwareSystem "Feast Feature Store" "Feature engineering and serving" "Internal RHOAI"
        llamaStack = softwareSystem "LlamaStack" "Gen AI inference (LLM, RAG, vector stores)" "Internal RHOAI"
        nvidianim = softwareSystem "NVIDIA NIM" "NVIDIA inference microservice" "External"
        thanos = softwareSystem "Thanos/Prometheus" "Cluster monitoring and metrics" "External"
        segment = softwareSystem "Segment.io" "Analytics telemetry" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator managing dashboard lifecycle" "Internal RHOAI"

        # Person interactions
        dataScientist -> odhDashboard "Creates notebooks, deploys models, monitors pipelines via browser"
        platformAdmin -> odhDashboard "Configures platform settings, manages profiles and runtimes via browser"

        # Container-level interactions
        oauthProxy -> openshiftOAuth "Validates OAuth session" "HTTPS/443"
        oauthProxy -> backend "Forwards authenticated requests" "HTTP/8080"
        frontend -> backend "API calls via fetch/WebSocket" "HTTP/8080"
        backend -> k8sApi "All K8s resource CRUD and RBAC" "HTTPS/443"
        backend -> thanos "Prometheus metrics queries" "HTTPS/9092"
        backend -> dsPipelines "Pipeline API proxy" "HTTPS/8443"
        backend -> trustyAI "Explainability API proxy" "HTTPS/443"
        backend -> mlmd "Metadata API proxy" "HTTPS/8443"
        backend -> feast "Feature store proxy" "HTTPS/443"
        backend -> llamaStack "Gen AI inference proxy" "HTTP/8321"
        backend -> modelRegistryBFF "Module federation proxy" "HTTPS/8043"
        backend -> segment "Analytics telemetry" "HTTPS/443"
        modelRegistryBFF -> k8sApi "SAR/SSAR checks, service discovery" "HTTPS/443"
        modelRegistryBFF -> modelRegistryOperator "Model CRUD operations" "HTTP/8080"
        modelRegistryBFF -> modelCatalog "Model catalog browsing" "HTTP/HTTPS"
        frontend -> modelRegistryUI "Dynamic module loading" "Module Federation"
        frontend -> genAiUI "Dynamic module loading (future)" "Module Federation"
        genAiBFF -> llamaStack "LLM inference, RAG, vector stores" "HTTP/8321"
        genAiBFF -> k8sApi "Namespace, InferenceService operations" "HTTPS/443"

        # System context interactions
        odhDashboard -> k8sApi "All resource operations via proxy" "HTTPS/443"
        odhDashboard -> openshiftOAuth "User authentication" "HTTPS/443"
        odhDashboard -> openshiftConsole "ConsoleLink integration" "CR"
        odhDashboard -> notebookController "Notebook lifecycle (create/start/stop)" "CRD: kubeflow.org/v1 Notebook"
        odhDashboard -> kserve "Model serving management" "CRD: InferenceService, ServingRuntime"
        odhDashboard -> modelRegistryOperator "Model registry management" "CRD + REST API"
        odhDashboard -> dsPipelines "Pipeline management proxy" "HTTPS/8443"
        odhDashboard -> trustyAI "Explainability proxy" "HTTPS/443"
        odhDashboard -> mlmd "Metadata proxy" "HTTPS/8443"
        odhDashboard -> feast "Feature store proxy" "HTTPS/443"
        odhDashboard -> llamaStack "Gen AI proxy" "HTTP/8321"
        odhDashboard -> nvidianim "NIM integration" "CRD: nim.opendatahub.io/Account"
        odhDashboard -> thanos "Metrics queries" "HTTPS/9092"
        rhoaiOperator -> odhDashboard "Deploys and manages via OdhDashboardConfig CRD" "CRD"
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
            element "Sidecar" {
                background #e8a838
                color #ffffff
            }
            element "Future" {
                background #9b59b6
                color #ffffff
                opacity 50
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
        }
    }
}
