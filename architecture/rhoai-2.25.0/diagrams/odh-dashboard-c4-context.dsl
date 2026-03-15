workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML workloads via web interface"
        admin = person "Platform Administrator" "Configures and maintains ODH/RHOAI platform"

        dashboard = softwareSystem "ODH Dashboard" "Web-based user interface for managing Open Data Hub and RHOAI platform components" {
            frontend = container "React Frontend" "Single-page application providing web UI" "React 18, PatternFly 6" {
                tags "Web Browser"
            }
            backend = container "Fastify Backend" "REST API server and Kubernetes API proxy" "Node.js 20, Fastify 4.28.1" {
                tags "API"
            }
            oauthProxy = container "OAuth Proxy" "Authentication and TLS termination sidecar" "OpenShift OAuth Proxy" {
                tags "Security"
            }
            plugins = container "Module Federation Plugins" "Dynamically loaded feature plugins" "Webpack Module Federation" {
                tags "Plugin"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes cluster control plane API" "External Platform"
        oauthServer = softwareSystem "OpenShift OAuth Server" "User authentication and authorization" "External Platform"
        prometheus = softwareSystem "Prometheus/Thanos" "Metrics and monitoring" "External Platform"

        odhOperator = softwareSystem "OpenDataHub Operator" "Platform lifecycle management" "Internal ODH"
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook environments" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model metadata and versioning" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal ODH"
        trustyai = softwareSystem "TrustyAI Service" "Model bias and trustworthiness metrics" "Internal ODH"
        kueue = softwareSystem "Kueue" "Distributed workload queue management" "Internal ODH"
        codeflare = softwareSystem "CodeFlare Operator" "Distributed training management" "Internal ODH"
        llamastack = softwareSystem "LlamaStack" "LLM inference distributions" "Internal ODH"

        # User interactions
        user -> dashboard "Creates notebooks, deploys models, views metrics" "HTTPS/443"
        admin -> dashboard "Configures platform settings, manages users" "HTTPS/443"

        # Dashboard to frontend/backend
        user -> oauthProxy "Accesses web UI" "HTTPS/443"
        oauthProxy -> oauthServer "Authenticates user" "OAuth 2.0"
        oauthProxy -> backend "Proxies authenticated requests" "HTTP/8080"
        backend -> frontend "Serves static assets" "HTTP"
        frontend -> backend "API calls for resources" "HTTP"

        # Backend to Kubernetes
        backend -> k8sAPI "Manages Kubernetes resources" "HTTPS/6443"
        backend -> prometheus "Queries metrics data" "HTTPS/9092"

        # Backend to ODH components
        backend -> odhOperator "Reads DataScienceCluster config" "via K8s API"
        backend -> notebooks "Creates and manages notebook CRs" "via K8s API"
        backend -> kserve "Reads InferenceService status" "via K8s API"
        backend -> modelRegistry "Manages ModelRegistry CRs and queries APIs" "HTTPS/8080, gRPC/9090"
        backend -> pipelines "Integrates pipeline runs" "via K8s API"
        backend -> trustyai "Displays bias metrics" "via K8s API"
        backend -> kueue "Manages workload queues" "via K8s API"
        backend -> codeflare "Manages distributed workloads" "via K8s API"
        backend -> llamastack "Manages LLM distributions" "via K8s API"

        # Plugin loading
        frontend -> plugins "Dynamically loads features" "Module Federation"
        plugins -> backend "Feature-specific API calls" "HTTP"
    }

    views {
        systemContext dashboard "SystemContext" {
            include *
            autoLayout lr
        }

        container dashboard "Containers" {
            include *
            autoLayout lr
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Web Browser" {
                shape WebBrowser
                background #4a90e2
                color #ffffff
            }
            element "API" {
                background #4a90e2
                color #ffffff
            }
            element "Security" {
                background #f5a623
                color #000000
            }
            element "Plugin" {
                background #d3d3d3
                color #000000
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
