workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and manages ML workloads, notebooks, and model deployments"
        admin = person "Platform Administrator" "Manages ODH/RHOAI platform configuration and user access"

        # ODH Dashboard System
        odhDashboard = softwareSystem "ODH Dashboard" "Web-based user interface for managing Open Data Hub and Red Hat OpenShift AI platform components" {
            backend = container "Backend API Server" "Provides REST API services for dashboard operations" "Node.js/Fastify" {
                apiRoutes = component "API Routes" "40+ REST endpoints for platform management" "Fastify Routes"
                k8sClient = component "Kubernetes Client" "Interacts with K8s API and custom resources" "@kubernetes/client-node"
                authMiddleware = component "Auth Middleware" "Validates user tokens and enforces RBAC" "Fastify Middleware"
            }
            frontend = container "Frontend Web UI" "Single-page application for user interactions" "React/TypeScript/PatternFly"
            oauthProxy = container "OAuth Proxy" "OpenShift OAuth authentication and HTTPS termination" "oauth-proxy sidecar"
        }

        # External Systems - OpenShift/Kubernetes
        k8sAPI = softwareSystem "Kubernetes API Server" "Manages cluster resources and custom resources" "OpenShift/Kubernetes"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Provides user authentication and authorization" "OpenShift"
        openShiftConsole = softwareSystem "OpenShift Console" "Web console for cluster administration" "OpenShift"

        # External Systems - Monitoring
        thanosQuerier = softwareSystem "Thanos Querier" "Provides Prometheus metrics aggregation and querying" "OpenShift Monitoring"

        # Internal ODH Components
        odhOperator = softwareSystem "OpenDataHub Operator" "Manages DataScienceCluster and platform lifecycle" "Internal ODH"
        notebookController = softwareSystem "Kubeflow Notebook Controller" "Manages Jupyter notebook workbench lifecycle" "Internal ODH"
        kserve = softwareSystem "KServe" "Serverless model serving platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning" "Internal ODH"
        odhModelController = softwareSystem "ODH Model Controller" "Manages serving runtimes and model deployments" "Internal ODH"
        nimOperator = softwareSystem "NVIDIA NIM Operator" "Manages NVIDIA NIM accounts and inference" "Internal ODH"

        # External Systems - Storage/Registry
        imageRegistry = softwareSystem "OpenShift Image Registry" "Container image storage and management" "OpenShift"
        s3Storage = softwareSystem "S3 Storage" "Model artifact and data storage" "External"

        # Relationships - Users to Dashboard
        dataScientist -> odhDashboard "Creates notebooks, deploys models, manages projects" "HTTPS/443"
        admin -> odhDashboard "Configures platform, manages accelerators, controls features" "HTTPS/443"

        # Relationships - Dashboard Containers
        dataScientist -> frontend "Interacts with UI" "HTTPS/443"
        admin -> frontend "Configures platform settings" "HTTPS/443"
        frontend -> oauthProxy "Routes all requests through" "HTTPS/8443"
        oauthProxy -> backend "Forwards authenticated requests" "HTTP/8080"
        oauthProxy -> oauthServer "Authenticates users" "OAuth 2.0/HTTPS"

        # Relationships - Backend Components
        apiRoutes -> authMiddleware "Validates requests"
        apiRoutes -> k8sClient "Performs resource operations"
        k8sClient -> k8sAPI "Creates, reads, updates, deletes resources" "HTTPS/443"

        # Relationships - Dashboard to OpenShift
        backend -> k8sAPI "Manages K8s resources (Pods, Services, ConfigMaps, Secrets, CRDs)" "HTTPS/443"
        backend -> oauthServer "Validates user tokens" "HTTPS/443"
        odhDashboard -> openShiftConsole "Integrates via ConsoleLink CRD" "K8s API"

        # Relationships - Dashboard to Monitoring
        backend -> thanosQuerier "Queries metrics for dashboard analytics" "HTTPS/9092"

        # Relationships - Dashboard to ODH Components
        backend -> odhOperator "Queries DataScienceCluster and DSCInitialization status" "K8s API"
        backend -> notebookController "Creates and manages Notebook CRs" "K8s API/HTTPS"
        backend -> kserve "Queries InferenceService status" "K8s API"
        backend -> modelRegistry "Manages ModelRegistry CRs and API calls" "K8s API/HTTPS/443"
        backend -> odhModelController "Manages ServingRuntime templates" "K8s API"
        backend -> nimOperator "Manages NIM Account CRs" "K8s API"

        # Relationships - Dashboard to Storage/Registry
        backend -> imageRegistry "Queries notebook image metadata and manages builds" "HTTPS/443"
        backend -> s3Storage "Indirectly via workloads (notebooks, models)" "HTTPS/443"
    }

    views {
        systemContext odhDashboard "SystemContext" {
            include *
            autoLayout
            description "System context diagram for ODH Dashboard showing external users and integrated systems"
        }

        container odhDashboard "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal structure of ODH Dashboard"
        }

        component backend "BackendComponents" {
            include *
            autoLayout
            description "Component diagram showing backend API server structure"
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "OpenShift/Kubernetes" {
                background #e74c3c
                color #ffffff
            }
            element "OpenShift" {
                background #e74c3c
                color #ffffff
            }
            element "OpenShift Monitoring" {
                background #f39c12
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
        }

        theme default
    }
}
