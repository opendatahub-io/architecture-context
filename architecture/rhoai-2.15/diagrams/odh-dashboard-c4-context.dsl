workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages data science projects, notebooks, and model deployments"
        admin = person "Platform Administrator" "Manages ODH/RHOAI platform configuration and user access"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Open Data Hub and Red Hat OpenShift AI" {
            frontend = container "React Frontend" "User interface for dashboard" "React 18 + PatternFly 5" {
                tags "Web Browser"
            }
            backend = container "Node.js Backend" "REST API server for Kubernetes operations" "Node.js 18 + Fastify" {
                tags "API"
            }
            oauthProxy = container "OAuth Proxy" "Authentication and authorization proxy" "OpenShift OAuth Proxy" {
                tags "Security"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Cluster identity provider and SSO" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Container image storage" "External"

        dscOperator = softwareSystem "DataScienceCluster Operator" "Platform component lifecycle management" "Internal ODH"
        dsciOperator = softwareSystem "DSCInitialization Operator" "Platform initialization and configuration" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform for ML inference" "Internal ODH"
        notebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook lifecycle management" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata and versioning" "Internal ODH"
        console = softwareSystem "OpenShift Console" "OpenShift web console" "External"
        isvPartners = softwareSystem "ISV Partner Applications" "Third-party integrations (NVIDIA, Anaconda, etc.)" "External"

        %% User interactions
        dataScientist -> odhDashboard "Manages projects, notebooks, models via web UI"
        admin -> odhDashboard "Configures platform settings and permissions"

        %% Dashboard internal
        dataScientist -> frontend "Uses web interface" "HTTPS/443"
        admin -> frontend "Uses web interface" "HTTPS/443"
        frontend -> oauthProxy "Authenticated via" "HTTPS/8443"
        oauthProxy -> backend "Proxies requests to" "HTTP/8080"

        %% Authentication
        oauthProxy -> oauthServer "Authenticates users via OAuth 2.0" "HTTPS/443"

        %% Backend integrations
        backend -> k8sAPI "Manages Kubernetes resources" "HTTPS/443, ServiceAccount Token"
        backend -> prometheus "Queries component metrics" "HTTPS/9091, ServiceAccount Token"
        backend -> imageRegistry "Manages notebook images" "HTTPS/443, ServiceAccount Token"

        %% Component integrations
        backend -> dscOperator "Monitors platform component status" "K8s Watch API/443"
        backend -> dsciOperator "Reads platform initialization config" "K8s Watch API/443"
        backend -> kserve "Manages inference services" "K8s CRUD API/443"
        backend -> notebooks "Creates and manages notebook pods" "K8s CRUD API/443"
        backend -> modelRegistry "Manages model registry instances" "K8s CRUD API/443"
        backend -> console "Registers dashboard link" "K8s API/443"
        backend -> isvPartners "Validates ISV integrations" "HTTPS/443"

        %% Monitoring
        prometheus -> oauthProxy "Scrapes /metrics endpoint" "HTTPS/443, no auth"
    }

    views {
        systemContext odhDashboard "ODH-Dashboard-SystemContext" {
            include *
            autoLayout
        }

        container odhDashboard "ODH-Dashboard-Containers" {
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
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "API" {
                shape Hexagon
            }
            element "Security" {
                shape Pipe
            }
        }

        themes default
    }

    configuration {
        scope softwaresystem
    }
}
