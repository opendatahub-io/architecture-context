workspace {
    model {
        user = person "Data Scientist / Admin" "Uses ODH Dashboard to manage data science workloads and platform configuration"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management dashboard for Red Hat OpenShift AI platform" {
            frontend = container "React Frontend" "Single-page application providing UI for RHOAI" "React 18, PatternFly 5"
            backend = container "Node.js Backend" "REST API server with K8s integration" "Node.js 18, Fastify 4"
            oauthProxy = container "OAuth Proxy" "Authenticates users via OpenShift OAuth" "OpenShift OAuth Proxy"

            oauthProxy -> backend "Proxies authenticated requests" "HTTP/8080"
            frontend -> backend "Makes API calls" "HTTPS/8443"
        }

        # External Dependencies
        k8sAPI = softwareSystem "Kubernetes API Server" "Manages cluster resources and CRDs" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Provides user authentication and authorization" "External"
        prometheus = softwareSystem "Prometheus/Thanos" "Metrics collection and querying" "External"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Container image storage and metadata" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress gateway for external access" "External"

        # Internal ODH/RHOAI Dependencies
        kserve = softwareSystem "KServe" "Serverless ML model serving platform" "Internal ODH"
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook environment controller" "Internal ODH"
        dsc = softwareSystem "DataScienceCluster Operator" "Platform installation and lifecycle" "Internal ODH"
        builds = softwareSystem "OpenShift Builds" "Container image build system" "Internal ODH"
        openshiftConsole = softwareSystem "OpenShift Console" "Cluster management web interface" "Internal ODH"

        # Relationships - User interactions
        user -> odhDashboard "Manages notebooks, models, and platform settings via web browser" "HTTPS/443"

        # Relationships - External dependencies
        odhDashboard -> openshiftOAuth "Authenticates users, validates tokens" "HTTPS/443, OAuth 2.0"
        odhDashboard -> k8sAPI "CRUD operations on CRDs, ConfigMaps, Secrets, etc." "HTTPS/443, ServiceAccount Token"
        odhDashboard -> prometheus "Queries notebook and model serving metrics" "HTTPS/9091, ServiceAccount Token"
        odhDashboard -> imageRegistry "Queries imagestream layer metadata" "HTTPS/443, ServiceAccount Token"
        openshiftRouter -> odhDashboard "Routes external traffic" "HTTPS/8443, TLS Reencrypt"

        # Relationships - Internal ODH dependencies
        odhDashboard -> kserve "Manages ServingRuntimes and InferenceServices" "K8s API, CRD operations"
        odhDashboard -> notebooks "Creates and manages Notebook custom resources" "K8s API, CRD operations"
        odhDashboard -> dsc "Monitors DataScienceCluster status" "K8s API, Watch events"
        odhDashboard -> builds "Triggers custom notebook image builds" "OpenShift Build API"
        odhDashboard -> openshiftConsole "Integrates via ConsoleLink CRD" "K8s API"
        openshiftConsole -> odhDashboard "Displays dashboard link in navigation" "HTTPS/8443"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }

        theme default
    }
}
