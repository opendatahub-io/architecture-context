workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages ML workloads, models, pipelines, and experiments via the dashboard"
        admin = person "Platform Admin" "Configures platform features, manages access control, and monitors operations"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI providing unified interface for data science workloads" {
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication enforcement sidecar via OpenShift RBAC SubjectAccessReview" "Go sidecar, 8443/TCP HTTPS"
            fastifyBackend = container "Fastify Backend" "API gateway, K8s proxy, WebSocket watch, module federation router, static asset server" "Node.js 22 / Fastify 4.28, 8080/TCP HTTP"
            reactFrontend = container "React Frontend" "PatternFly 6 SPA host with Webpack Module Federation loading plugin remotes" "React 18 / TypeScript"

            modelRegistryBFF = container "Model Registry BFF" "Model Registry and Catalog management: registered models, versions, artifacts, transfer jobs" "Go 1.25, 8043/TCP HTTPS"
            genAiBFF = container "Gen AI BFF" "Generative AI studio: LlamaStack, MaaS, MLflow prompts, NeMo guardrails, MCP tools" "Go 1.25, 8143/TCP HTTPS"
            maasBFF = container "MaaS BFF" "Models-as-a-Service: subscriptions, API keys, authorization policies, tiers" "Go 1.25, 8243/TCP HTTPS"
            mlflowBFF = container "MLflow BFF" "MLflow experiment tracking with auto-discovery of MLflow instances" "Go 1.25, 8343/TCP HTTPS"
            evalHubBFF = container "Eval Hub BFF" "Evaluation Hub: evaluation jobs, collections, providers via TrustyAI" "Go 1.25, 8543/TCP HTTPS"
            automlBFF = container "AutoML BFF" "AutoML pipeline management: tabular/time-series training, S3 data, model registration" "Go 1.25, 8643/TCP HTTPS"
            autoragBFF = container "AutoRAG BFF" "AutoRAG pipeline management: RAG pipelines, S3 data, LlamaStack integration" "Go 1.25, 8743/TCP HTTPS"
        }

        # Platform Infrastructure
        gatewayAPI = softwareSystem "Gateway API" "Platform ingress via HTTPRoute (data-science-gateway)" "Infrastructure"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes API server for all resource operations" "Infrastructure"
        operator = softwareSystem "RHOAI Operator" "Deploys and manages dashboard via kustomize overlays" "Infrastructure"

        # Platform Services
        thanosQuerier = softwareSystem "Thanos Querier" "Prometheus metrics queries for monitoring dashboards" "Platform Service"
        perses = softwareSystem "Data Science Perses" "Observability dashboard service" "Platform Service"

        # Domain Services - Internal ODH
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata, versions, and artifacts" "Internal ODH"
        modelCatalog = softwareSystem "Model Catalog" "Browsable catalog of available models" "Internal ODH"
        llamaStack = softwareSystem "LlamaStack" "AI model inference, vector stores, file management" "Internal ODH"
        maasAPI = softwareSystem "MaaS API" "Models-as-a-Service: subscriptions, tokens, policies" "Internal ODH"
        mlflowServer = softwareSystem "MLflow Server" "Experiment tracking and prompt management" "Internal ODH"
        nemoGuardrails = softwareSystem "NeMo Guardrails" "Content moderation for AI responses" "Internal ODH"
        pipelineServer = softwareSystem "Pipeline Server (DSPA)" "Data Science Pipeline run management" "Internal ODH"
        evalHub = softwareSystem "EvalHub (TrustyAI)" "Evaluation job, collection, and provider management" "Internal ODH"
        feast = softwareSystem "Feast" "Feature store discovery and metadata" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving runtime management" "Internal ODH"

        # External Services
        s3 = softwareSystem "S3/MinIO" "Object storage for pipeline data and model artifacts" "External"
        mcpServers = softwareSystem "MCP Servers" "Tool discovery and execution via HTTP" "External"

        # Relationships - Users
        datascientist -> odhDashboard "Uses for ML workload management" "HTTPS/443"
        admin -> odhDashboard "Configures platform and manages access" "HTTPS/443"

        # Relationships - Infrastructure
        gatewayAPI -> odhDashboard "Routes external traffic" "HTTPS/8443"
        operator -> odhDashboard "Deploys and configures" "kustomize"
        odhDashboard -> k8sAPI "All K8s resource operations" "HTTPS/6443"

        # Relationships - Platform Services
        odhDashboard -> thanosQuerier "Prometheus metrics queries" "HTTPS/9092"
        odhDashboard -> perses "Observability dashboards" "HTTP/8080"

        # Relationships - Domain Services
        odhDashboard -> modelRegistry "Model CRUD operations" "HTTP/HTTPS"
        odhDashboard -> modelCatalog "Model catalog browsing" "HTTP/HTTPS"
        odhDashboard -> llamaStack "AI inference, vector stores, files" "HTTPS (TLS 1.3)"
        odhDashboard -> maasAPI "Model subscriptions, tokens" "HTTPS"
        odhDashboard -> mlflowServer "Experiment tracking, prompts" "HTTPS"
        odhDashboard -> nemoGuardrails "Content moderation" "HTTPS"
        odhDashboard -> pipelineServer "Pipeline run management" "HTTPS"
        odhDashboard -> evalHub "Evaluation management" "HTTPS"
        odhDashboard -> feast "Feature store queries" "HTTPS"
        odhDashboard -> kserve "Serving runtime management" "CRD CRUD"
        odhDashboard -> s3 "Data upload/download" "HTTPS/443"
        odhDashboard -> mcpServers "Tool discovery" "HTTP"

        # Internal container relationships
        kubeRbacProxy -> fastifyBackend "Forwards authenticated requests" "HTTP/8080"
        fastifyBackend -> reactFrontend "Serves static assets"
        fastifyBackend -> modelRegistryBFF "Module federation proxy" "HTTPS/8043"
        fastifyBackend -> genAiBFF "Module federation proxy" "HTTPS/8143"
        fastifyBackend -> maasBFF "Module federation proxy" "HTTPS/8243"
        fastifyBackend -> mlflowBFF "Module federation proxy" "HTTPS/8343"
        fastifyBackend -> evalHubBFF "Module federation proxy" "HTTPS/8543"
        fastifyBackend -> automlBFF "Module federation proxy" "HTTPS/8643"
        fastifyBackend -> autoragBFF "Module federation proxy" "HTTPS/8743"
        genAiBFF -> maasBFF "Inter-BFF token delegation" "HTTPS/8243"
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
            element "Platform Service" {
                background #6c8ebf
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
            element "Person" {
                shape person
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
