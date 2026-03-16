workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and manages ML workbenches, notebooks, pipelines, and model deployments"
        mlEngineer = person "ML Engineer" "Deploys and monitors ML models in production"
        admin = person "Platform Administrator" "Configures dashboard settings, user groups, and accelerator profiles"

        # Main System
        odhDashboard = softwareSystem "ODH Dashboard" "Web-based UI for Red Hat OpenShift AI platform providing centralized management of data science tools" {
            frontend = container "React Frontend" "PatternFly-based SPA providing dashboard UI" "TypeScript, React" {
                tags "Web Browser"
            }
            backend = container "Fastify Backend" "REST API server that proxies Kubernetes API calls" "Node.js, Fastify" {
                tags "API"
            }
            oauthProxy = container "OAuth Proxy" "Handles OpenShift authentication" "OpenShift OAuth Proxy" {
                tags "Security"
            }
        }

        # External Platform Systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane for resource management" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Provides authentication and authorization services" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external traffic" "External"
        openshiftConsole = softwareSystem "OpenShift Console" "Main OpenShift web console" "External"

        # Internal ODH Systems
        odhOperator = softwareSystem "ODH Operator" "Manages DataScienceCluster and component lifecycle" "Internal ODH"
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook workbench environments" "Internal ODH"
        kserve = softwareSystem "KServe" "Kubernetes-native model inference platform" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh Serving" "High-density multi-model serving platform" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and metadata management" "Internal ODH"
        thanos = softwareSystem "Thanos Querier" "Prometheus-based metrics aggregation" "Internal ODH"

        # External Services
        s3Storage = softwareSystem "S3 Storage" "Object storage for models and pipeline artifacts" "External Service"

        # User Relationships
        dataScientist -> odhDashboard "Creates notebooks, runs pipelines, explores learning resources"
        mlEngineer -> odhDashboard "Deploys models, monitors metrics, manages serving runtimes"
        admin -> odhDashboard "Configures dashboard settings, manages user groups and accelerator profiles"

        # Dashboard Internal Relationships
        dataScientist -> frontend "Accesses via web browser (HTTPS/443)"
        mlEngineer -> frontend "Accesses via web browser (HTTPS/443)"
        admin -> frontend "Accesses via web browser (HTTPS/443)"
        frontend -> oauthProxy "Requests authenticated via"
        oauthProxy -> backend "Proxies requests to (HTTP/8080)"
        backend -> frontend "Serves UI assets to"

        # Dashboard to External Platform
        oauthProxy -> openshiftOAuth "Authenticates users via OAuth 2.0 (HTTPS/443)"
        backend -> k8sAPI "Manages resources via REST API (HTTPS/443)"
        openshiftRouter -> oauthProxy "Routes external traffic to (HTTPS/8443)"
        odhDashboard -> openshiftConsole "Integrated via ConsoleLink"

        # Dashboard to Internal ODH Systems
        backend -> odhOperator "Reads DataScienceCluster status (API)"
        backend -> notebooks "Creates and manages Notebook resources (API)"
        backend -> kserve "Manages ServingRuntime resources (API)"
        backend -> modelmesh "Manages ModelMesh deployments (API)"
        backend -> pipelines "Integrates with pipeline workflows (HTTPS/8443)"
        backend -> modelRegistry "Manages model metadata (HTTPS/8080)"
        backend -> thanos "Queries performance metrics (HTTPS/9092)"

        # Dashboard to External Services
        backend -> s3Storage "Stores pipeline artifacts and models (HTTPS/443)"

        # Component Dependencies
        notebooks -> k8sAPI "Creates StatefulSets for workbenches"
        kserve -> k8sAPI "Creates inference service deployments"
        modelmesh -> k8sAPI "Creates model serving deployments"
        pipelines -> s3Storage "Stores workflow artifacts"
        kserve -> s3Storage "Loads model artifacts"
        modelmesh -> s3Storage "Loads model artifacts"
    }

    views {
        systemContext odhDashboard "ODHDashboardContext" {
            include *
            autoLayout
        }

        container odhDashboard "ODHDashboardContainers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "API" {
                shape RoundedBox
            }
            element "Security" {
                shape Hexagon
            }
        }
    }
}
