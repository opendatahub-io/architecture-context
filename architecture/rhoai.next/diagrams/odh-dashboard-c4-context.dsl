workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, runs pipelines, and monitors experiments"
        platformAdmin = person "Platform Admin" "Configures dashboard settings, manages connections, RBAC, and platform features"

        odhDashboard = softwareSystem "ODH Dashboard" "Unified web console for Red Hat OpenShift AI providing management of data science workloads, model serving, pipelines, and platform administration" {
            kubeRbacProxy = container "kube-rbac-proxy" "Authenticates users via OpenShift RBAC (SubjectAccessReview)" "Go Sidecar" "auth"
            fastifyBackend = container "Fastify Backend" "API gateway: K8s proxy, WebSocket watch streams, module federation routing, static asset serving" "Node.js 22 / TypeScript"
            reactFrontend = container "React Frontend" "Module Federation host application with PatternFly 6 UI components" "React 18 / TypeScript / Webpack 5"
            modelRegistryBFF = container "Model Registry BFF" "Model Registry and Model Catalog management: registered models, versions, artifacts, transfer jobs" "Go 1.25 Sidecar"
            genAiBFF = container "Gen AI BFF" "Generative AI studio: LlamaStack, NeMo guardrails, MCP tools, MLflow prompts, MaaS tokens" "Go 1.25 Sidecar"
            maasBFF = container "MaaS BFF" "Models-as-a-Service: subscriptions, API keys, authorization policies, tier management" "Go 1.25 Sidecar"
            mlflowBFF = container "MLflow BFF" "MLflow experiment tracking with auto-discovery of MLflow instances" "Go 1.25 Sidecar"
            evalHubBFF = container "Eval Hub BFF" "Evaluation Hub: evaluation jobs, collections, providers via TrustyAI" "Go 1.25 Sidecar"
            automlBFF = container "AutoML BFF" "AutoML pipeline management: tabular/time-series training, S3 data, model registration" "Go 1.25 Sidecar"
            autoragBFF = container "AutoRAG BFF" "AutoRAG pipeline management: RAG pipelines, S3 data, LlamaStack queries" "Go 1.25 Sidecar"
        }

        # Internal ODH/RHOAI Platform Components
        rhodsOperator = softwareSystem "RHODS Operator" "Deploys and manages ODH Dashboard via kustomize overlays" "Internal ODH"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource operations" "Platform"
        gatewayAPI = softwareSystem "Gateway API" "External ingress via data-science-gateway HTTPRoute" "Platform"

        # Upstream Platform Services
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and artifacts" "Internal ODH"
        modelCatalog = softwareSystem "Model Catalog" "Browsable catalog of available models" "Internal ODH"
        llamaStack = softwareSystem "LlamaStack" "AI model inference, vector stores, file management" "Internal ODH"
        maasAPI = softwareSystem "MaaS API" "Models-as-a-Service platform for model subscriptions and API keys" "Internal ODH"
        mlflowServer = softwareSystem "MLflow Tracking Server" "Experiment tracking and prompt management" "Internal ODH"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation and guardrails enforcement" "Internal ODH"
        pipelineServer = softwareSystem "Pipeline Server (DSPA)" "Data Science Pipelines for ML workflow orchestration" "Internal ODH"
        evalHub = softwareSystem "EvalHub (TrustyAI)" "Evaluation job management, collections, and providers" "Internal ODH"
        thanosQuerier = softwareSystem "Thanos Querier" "Prometheus metrics aggregation and querying" "Platform"
        perses = softwareSystem "Perses" "Observability dashboard engine" "Internal ODH"

        # External Services
        s3Storage = softwareSystem "S3/MinIO" "Object storage for pipeline data and model artifacts" "External"
        mcpServers = softwareSystem "MCP Servers" "Tool discovery and execution servers" "External"

        # Relationships - Users
        dataScientist -> odhDashboard "Manages notebooks, models, pipelines, and experiments via" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures platform settings, connections, and RBAC via" "HTTPS/443"

        # Relationships - Internal container
        kubeRbacProxy -> kubernetesAPI "Validates user identity via SubjectAccessReview" "HTTPS/6443"
        kubeRbacProxy -> fastifyBackend "Forwards authenticated requests with identity headers" "HTTP/8080"
        reactFrontend -> fastifyBackend "API calls and module federation loading" "HTTP"
        fastifyBackend -> modelRegistryBFF "Proxies /_mf/model-registry/* requests" "HTTPS/8043"
        fastifyBackend -> genAiBFF "Proxies /_mf/gen-ai/* requests" "HTTPS/8143"
        fastifyBackend -> maasBFF "Proxies /_mf/maas/* requests" "HTTPS/8243"
        fastifyBackend -> mlflowBFF "Proxies /_mf/mlflow/* requests" "HTTPS/8343"
        fastifyBackend -> evalHubBFF "Proxies /_mf/eval-hub/* requests" "HTTPS/8543"
        fastifyBackend -> automlBFF "Proxies /_mf/automl/* requests" "HTTPS/8643"
        fastifyBackend -> autoragBFF "Proxies /_mf/autorag/* requests" "HTTPS/8743"
        genAiBFF -> maasBFF "Inter-BFF token delegation" "HTTPS/8243"

        # Relationships - System level
        rhodsOperator -> odhDashboard "Deploys via kustomize overlays"
        gatewayAPI -> odhDashboard "Routes external traffic via HTTPRoute" "HTTPS/8443"
        odhDashboard -> kubernetesAPI "All K8s resource operations (CRUD, watch, RBAC)" "HTTPS/6443"
        odhDashboard -> thanosQuerier "Prometheus metrics queries" "HTTPS/9092"
        odhDashboard -> perses "Observability dashboard data" "HTTP/8080"

        # BFF → Upstream
        modelRegistryBFF -> modelRegistry "Model CRUD operations" "REST API"
        modelRegistryBFF -> modelCatalog "Catalog browsing" "REST API"
        genAiBFF -> llamaStack "AI inference, vector stores, files" "HTTPS (TLS 1.3)"
        genAiBFF -> maasAPI "Model listing, tokens" "HTTPS"
        genAiBFF -> mlflowServer "Prompt management" "REST API"
        genAiBFF -> nemoGuardrails "Content moderation" "HTTPS"
        genAiBFF -> mcpServers "Tool discovery" "HTTP"
        maasBFF -> maasAPI "Subscriptions, API keys, policies" "HTTPS"
        mlflowBFF -> mlflowServer "Experiment listing" "REST API"
        evalHubBFF -> evalHub "Evaluation jobs, collections" "HTTPS"
        automlBFF -> pipelineServer "Pipeline run CRUD" "HTTPS"
        automlBFF -> s3Storage "Data upload/download" "HTTPS/443"
        automlBFF -> modelRegistry "Model registration" "REST API"
        autoragBFF -> pipelineServer "Pipeline run CRUD" "HTTPS"
        autoragBFF -> s3Storage "Data upload/download" "HTTPS/443"
        autoragBFF -> llamaStack "Model/vector store queries" "HTTPS"
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
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "auth" {
                background #c62828
                color #ffffff
            }
        }
    }
}
