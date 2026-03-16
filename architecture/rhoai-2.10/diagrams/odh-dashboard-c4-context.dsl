workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages data science projects, notebooks, and model deployments"
        admin = person "Platform Administrator" "Configures ODH components and manages cluster settings"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based user interface and API gateway for Open Data Hub and RHOAI platform management" {
            frontend = container "Frontend" "React/TypeScript single-page application with PatternFly UI components" "React 18, TypeScript, PatternFly" {
                tags "WebApp"
            }

            backend = container "Backend" "Node.js API gateway that proxies Kubernetes API requests and serves frontend assets" "Node.js 18, Fastify" {
                tags "API"
            }

            oauthProxy = container "OAuth Proxy" "Authentication and authorization enforcement using OpenShift OAuth" "OpenShift OAuth Proxy" {
                tags "Security"
            }
        }

        # External Dependencies (OpenShift Platform)
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster resource management and orchestration" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "User authentication and authorization service" "External"
        prometheusService = softwareSystem "Prometheus" "Metrics collection and querying for model serving and workloads" "External"
        openshiftRoute = softwareSystem "OpenShift Route/Ingress" "External HTTPS access and traffic routing" "External"

        # Internal ODH Components
        dataScienceCluster = softwareSystem "DataScienceCluster" "ODH platform configuration and component management" "Internal ODH"
        dscInit = softwareSystem "DSCInitialization" "Platform initialization status and configuration" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook lifecycle management" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform with autoscaling and traffic management" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage and versioning" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "MLOps workflow orchestration and execution" "Internal ODH"
        trustyAI = softwareSystem "TrustyAI Service" "Model bias detection and explainability metrics" "Internal ODH"

        # Relationships - Users to System
        dataScientist -> odhDashboard "Creates projects, notebooks, and model deployments via web UI"
        admin -> odhDashboard "Configures platform settings and manages components"

        # Relationships - Within ODH Dashboard
        dataScientist -> frontend "Interacts with UI" "HTTPS/443"
        admin -> frontend "Configures settings" "HTTPS/443"
        frontend -> oauthProxy "Sends requests through" "HTTPS/8443"
        oauthProxy -> backend "Forwards authenticated requests to" "HTTP/8080"
        backend -> frontend "Serves static assets to"

        # Relationships - External Dependencies
        oauthProxy -> oauthServer "Authenticates users with" "HTTPS/443, OAuth 2.0"
        backend -> kubernetesAPI "Performs resource CRUD operations on" "HTTPS/443, Service Account Token"
        backend -> prometheusService "Queries metrics from" "HTTP/9091, Bearer Token"
        openshiftRoute -> oauthProxy "Routes external traffic to" "HTTPS/8443, TLS Reencrypt"

        # Relationships - Internal ODH Components
        backend -> dataScienceCluster "Reads component configuration from" "Kubernetes API"
        backend -> dscInit "Checks initialization status of" "Kubernetes API"
        backend -> kubeflowNotebooks "Creates and manages notebook instances in" "Kubernetes API, CRUD"
        backend -> kserve "Configures model serving runtimes in" "Kubernetes API, CRUD"
        backend -> modelRegistry "Manages model registry instances and queries metadata from" "HTTP API + Kubernetes API"
        backend -> dataSciencePipelines "Executes and monitors pipelines via" "HTTP API"
        backend -> trustyAI "Retrieves bias metrics from" "HTTP API"

        # CRD Relationships
        backend -> odhDashboard "Manages configuration via AcceleratorProfile, OdhApplication, OdhDashboardConfig, OdhDocument, OdhQuickStart CRDs"
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
            element "WebApp" {
                shape WebBrowser
                background #4a90e2
                color #ffffff
            }
            element "API" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
            element "Security" {
                shape RoundedBox
                background #f5a623
                color #000000
            }
        }
    }
}
