workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, trains models, and deploys ML services"
        mlEngineer = person "ML Engineer" "Manages model serving, monitors deployments, and optimizes performance"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based console for Red Hat OpenShift AI and Open Data Hub platform" {
            frontend = container "Frontend" "User interface for data science workflows" "React 18.2.0 + PatternFly 6.4.0" {
                genAiPlugin = component "GenAI Plugin" "GenAI studio and LLM serving UI" "Module Federation"
                modelRegistryPlugin = component "Model Registry Plugin" "Model registry UI components" "Module Federation"
                maasPlugin = component "MaaS Plugin" "Model-as-a-Service UI" "Module Federation"
            }
            backend = container "Backend" "REST API server and K8s API proxy" "Node.js 22 + Fastify 4.28.1" {
                apiRouter = component "API Router" "Routes API requests to handlers" "Fastify"
                k8sProxy = component "K8s Proxy" "Proxies requests to Kubernetes API" "@kubernetes/client-node"
                metricsProxy = component "Metrics Proxy" "Proxies Prometheus queries" "HTTP Client"
            }
            rbacProxy = container "kube-rbac-proxy" "OAuth authentication and authorization" "Go Sidecar"
        }

        k8s = softwareSystem "Kubernetes API Server" "Manages cluster resources and orchestration" "External"
        openShiftOAuth = softwareSystem "OpenShift OAuth" "User authentication and token management" "External"
        thanos = softwareSystem "Thanos Querier" "Prometheus metrics aggregation and querying" "External"

        kserve = softwareSystem "KServe" "Serverless model inference platform" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook management" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata and versioning" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Manages ODH platform installation and configuration" "Internal ODH"
        feastRegistry = softwareSystem "Feast" "Feature store for ML feature engineering" "Internal ODH"
        buildService = softwareSystem "OpenShift Build Service" "Container image building and management" "External"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Container image storage and distribution" "External"

        dataScientist -> odhDashboard "Creates notebooks, explores data, trains models via web UI"
        mlEngineer -> odhDashboard "Deploys models, monitors performance, manages serving via web UI"

        frontend -> backend "API calls" "HTTPS/8080"
        rbacProxy -> backend "Proxies authenticated requests with user headers" "HTTP/8080"
        backend -> k8sProxy "Routes K8s operations"
        k8sProxy -> k8s "CRUD operations for all resources" "HTTPS/6443"
        backend -> metricsProxy "Routes metrics queries"
        metricsProxy -> thanos "PromQL queries" "HTTPS/9092"

        rbacProxy -> openShiftOAuth "Validates OAuth tokens" "HTTPS/6443"

        backend -> kserve "Manages InferenceServices via K8s API" "HTTPS/6443"
        backend -> kubeflowNotebooks "Creates and manages Notebook CRs" "HTTPS/6443"
        backend -> modelRegistry "Proxies model registry operations" "HTTP/HTTPS 8080"
        backend -> odhOperator "Reads DataScienceCluster status" "HTTPS/6443"
        backend -> feastRegistry "Proxies feature store operations" "HTTP/HTTPS 8080"
        backend -> buildService "Triggers notebook image builds" "HTTPS/6443"
        backend -> imageRegistry "Inspects image layers and metadata" "HTTPS/6443"
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

        component frontend "FrontendComponents" {
            include *
            autoLayout
        }

        component backend "BackendComponents" {
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
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #f5a623
                color #000000
            }
            element "Component" {
                background #9b59b6
                color #ffffff
            }
        }

        theme default
    }
}
