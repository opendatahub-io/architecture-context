workspace {
    name "Feast Operator Architecture"
    description "C4 model for Feast Operator in RHOAI 3.2"

    model {
        // Actors
        dataScientist = person "Data Scientist" "Creates and manages feature stores for ML model training and serving"
        mlEngineer = person "ML Engineer" "Deploys ML applications that consume features from online store"
        platformAdmin = person "Platform Administrator" "Manages Feast operator deployment and monitors health"

        // Main System
        feast = softwareSystem "Feast Operator" "Kubernetes operator that deploys and manages Feast feature store instances for machine learning workloads" {
            controller = container "Feast Operator Controller" "Reconciles FeatureStore CRs and manages lifecycle of Feast deployments" "Go, Kubernetes Operator" {
                reconciler = component "FeatureStore Reconciler" "Watches FeatureStore CRs and reconciles desired state" "Go Controller"
                deployer = component "Service Deployer" "Creates and manages Deployments, Services, ConfigMaps" "Go"
                notebookIntegrator = component "Notebook Integrator" "Injects Feast client configs into Kubeflow notebooks" "Go"
            }

            metricsService = container "Metrics Service" "Exposes Prometheus metrics with RBAC authentication" "kube-rbac-proxy" {
                proxy = component "RBAC Proxy" "Validates bearer tokens via TokenReview/SubjectAccessReview" "kube-rbac-proxy"
            }

            registryService = container "Registry Service" "Stores and serves feature store metadata (feature definitions, data sources)" "Python 3.11, gRPC/REST" {
                grpcServer = component "gRPC Server" "Feature registry gRPC API" "Python gRPC"
                restServer = component "REST Server" "Feature registry REST API" "Python FastAPI"
                metadataStore = component "Metadata Store" "Persists feature definitions" "File/SQL/S3"
            }

            onlineStore = container "Online Store" "Low-latency serving of pre-computed features for real-time inference" "Python 3.11, HTTP" {
                apiServer = component "API Server" "Feature retrieval HTTP API" "Python FastAPI"
                featureCache = component "Feature Cache" "In-memory feature cache for low latency" "Python"
                dbConnector = component "Database Connector" "Connects to SQLite/PostgreSQL/Cassandra" "Python"
            }

            offlineStore = container "Offline Store" "Processes historical feature data for batch scoring and model training" "Python 3.11, HTTP" {
                apiServer2 = component "API Server" "Historical feature processing API" "Python FastAPI"
                dataProcessor = component "Data Processor" "Processes historical features from Parquet/DuckDB" "Python"
            }

            webUI = container "Web UI" "Web interface for exploring features and feature store configurations" "Python 3.11, HTTP" {
                frontend = component "Web Frontend" "Feature exploration UI" "Python Flask/React"
            }
        }

        // External Kubernetes Platform
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform (1.11.3+)" "External Platform" {
            apiServer = container "API Server" "Kubernetes API for resource management" "Go"
            etcd = container "etcd" "Kubernetes state storage" "etcd"
        }

        // Internal ODH Components
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook environment for data science" "Internal ODH" {
            notebookController = container "Notebook Controller" "Manages notebook pod lifecycle" "Go"
        }

        openShiftRouter = softwareSystem "OpenShift Routes" "External access to services via Routes" "Internal ODH (OpenShift)" {
            routeController = container "Route Controller" "Manages Route resources" "Go"
        }

        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "Internal ODH" {
            prometheus = container "Prometheus" "Metrics scraping and storage" "Prometheus"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing ODH components" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows" "Internal ODH"

        // External Services
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for registry persistence and model artifacts" "External Service"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline/registry storage" "External Service"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for feature data" "External Service"
        cassandra = softwareSystem "Cassandra" "Distributed database for online store" "External Service"
        gitServer = softwareSystem "Git Repository" "Feature repository for feature definitions (Git-based)" "External Service"

        // Relationships - User interactions
        dataScientist -> feast "Creates FeatureStore CRs, queries feature metadata" "kubectl/UI"
        mlEngineer -> feast "Retrieves features for ML inference" "HTTP/gRPC API"
        platformAdmin -> feast "Monitors operator health, manages deployments" "kubectl/Prometheus"

        // Feast internal relationships
        feast -> kubernetes "Manages Deployments, Services, CRDs" "HTTPS/6443 (TLS 1.2+, SA Token)"
        controller -> registryService "Creates and manages" "Kubernetes API"
        controller -> onlineStore "Creates and manages" "Kubernetes API"
        controller -> offlineStore "Creates and manages" "Kubernetes API"
        controller -> webUI "Creates and manages" "Kubernetes API"

        // Integration with ODH components
        feast -> kubeflowNotebooks "Injects Feast client ConfigMaps" "CRD Watch"
        feast -> openShiftRouter "Creates Routes for external access" "route.openshift.io/v1 API"
        prometheusOperator -> feast "Scrapes metrics" "HTTPS/8443 (TLS 1.2+, Bearer Token)"

        // Optional dashboard integration
        odhDashboard -> feast "Manages FeatureStores (potential)" "Kubernetes API"
        dsPipelines -> feast "Integrates feature retrieval (potential)" "HTTP API"

        // External service connections
        registryService -> s3Storage "Persists registry metadata" "HTTPS/443 (TLS 1.2+, AWS IAM)"
        onlineStore -> postgresql "Queries feature values" "PostgreSQL/5432 (TLS 1.2+ optional)"
        onlineStore -> cassandra "Queries feature values" "CQL/9042 (TLS 1.2+ optional)"
        offlineStore -> snowflake "Queries historical features" "HTTPS/443 (TLS 1.2+, OAuth)"
        controller -> gitServer "Syncs feature repository" "HTTPS/443 or SSH/22"

        // ML Application flow
        mlApp = softwareSystem "ML Application" "Production ML models consuming features" "External"
        mlApp -> onlineStore "Retrieves real-time features" "HTTP/HTTPS (6566/6567)"
    }

    views {
        systemContext feast "FeastSystemContext" {
            include *
            autoLayout lr
            description "System context diagram for Feast Operator showing external dependencies and integrations"
        }

        container feast "FeastContainers" {
            include *
            autoLayout lr
            description "Container diagram showing Feast Operator internal components"
        }

        component controller "FeastControllerComponents" {
            include *
            autoLayout lr
            description "Component diagram for Feast Operator Controller"
        }

        component registryService "FeastRegistryComponents" {
            include *
            autoLayout lr
            description "Component diagram for Feast Registry Service"
        }

        component onlineStore "FeastOnlineStoreComponents" {
            include *
            autoLayout lr
            description "Component diagram for Feast Online Store"
        }

        dynamic feast "FeatureStoreCreation" "Feature Store Creation Flow" {
            dataScientist -> kubernetes "1. Creates FeatureStore CR"
            kubernetes -> controller "2. Watch notification"
            controller -> kubernetes "3. Creates Deployments, Services, PVCs"
            controller -> registryService "4. Registry deployment created"
            controller -> onlineStore "5. Online store deployment created"
            controller -> offlineStore "6. Offline store deployment created"
            controller -> webUI "7. Web UI deployment created"
            autoLayout lr
            description "Sequence showing how a FeatureStore CR is created and reconciled"
        }

        dynamic feast "FeatureRetrieval" "Feature Retrieval Flow" {
            mlApp -> onlineStore "1. POST /online/features"
            onlineStore -> postgresql "2. Query feature values"
            postgresql -> onlineStore "3. Feature data"
            onlineStore -> mlApp "4. JSON response (low-latency)"
            autoLayout lr
            description "Sequence showing real-time feature retrieval from online store"
        }

        styles {
            element "Software System" {
                shape roundedbox
                background #1168bd
                color #ffffff
            }
            element "Container" {
                shape roundedbox
                background #438dd5
                color #ffffff
            }
            element "Component" {
                shape component
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal ODH (OpenShift)" {
                background #ee0000
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "External" {
                background #d35400
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
