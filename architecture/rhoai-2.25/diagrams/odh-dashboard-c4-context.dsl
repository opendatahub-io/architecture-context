workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Uses dashboard to manage data science workloads, notebooks, model serving, and pipelines"
        admin = person "Platform Administrator" "Configures dashboard, manages RBAC, and monitors platform health"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based user interface for Open Data Hub and Red Hat OpenShift AI platform" {
            frontend = container "Frontend SPA" "Single-page application for user interface" "React 18, PatternFly 6, Redux" {
                uiComponents = component "UI Components" "Reusable PatternFly components" "React Components"
                stateManagement = component "State Management" "Global application state" "Redux Store"
                moduleFederation = component "Module Federation" "Dynamic plugin loader" "Webpack Module Federation"
            }

            backend = container "Backend API Server" "REST API proxy to Kubernetes and business logic" "Node.js 20, Fastify 4.28.1" {
                apiRoutes = component "API Routes" "35+ route groups for resource management" "Fastify Plugins"
                k8sClient = component "Kubernetes Client" "API client for cluster resources" "@kubernetes/client-node"
                wsServer = component "WebSocket Server" "Real-time updates and streaming" "WebSocket"
            }

            oauthProxy = container "OAuth Proxy" "Authentication and TLS termination" "OpenShift OAuth Proxy" {
                authHandler = component "Auth Handler" "OAuth 2.0 flow management" "OAuth Proxy"
                tlsTermination = component "TLS Termination" "HTTPS endpoint and certificate" "TLS 1.2+"
            }

            plugins = container "Dynamic Plugins" "Feature-specific modules loaded at runtime" "Webpack Module Federation" {
                genAiPlugin = component "Gen AI Plugin" "Generative AI model management" "React Module"
                modelRegPlugin = component "Model Registry Plugin" "Model versioning and metadata" "React Module"
                featureStorePlugin = component "Feature Store Plugin" "Feature engineering" "React Module"
                lmEvalPlugin = component "LM Eval Plugin" "Language model evaluation" "React Module"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "User authentication service" "External"
        prometheus = softwareSystem "Prometheus/Thanos" "Metrics collection and querying" "External"

        odhOperator = softwareSystem "OpenDataHub Operator" "Platform lifecycle management" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook management" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and metadata storage" "Internal ODH"
        odhModelController = softwareSystem "ODH Model Controller" "Serving runtime management" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal ODH"
        trustyai = softwareSystem "TrustyAI Service" "Model bias and fairness metrics" "Internal ODH"
        kueue = softwareSystem "Kueue" "Distributed workload queue management" "Internal ODH"
        codeflare = softwareSystem "CodeFlare Operator" "Distributed training orchestration" "Internal ODH"

        # User relationships
        user -> odhDashboard "Accesses via browser (HTTPS/443)" "HTTPS"
        admin -> odhDashboard "Configures and monitors" "HTTPS"

        # Frontend relationships
        user -> frontend "Interacts with UI"
        frontend -> backend "API calls (via OAuth proxy)" "HTTPS/8443 → HTTP/8080"
        frontend -> plugins "Loads dynamic plugins" "Module Federation"

        # OAuth proxy relationships
        odhDashboard -> oauthServer "Authenticates users" "OAuth 2.0, HTTPS/6443"
        oauthProxy -> backend "Proxies authenticated requests" "HTTP/8080"

        # Backend relationships
        backend -> k8sAPI "Manages Kubernetes resources" "HTTPS/6443, ServiceAccount Token"
        backend -> prometheus "Queries metrics data" "HTTPS/9092, ServiceAccount Token"

        # ODH component relationships
        backend -> odhOperator "Reads DataScienceCluster and DSCInitialization" "Kubernetes API"
        backend -> kubeflowNotebooks "Creates and manages Notebook CRs" "Kubernetes API"
        backend -> kserve "Reads InferenceService status" "Kubernetes API"
        backend -> modelRegistry "Creates and manages ModelRegistry CRs" "Kubernetes API"
        backend -> odhModelController "Interacts with serving runtimes" "Kubernetes API"
        backend -> dsPipelines "Integrates with pipeline runs" "Kubernetes API"
        backend -> trustyai "Displays bias metrics" "Kubernetes API"
        backend -> kueue "Manages workload queues" "Kubernetes API"
        backend -> codeflare "Manages distributed training" "Kubernetes API"

        # Monitoring relationships
        prometheus -> oauthProxy "Scrapes /metrics endpoint" "HTTPS/8443, no auth"
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

        component frontend "FrontendComponents" {
            include *
            autoLayout
        }

        component backend "BackendComponents" {
            include *
            autoLayout
        }

        component plugins "PluginComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85c1e9
                color #000000
            }
            element "Person" {
                background #f5a623
                shape Person
            }
        }

        theme default
    }
}
