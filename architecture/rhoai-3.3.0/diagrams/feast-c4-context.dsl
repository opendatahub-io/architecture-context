workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML features for training and inference"
        mlEngineer = person "ML Engineer" "Deploys models that consume features for real-time inference"
        dataEngineer = person "Data Engineer" "Manages feature definitions and materialization pipelines"

        feast = softwareSystem "Feast Feature Store" "Open-source feature store for managing, serving, and tracking ML features with consistent access for training and serving" {
            operator = container "Feast Operator" "Manages FeatureStore CR lifecycle, deploying and configuring Feast services" "Go Operator" {
                tags "Operator"
            }

            onlineServer = container "Online Feature Server" "Serves features for real-time inference with low latency" "Python FastAPI + gRPC" {
                tags "FeatureServer"
            }

            offlineServer = container "Offline Feature Server" "Serves historical features for model training and batch scoring" "Python FastAPI" {
                tags "FeatureServer"
            }

            registryServer = container "Registry Server" "Manages feature metadata (entities, feature views, data sources)" "Python gRPC + REST" {
                tags "Registry"
            }

            uiServer = container "UI Server" "Web interface for feature discovery and exploration" "React/TypeScript" {
                tags "UI"
            }
        }

        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform" "External"

        postgresql = softwareSystem "PostgreSQL" "Optional persistent storage for registry and online features" "External Database"
        redis = softwareSystem "Redis" "Optional high-performance online feature storage" "External Cache"
        s3 = softwareSystem "S3 / Object Storage" "Stores offline features and registry metadata" "External Storage"

        oidcProvider = softwareSystem "OIDC Provider" "Authenticates users and validates JWT tokens" "External Auth"
        prometheus = softwareSystem "Prometheus" "Monitors feature server performance and operator health" "External Monitoring"

        openshiftRoutes = softwareSystem "OpenShift Routes" "Provides external access to feature servers and UI" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook environment for data science" "Internal ODH"
        certManager = softwareSystem "cert-manager" "Provisions TLS certificates for services" "Internal ODH"

        odhDashboard = softwareSystem "ODH Dashboard" "Unified dashboard for managing RHOAI components" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows" "Internal ODH"
        modelServing = softwareSystem "Model Serving" "KServe or ModelMesh for model deployment" "Internal ODH"

        # User interactions
        dataScientist -> feast "Defines features, retrieves training data" "Feast SDK/CLI"
        mlEngineer -> feast "Retrieves real-time features for inference" "gRPC/HTTP API"
        dataEngineer -> feast "Manages feature pipelines and materialization" "Feast SDK/CLI"

        # Feast internal relationships
        operator -> kubernetes "Manages Deployments, Services, ConfigMaps, Routes" "HTTPS/6443"
        operator -> onlineServer "Creates and configures" "Reconciliation"
        operator -> offlineServer "Creates and configures" "Reconciliation"
        operator -> registryServer "Creates and configures" "Reconciliation"
        operator -> uiServer "Creates and configures" "Reconciliation"

        onlineServer -> registryServer "Fetches feature metadata" "gRPC/6570-6571"
        offlineServer -> registryServer "Fetches feature metadata" "gRPC/6570-6571"
        uiServer -> registryServer "Queries feature registry" "REST API/6572-6573"

        # External dependencies
        onlineServer -> postgresql "Stores online features" "PostgreSQL/5432 (optional)"
        onlineServer -> redis "Stores online features" "Redis/6379 (optional)"
        offlineServer -> s3 "Reads historical feature data" "HTTPS/443"
        registryServer -> postgresql "Stores feature metadata" "PostgreSQL/5432 (optional)"
        registryServer -> s3 "Stores feature metadata" "HTTPS/443 (optional)"

        # Authentication and monitoring
        onlineServer -> oidcProvider "Validates JWT tokens" "HTTPS/443 (optional)"
        offlineServer -> oidcProvider "Validates JWT tokens" "HTTPS/443 (optional)"
        registryServer -> oidcProvider "Validates JWT tokens" "HTTPS/443 (optional)"

        prometheus -> onlineServer "Scrapes metrics" "HTTP/8000"
        prometheus -> offlineServer "Scrapes metrics" "HTTP/8000"
        prometheus -> operator "Scrapes operator metrics" "HTTPS/8443"

        # OpenShift/ODH integrations
        operator -> openshiftRoutes "Creates Routes for external access" "route.openshift.io API"
        operator -> kubeflowNotebooks "Injects client configuration" "ConfigMap injection"
        operator -> certManager "Requests TLS certificates" "cert-manager API (optional)"

        odhDashboard -> feast "Manages FeatureStore instances via UI" "Kubernetes API"
        pipelines -> feast "Retrieves features for training pipelines" "Feast SDK"
        modelServing -> onlineServer "Fetches features for model inference" "gRPC/HTTP API"
    }

    views {
        systemContext feast "SystemContext" {
            include *
            autoLayout
        }

        container feast "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
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
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "FeatureServer" {
                background #50c878
                color #000000
            }
            element "Registry" {
                background #f5a623
                color #000000
            }
            element "UI" {
                background #bd10e0
                color #ffffff
            }
            element "External Database" {
                background #336791
                color #ffffff
            }
            element "External Cache" {
                background #dc382d
                color #ffffff
            }
            element "External Storage" {
                background #ff9900
                color #000000
            }
            element "External Auth" {
                background #eb5424
                color #ffffff
            }
            element "External Monitoring" {
                background #e6522c
                color #ffffff
            }
        }

        theme default
    }
}
