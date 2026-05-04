workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, runs pipelines, and manages AI/ML workloads"
        platformAdmin = person "Platform Admin" "Configures dashboard settings, manages registries, and administers platform features"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI providing unified interface for data science workloads" {
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication enforcement via OpenShift RBAC SubjectAccessReview" "Go Sidecar" "Auth"
            fastifyBackend = container "Fastify Backend" "API gateway serving React SPA, proxying K8s API, WebSocket watch streams, and routing module federation requests" "Node.js 22 / TypeScript"
            reactFrontend = container "React Frontend" "Module Federation host application with PatternFly 6 UI" "React / TypeScript / Webpack 5"
            modelRegistryBFF = container "Model Registry BFF" "Model Registry and Model Catalog management" "Go 1.25 BFF Sidecar"
            genAiBFF = container "Gen AI BFF" "Generative AI studio: LlamaStack, NeMo guardrails, MCP tools, prompts" "Go 1.25 BFF Sidecar"
            maasBFF = container "MaaS BFF" "Models-as-a-Service: subscriptions, API keys, policies, tiers" "Go 1.25 BFF Sidecar"
            mlflowBFF = container "MLflow BFF" "MLflow experiment tracking with auto-discovery" "Go 1.25 BFF Sidecar"
            evalHubBFF = container "Eval Hub BFF" "Evaluation Hub: job management, collections, providers" "Go 1.25 BFF Sidecar"
            automlBFF = container "AutoML BFF" "AutoML pipeline management: tabular and time-series training" "Go 1.25 BFF Sidecar"
            autoragBFF = container "AutoRAG BFF" "AutoRAG pipeline management: RAG training jobs" "Go 1.25 BFF Sidecar"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "OpenShift/Kubernetes API server for resource management and RBAC" "Platform"
        gatewayAPI = softwareSystem "Gateway API" "data-science-gateway providing external HTTPRoute ingress" "Platform"
        thanosQuerier = softwareSystem "Thanos Querier" "Prometheus metrics querying in openshift-monitoring namespace" "Platform"

        modelRegistrySvc = softwareSystem "Model Registry Service" "Stores and manages registered models, versions, and artifacts" "Internal ODH"
        modelCatalog = softwareSystem "Model Catalog Service" "Browsable catalog of available models" "Internal ODH"
        llamaStack = softwareSystem "LlamaStack" "AI model inference, vector stores, and file management" "Internal ODH"
        maasAPI = softwareSystem "MaaS API" "Models-as-a-Service platform for model subscriptions and tokens" "Internal ODH"
        mlflowServer = softwareSystem "MLflow Tracking Server" "Experiment tracking and prompt management" "Internal ODH"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation and safety guardrails" "Internal ODH"
        pipelineServer = softwareSystem "Pipeline Server (DSPA)" "Data Science Pipelines for ML workflow execution" "Internal ODH"
        evalHubSvc = softwareSystem "EvalHub (TrustyAI)" "Evaluation job management and LLM benchmarking" "Internal ODH"
        s3Storage = softwareSystem "S3/MinIO" "Object storage for training data and model artifacts" "External"
        mcpServers = softwareSystem "MCP Servers" "Model Context Protocol servers for tool discovery" "Internal ODH"
        perses = softwareSystem "Perses" "Observability dashboard service" "Internal ODH"
        feastRegistry = softwareSystem "Feast Registry" "Feature store metadata service" "Internal ODH"

        # User interactions
        dataScientist -> odhDashboard "Manages notebooks, models, pipelines via browser" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures dashboard, manages registries and serving runtimes" "HTTPS/443"

        # External ingress
        gatewayAPI -> odhDashboard "Routes external traffic" "HTTPS/443 → 8443"

        # Internal container relationships
        kubeRbacProxy -> fastifyBackend "Forwards authenticated requests" "HTTP/8080"
        fastifyBackend -> reactFrontend "Serves SPA assets"
        fastifyBackend -> modelRegistryBFF "Module federation proxy" "HTTPS/8043"
        fastifyBackend -> genAiBFF "Module federation proxy" "HTTPS/8143"
        fastifyBackend -> maasBFF "Module federation proxy" "HTTPS/8243"
        fastifyBackend -> mlflowBFF "Module federation proxy" "HTTPS/8343"
        fastifyBackend -> evalHubBFF "Module federation proxy" "HTTPS/8543"
        fastifyBackend -> automlBFF "Module federation proxy" "HTTPS/8643"
        fastifyBackend -> autoragBFF "Module federation proxy" "HTTPS/8743"
        genAiBFF -> maasBFF "Inter-BFF token delegation" "HTTPS/8243"

        # Platform dependencies
        kubeRbacProxy -> kubernetesAPI "SubjectAccessReview" "HTTPS/6443"
        fastifyBackend -> kubernetesAPI "K8s API passthrough, CRD watch" "HTTPS/6443"
        fastifyBackend -> thanosQuerier "Prometheus queries" "HTTPS/9092"
        fastifyBackend -> perses "Observability dashboards" "HTTP/8080"
        fastifyBackend -> feastRegistry "Feature store proxy" "HTTPS"

        # BFF → Upstream service dependencies
        modelRegistryBFF -> modelRegistrySvc "Model CRUD operations" "HTTP(S)"
        modelRegistryBFF -> modelCatalog "Catalog queries" "HTTP(S)"
        modelRegistryBFF -> kubernetesAPI "Service discovery, RBAC" "HTTPS/6443"
        genAiBFF -> llamaStack "Model inference, vector stores" "HTTPS TLS 1.3"
        genAiBFF -> maasAPI "Model listing, tokens" "HTTPS"
        genAiBFF -> mlflowServer "Prompt management" "HTTPS"
        genAiBFF -> nemoGuardrails "Content moderation" "HTTPS"
        genAiBFF -> mcpServers "Tool discovery" "HTTP"
        genAiBFF -> kubernetesAPI "CR management" "HTTPS/6443"
        maasBFF -> maasAPI "Subscriptions, policies" "HTTPS"
        maasBFF -> kubernetesAPI "CRD CRUD, RBAC" "HTTPS/6443"
        mlflowBFF -> mlflowServer "Experiment tracking" "HTTPS"
        mlflowBFF -> kubernetesAPI "CR watching" "HTTPS/6443"
        evalHubBFF -> evalHubSvc "Evaluation management" "HTTPS"
        evalHubBFF -> kubernetesAPI "CR status" "HTTPS/6443"
        automlBFF -> pipelineServer "Pipeline run CRUD" "HTTPS"
        automlBFF -> s3Storage "Data upload/download" "HTTPS/443"
        automlBFF -> modelRegistrySvc "Model registration" "HTTPS"
        automlBFF -> kubernetesAPI "DSPA discovery, secrets" "HTTPS/6443"
        autoragBFF -> pipelineServer "Pipeline run CRUD" "HTTPS"
        autoragBFF -> s3Storage "Data upload/download" "HTTPS/443"
        autoragBFF -> llamaStack "Model/vector store queries" "HTTPS"
        autoragBFF -> kubernetesAPI "DSPA discovery, secrets" "HTTPS/6443"
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
            element "Platform" {
                background #e1d5e7
                shape RoundedBox
            }
            element "Internal ODH" {
                background #d5e8d4
                shape RoundedBox
            }
            element "External" {
                background #fff2cc
                shape RoundedBox
            }
            element "Auth" {
                background #f8cecc
                shape Hexagon
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
