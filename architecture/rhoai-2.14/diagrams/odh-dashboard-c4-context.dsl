workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates notebooks, trains models, and deploys inference services"
        mlOpsEngineer = person "MLOps Engineer" "Manages model serving deployments and monitors production models"
        administrator = person "Platform Administrator" "Configures ODH/RHOAI components and manages cluster resources"

        # Main System
        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for RHOAI/ODH data science platform" {
            tags "Internal ODH"

            # Containers
            oauthProxy = container "OAuth Proxy" "Handles OpenShift authentication" "OpenShift OAuth Proxy" {
                tags "Authentication"
            }

            backend = container "Backend API" "REST API for Kubernetes resource management" "Node.js/Fastify" {
                tags "Backend"
            }

            frontend = container "Frontend SPA" "User interface for dashboard" "React/TypeScript/PatternFly" {
                tags "Frontend"
            }

            k8sClient = container "Kubernetes Client" "K8s API communication" "@kubernetes/client-node" {
                tags "Library"
            }
        }

        # External Systems - Required
        openShiftOAuth = softwareSystem "OpenShift OAuth Server" "User authentication and authorization" {
            tags "External Required"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster resource management and RBAC" {
            tags "External Required"
        }

        # External Systems - Optional
        thanos = softwareSystem "Thanos Querier" "Prometheus metrics aggregation for monitoring" {
            tags "External Optional"
        }

        imageRegistry = softwareSystem "OpenShift Image Registry" "Container image storage and metadata" {
            tags "External Optional"
        }

        builds = softwareSystem "OpenShift Builds" "Custom notebook image building" {
            tags "External Optional"
        }

        # Internal ODH Components
        notebookController = softwareSystem "Notebook Controller" "Manages Jupyter notebook lifecycle" {
            tags "Internal ODH"
        }

        kserve = softwareSystem "KServe" "Serverless model serving platform" {
            tags "Internal ODH"
        }

        modelRegistry = softwareSystem "Model Registry" "ML model metadata and versioning" {
            tags "Internal ODH"
        }

        dscOperator = softwareSystem "Data Science Cluster Operator" "ODH/RHOAI platform lifecycle management" {
            tags "Internal ODH"
        }

        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration (Kubeflow Pipelines)" {
            tags "Internal ODH"
        }

        odhOperator = softwareSystem "ODH Operator" "Component installation and configuration" {
            tags "Internal ODH"
        }

        # Relationships - Users to Dashboard
        dataScientist -> odhDashboard "Creates notebooks, views models, runs pipelines" "HTTPS/443"
        mlOpsEngineer -> odhDashboard "Deploys models, monitors serving metrics" "HTTPS/443"
        administrator -> odhDashboard "Configures components, manages users" "HTTPS/443"

        # Relationships - Dashboard containers
        dataScientist -> oauthProxy "Accesses via web browser" "HTTPS/443"
        mlOpsEngineer -> oauthProxy "Accesses via web browser" "HTTPS/443"
        administrator -> oauthProxy "Accesses via web browser" "HTTPS/443"

        oauthProxy -> openShiftOAuth "Authenticates users" "HTTPS/443"
        oauthProxy -> backend "Proxies authenticated requests" "HTTP/8080"
        backend -> frontend "Serves static assets"
        backend -> k8sClient "Uses for K8s operations"
        k8sClient -> kubernetesAPI "Manages resources via REST API" "HTTPS/6443"

        # Relationships - Dashboard to external systems
        odhDashboard -> openShiftOAuth "Authenticates users via OAuth 2.0" "HTTPS/443"
        odhDashboard -> kubernetesAPI "Creates/reads/updates resources, enforces RBAC" "HTTPS/6443"
        odhDashboard -> thanos "Queries model serving metrics" "HTTP/9092"
        odhDashboard -> imageRegistry "Retrieves custom notebook image metadata" "HTTPS/5000"
        odhDashboard -> builds "Triggers custom image builds" "HTTPS/6443 (via K8s API)"

        # Relationships - Dashboard to internal ODH components
        odhDashboard -> notebookController "Creates and monitors Notebook CRs" "HTTPS/6443 (via K8s API)"
        odhDashboard -> kserve "Monitors InferenceService status" "HTTPS/6443 (via K8s API)"
        odhDashboard -> modelRegistry "Manages ModelRegistry CRs" "HTTPS/6443 (via K8s API)"
        odhDashboard -> dscOperator "Reads DataScienceCluster config" "HTTPS/6443 (via K8s API)"
        odhDashboard -> pipelines "Proxies pipeline API requests" "HTTPS/6443 (via K8s API)"
        odhDashboard -> odhOperator "Watches component status via CRs" "HTTPS/6443 (via K8s API)"
    }

    views {
        systemContext odhDashboard "ODHDashboardSystemContext" {
            include *
            autoLayout lr
            title "ODH Dashboard - System Context"
            description "High-level view of ODH Dashboard and its interactions with users and external systems"
        }

        container odhDashboard "ODHDashboardContainers" {
            include *
            autoLayout lr
            title "ODH Dashboard - Container View"
            description "Internal structure of ODH Dashboard showing authentication, backend, and frontend components"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }

            element "Internal ODH" {
                background #7ed321
                color #000000
            }

            element "External Required" {
                background #999999
                color #ffffff
            }

            element "External Optional" {
                background #cccccc
                color #000000
            }

            element "Authentication" {
                background #4a90e2
                color #ffffff
            }

            element "Backend" {
                background #4a90e2
                color #ffffff
            }

            element "Frontend" {
                background #4a90e2
                color #ffffff
            }

            element "Library" {
                background #6c9bd1
                color #ffffff
            }
        }
    }
}
