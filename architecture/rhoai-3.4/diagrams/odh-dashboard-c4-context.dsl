workspace {
    model {
        // People
        dataScientist = person "Data Scientist" "Creates notebooks, deploys models, runs pipelines, and uses Gen AI features"
        mlEngineer = person "ML Engineer" "Manages model serving, registry, and production deployments"
        platformAdmin = person "Platform Admin" "Configures dashboard features, RBAC, and cluster settings"

        // Main System
        odhDashboard = softwareSystem "ODH Dashboard" "Web dashboard providing the primary UI for Red Hat OpenShift AI" {
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination, SubjectAccessReview authorization" "Go Sidecar" "Auth"
            dashboardBackend = container "Dashboard Backend" "Serves React SPA, proxies K8s API, routes module federation" "Node.js/Fastify" "Core"
            dashboardFrontend = container "Dashboard Frontend" "React SPA with PatternFly, Module Federation host" "React/TypeScript" "Frontend"
            modelRegistryBFF = container "Model Registry BFF" "Proxies model registry CRUD, model catalog, MCP deployments" "Go BFF Sidecar"
            genAiBFF = container "Gen AI BFF" "Proxies LlamaStack, MaaS, MLflow prompts, MCP tools, guardrails" "Go BFF Sidecar"
            maasBFF = container "MaaS BFF" "Manages Models-as-a-Service subscriptions, API keys, tiers" "Go BFF Sidecar"
            mlflowBFF = container "MLflow BFF" "Proxies MLflow experiment tracking API" "Go BFF Sidecar"
            evalHubBFF = container "Eval Hub BFF" "Manages evaluation runs with TrustyAI EvalHub" "Go BFF Sidecar"
            automlBFF = container "AutoML BFF" "Manages AutoML experiments with S3 and pipelines" "Go BFF Sidecar"
            autoragBFF = container "AutoRAG BFF" "Manages AutoRAG pipelines with LlamaStack and S3" "Go BFF Sidecar"
        }

        // External Systems - Platform
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for all resource operations" "Platform"
        gateway = softwareSystem "data-science-gateway" "Envoy-based Gateway API for external ingress" "Platform"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "Model explainability and evaluation metrics" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata management" "Internal RHOAI"
        modelCatalog = softwareSystem "Model Catalog" "Curated model catalog" "Internal RHOAI"
        openshiftConsole = softwareSystem "OpenShift Console" "OpenShift web console with ConsoleLink integration" "Platform"

        // External Systems - AI/ML Services
        llamaStack = softwareSystem "LlamaStack" "AI inference, RAG, vector stores" "AI Service"
        maasApi = softwareSystem "MaaS API" "Models-as-a-Service platform" "AI Service"
        mlflow = softwareSystem "MLflow" "Experiment and prompt tracking" "AI Service"
        perses = softwareSystem "Perses" "Dashboard visualization service" "Internal RHOAI"

        // External Systems - Storage
        s3Storage = softwareSystem "S3 Storage" "Object storage for datasets and model artifacts" "External"

        // User relationships
        dataScientist -> odhDashboard "Manages notebooks, models, pipelines via" "HTTPS/443"
        mlEngineer -> odhDashboard "Manages model serving and registry via" "HTTPS/443"
        platformAdmin -> odhDashboard "Configures platform features via" "HTTPS/443"

        // Internal container relationships
        kubeRbacProxy -> dashboardBackend "Forwards authenticated requests" "HTTP/8080"
        dashboardBackend -> dashboardFrontend "Serves" "HTTP"
        dashboardBackend -> modelRegistryBFF "Proxies /_mf/modelRegistry/*" "HTTPS/8043 TLS 1.3"
        dashboardBackend -> genAiBFF "Proxies /_mf/genAi/*" "HTTPS/8143 TLS 1.3"
        dashboardBackend -> maasBFF "Proxies /_mf/maas/*" "HTTPS/8243 TLS 1.3"
        dashboardBackend -> mlflowBFF "Proxies /_mf/mlflow/*" "HTTPS/8343 TLS 1.3"
        dashboardBackend -> evalHubBFF "Proxies /_mf/evalHub/*" "HTTPS/8543 TLS 1.3"
        dashboardBackend -> automlBFF "Proxies /_mf/automl/*" "HTTPS/8643 TLS 1.3"
        dashboardBackend -> autoragBFF "Proxies /_mf/autorag/*" "HTTPS/8743 TLS 1.3"

        // External relationships from containers
        gateway -> kubeRbacProxy "Routes external traffic" "HTTPS/8443"
        dashboardBackend -> k8sApi "Proxies K8s API calls" "HTTPS/6443"
        dashboardBackend -> dsPipelines "Proxies pipeline operations" "HTTPS/8443"
        dashboardBackend -> trustyai "Proxies explainability metrics" "HTTPS/443"
        dashboardBackend -> perses "Proxies dashboard visualizations" "HTTP/8080"

        modelRegistryBFF -> modelRegistry "Model metadata CRUD" "HTTPS/443"
        modelRegistryBFF -> modelCatalog "Model catalog browsing" "HTTPS/443"
        genAiBFF -> llamaStack "AI inference and RAG" "HTTP/gRPC"
        genAiBFF -> maasApi "MaaS model access" "HTTPS"
        genAiBFF -> mlflow "Prompt management" "HTTP"
        maasBFF -> maasApi "Subscription and API key management" "HTTPS"
        mlflowBFF -> mlflow "Experiment tracking" "HTTP"
        evalHubBFF -> trustyai "Evaluation execution" "HTTPS"
        automlBFF -> s3Storage "Dataset and artifact storage" "HTTPS/443"
        automlBFF -> dsPipelines "Pipeline execution" "HTTPS"
        autoragBFF -> llamaStack "RAG evaluation" "HTTP/gRPC"
        autoragBFF -> s3Storage "Document storage" "HTTPS/443"

        odhDashboard -> openshiftConsole "Registers ConsoleLink" "CR"
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
                background #438DD5
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "AI Service" {
                background #f5a623
                color #ffffff
            }
            element "External" {
                background #e67e22
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Auth" {
                background #e74c3c
                color #ffffff
            }
            element "Core" {
                background #3498db
                color #ffffff
            }
            element "Frontend" {
                background #2ecc71
                color #ffffff
            }
        }
    }
}
