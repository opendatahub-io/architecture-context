workspace {
    model {
        user = person "Data Scientist" "Creates and manages data science projects, notebooks, and model deployments"
        admin = person "Platform Administrator" "Configures ODH platform components and manages cluster settings"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Open Data Hub and Red Hat OpenShift AI" {
            frontend = container "React Frontend" "User interface for dashboard interactions" "React 18 + PatternFly" {
                tags "WebApp"
            }
            backend = container "Node.js Backend" "API server that proxies K8s requests and enforces authentication" "Node.js 20 + Fastify" {
                tags "API"
            }
            proxy = container "kube-rbac-proxy" "OAuth2 authentication proxy with user/group header injection" "Go Proxy" {
                tags "Proxy"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API" "Container orchestration platform API" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "User authentication service" "External"
        thanosQuerier = softwareSystem "Thanos Querier" "Prometheus metrics aggregator" "External"

        notebookController = softwareSystem "Notebook Controller" "Manages Jupyter notebook lifecycle" "Internal ODH"
        kserveController = softwareSystem "KServe Controller" "Manages InferenceService resources for model serving" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Manages DataScienceCluster and platform configuration" "Internal ODH"
        feastOperator = softwareSystem "Feast Operator" "Manages FeatureStore resources" "Internal ODH"
        llamaStackOperator = softwareSystem "Llama Stack Operator" "Manages LlamaStackDistribution resources" "Internal ODH"
        pipelines = softwareSystem "Kubeflow Pipelines" "ML workflow orchestration" "Internal ODH"

        # User interactions
        user -> odhDashboard "Uses dashboard to manage projects and deploy models" "HTTPS/443"
        admin -> odhDashboard "Configures platform settings and feature flags" "HTTPS/443"

        # Frontend to backend
        frontend -> proxy "API requests via authentication proxy" "HTTPS/8443"
        proxy -> backend "Forwards authenticated requests with user headers" "HTTP/8080"

        # Backend to external dependencies
        proxy -> openshiftOAuth "Validates OAuth2 bearer tokens" "HTTPS/443"
        backend -> k8sAPI "CRUD operations on Kubernetes resources" "HTTPS/443"
        backend -> thanosQuerier "Queries Prometheus metrics" "HTTPS/9092"

        # Backend to internal ODH components
        backend -> notebookController "Creates and manages Jupyter notebooks via Notebook CRD" "HTTPS/443 (K8s API)"
        backend -> kserveController "Monitors InferenceService status" "HTTPS/443 (K8s API)"
        backend -> modelRegistry "Manages ModelRegistry instances" "HTTPS/443 (K8s API), HTTP/8080, gRPC/9090"
        backend -> odhOperator "Monitors DataScienceCluster and DSCInitialization" "HTTPS/443 (K8s API)"
        backend -> feastOperator "Monitors FeatureStore resources" "HTTPS/443 (K8s API)"
        backend -> llamaStackOperator "Monitors LlamaStackDistribution resources" "HTTPS/443 (K8s API)"
        backend -> pipelines "Accesses pipeline definitions and executions" "HTTPS/443 (K8s API)"
    }

    views {
        systemContext odhDashboard "ODHDashboard-SystemContext" {
            include *
            autoLayout
        }

        container odhDashboard "ODHDashboard-Containers" {
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
            element "WebApp" {
                shape WebBrowser
                background #4a90e2
                color #ffffff
            }
            element "API" {
                shape Hexagon
                background #4a90e2
                color #ffffff
            }
            element "Proxy" {
                shape Component
                background #f5a623
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
