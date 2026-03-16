workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML workbenches, pipelines, and model serving"
        admin = person "Platform Administrator" "Configures platform settings, manages users, and monitors resources"

        odhDashboard = softwareSystem "ODH Dashboard" "Central web-based UI for managing and interacting with Open Data Hub and Red Hat OpenShift AI platform components" {
            frontend = container "Frontend" "React/PatternFly web application providing user interface" "TypeScript/React" {
                tags "Web Browser"
            }

            backend = container "Backend" "REST API server providing k8s access and service proxying" "Node.js/Fastify" {
                tags "API"
            }

            oauthProxy = container "OAuth Proxy" "Authentication and authorization layer" "OpenShift OAuth Proxy" {
                tags "Security"
            }

            frontend -> backend "Makes API calls to" "HTTP/8080"
            oauthProxy -> backend "Forwards authenticated requests to" "HTTP/8080"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Manages cluster resources and custom resources" "External"
        openShiftOAuth = softwareSystem "OpenShift OAuth" "User authentication and authorization" "External"
        openShiftConsole = softwareSystem "OpenShift Console" "OpenShift web console" "External"
        prometheus = softwareSystem "Prometheus/Thanos" "Metrics collection and querying" "External"

        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook workbench management" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration and execution" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and metadata management" "Internal ODH"
        mlmd = softwareSystem "ML Metadata (MLMD)" "Pipeline metadata and artifact tracking" "Internal ODH"
        trustyAI = softwareSystem "TrustyAI" "Model fairness and bias metrics" "Internal ODH"
        kserve = softwareSystem "KServe" "Serverless model serving platform" "Internal ODH"
        openShiftBuilds = softwareSystem "OpenShift Builds" "Custom notebook image builds" "Internal ODH"

        # User interactions
        dataScientist -> odhDashboard "Manages workbenches, pipelines, models via" "HTTPS/443"
        admin -> odhDashboard "Configures platform settings via" "HTTPS/443"

        # Dashboard to external dependencies
        odhDashboard -> openShiftOAuth "Authenticates users via" "HTTPS/6443"
        odhDashboard -> k8sAPI "Manages resources via" "HTTPS/6443"
        odhDashboard -> prometheus "Queries metrics from" "HTTPS/9091"
        openShiftConsole -> odhDashboard "Links to dashboard via" "ConsoleLink"

        # Dashboard to internal ODH components
        odhDashboard -> kubeflowNotebooks "Manages notebook CRDs" "HTTPS/6443"
        odhDashboard -> dataSciencePipelines "Proxies pipeline API requests to" "HTTPS/8443"
        odhDashboard -> modelRegistry "Proxies model registry API requests to" "HTTP-HTTPS/8080"
        odhDashboard -> mlmd "Proxies ML metadata API requests to" "HTTP-HTTPS/8080"
        odhDashboard -> trustyAI "Proxies bias metrics API requests to" "HTTP-HTTPS/8080"
        odhDashboard -> kserve "Manages serving runtime CRDs" "HTTPS/6443"
        odhDashboard -> openShiftBuilds "Manages custom image builds via" "HTTPS/6443"

        # Deployment
        deploymentEnvironment "Production" {
            deploymentNode "OpenShift Cluster" {
                deploymentNode "Operator Namespace" {
                    deploymentNode "odh-dashboard Pod" {
                        containerInstance oauthProxy
                        containerInstance backend
                        containerInstance frontend
                    }
                }
            }
        }
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

        deployment odhDashboard "Production" "Deployment" {
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
                shape Component
                background #d73027
                color #ffffff
            }
        }
    }
}
