workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Uses RHOAI platform to manage data science workloads, notebooks, and model deployments"
        admin = person "Platform Administrator" "Configures dashboard features, manages accelerator profiles, and oversees platform settings"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Red Hat OpenShift AI platform" {
            backend = container "Backend API Server" "Fastify/Node.js REST API providing K8s proxy and business logic" "Node.js 18+, Fastify 4.16.0" {
                apiRouter = component "API Router" "Routes HTTP requests to appropriate handlers" "Fastify"
                k8sProxy = component "Kubernetes Proxy" "Proxies and transforms K8s API requests with user impersonation" "Kubernetes Client 0.12.2"
                configManager = component "Configuration Manager" "Manages dashboard and platform configuration" "TypeScript"
                metricsProxy = component "Metrics Proxy" "Proxies Prometheus queries for model metrics" "Fastify"
            }

            frontend = container "Frontend Web UI" "Single-page application for data science workflows" "React 18.2.0, PatternFly 5.3.x" {
                notebookUI = component "Notebook Management" "UI for launching and managing Jupyter notebooks" "React"
                projectUI = component "Project Management" "UI for creating and managing data science projects" "React"
                modelServingUI = component "Model Serving" "UI for deploying and managing ML models" "React"
                acceleratorUI = component "Accelerator Profiles" "UI for GPU/accelerator configuration" "React"
            }

            oauthProxy = container "OAuth Proxy" "Authentication gateway securing dashboard access" "OpenShift OAuth Proxy"
        }

        %% External Systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane managing all Kubernetes resources" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Centralized authentication and authorization service" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and querying service" "External"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Container image storage and management" "External"

        %% Internal ODH Components
        odhOperator = softwareSystem "ODH Operator" "Manages DataScienceCluster lifecycle and component deployment" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook server operator managing Jupyter workspaces" "Internal ODH"
        kserve = softwareSystem "KServe" "Serverless model serving platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry Operator" "Model metadata and versioning service" "Internal ODH"
        openShiftBuild = softwareSystem "OpenShift Build Service" "Custom notebook image building system" "Internal ODH"

        %% User interactions
        user -> odhDashboard "Launches notebooks, deploys models, manages projects via web UI" "HTTPS/443, Bearer Token"
        admin -> odhDashboard "Configures dashboard features, manages accelerator profiles" "HTTPS/443, Bearer Token"

        %% Dashboard internal flows
        user -> frontend "Interacts with UI"
        admin -> frontend "Configures settings"
        frontend -> oauthProxy "API requests via proxy" "HTTPS/8443"
        oauthProxy -> backend "Forwards authenticated requests" "HTTP/8080 localhost"
        oauthProxy -> oauthServer "Validates tokens, authenticates users" "HTTPS/443, OAuth 2.0"

        backend -> k8sAPI "CRUD operations on K8s resources with user impersonation" "HTTPS/6443, User Bearer Token"
        backend -> prometheus "Query model serving and pipeline metrics" "HTTP/9091, ServiceAccount Token"
        backend -> imageRegistry "Inspect ImageStream layers for custom images" "HTTPS/5000, ServiceAccount Token"

        %% Dashboard to ODH components
        odhDashboard -> odhOperator "Monitors DataScienceCluster and DSCInitialization CRs" "K8s Watch API"
        odhDashboard -> kubeflowNotebooks "Creates and manages Notebook CRs for user workspaces" "K8s API, CRUD"
        odhDashboard -> kserve "Reads ServingRuntime templates for model serving" "K8s API, Read"
        odhDashboard -> modelRegistry "Manages ModelRegistry instances" "K8s API, CRUD"
        odhDashboard -> openShiftBuild "Creates BuildConfigs and Builds for custom images" "K8s API, Create"

        %% ODH components to K8s API
        odhOperator -> k8sAPI "Manages component deployments"
        kubeflowNotebooks -> k8sAPI "Creates notebook pods and services"
        kserve -> k8sAPI "Deploys model serving workloads"
        modelRegistry -> k8sAPI "Manages model registry deployments"
        openShiftBuild -> k8sAPI "Executes image builds"
    }

    views {
        systemContext odhDashboard "ODHDashboardSystemContext" {
            include *
            autoLayout lr
        }

        container odhDashboard "ODHDashboardContainers" {
            include *
            autoLayout lr
        }

        component backend "BackendComponents" {
            include *
            autoLayout lr
        }

        component frontend "FrontendComponents" {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape person
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

            element "External" {
                background #999999
                color #ffffff
            }

            element "Internal ODH" {
                background #7ed321
                color #000000
            }
        }

        themes default
    }
}
