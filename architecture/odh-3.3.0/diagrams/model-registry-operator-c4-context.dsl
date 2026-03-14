workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML models in notebooks and pipelines"
        mlEngineer = person "ML Engineer" "Deploys and monitors ML models in production"
        admin = person "Platform Administrator" "Manages Model Registry instances and permissions"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator that deploys and manages Model Registry instances for tracking, versioning, and organizing machine learning models" {
            operator = container "Operator Controller" "Reconciles ModelRegistry CRs and manages service deployments" "Go Operator" {
                reconciler = component "ModelRegistry Reconciler" "Creates Deployments, Services, Routes, NetworkPolicies, and RBAC for each registry instance"
            }

            modelRegistryService = container "Model Registry Service" "Provides REST API and gRPC API for model metadata management" "Python/Go Service" {
                restAPI = component "REST API" "HTTP/HTTPS endpoints for model registration, versioning, and queries"
                grpcAPI = component "gRPC API" "ML Metadata Service for programmatic access"
            }

            oauthProxy = container "OAuth Proxy" "Authenticates and authorizes API requests" "OAuth2 Proxy" "Optional"
            dbProxy = container "Database Proxy" "Secures database connections with TLS" "Sidecar" "Optional"
        }

        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform" "External Platform"
        postgreSQL = softwareSystem "PostgreSQL Database" "Stores model metadata, versions, and lineage" "External Database"
        mySQL = softwareSystem "MySQL Database" "Alternative database backend for model metadata" "External Database"
        oauthService = softwareSystem "OAuth Service" "OpenShift authentication and authorization" "External Auth"
        s3Storage = softwareSystem "S3 Storage" "Stores model artifacts (referenced by URI)" "External Storage"
        prometheus = softwareSystem "Prometheus" "Monitors operator metrics" "External Monitoring"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for browsing and managing registered models" "Internal ODH"
        notebooks = softwareSystem "Notebooks" "Data science workbenches (Jupyter, VS Code)" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Automated ML workflows and model training" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving platform for inference services" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "Model monitoring and explainability service" "Internal ODH"

        # Relationships - Users
        dataScientist -> notebooks "Develops models in"
        dataScientist -> dataSciencePipelines "Creates training pipelines in"
        mlEngineer -> kserve "Deploys models with"
        mlEngineer -> odhDashboard "Monitors models via"
        admin -> modelRegistryOperator "Creates and configures registry instances" "kubectl/YAML"

        # Relationships - Operator
        modelRegistryOperator -> kubernetes "Manages resources in" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        operator -> kubernetes "Creates Deployments, Services, Routes, NetworkPolicies, RBAC"

        # Relationships - Model Registry Service
        modelRegistryService -> postgreSQL "Stores and retrieves model metadata" "PostgreSQL/5432, TLS 1.2+ (optional), Password"
        modelRegistryService -> mySQL "Stores and retrieves model metadata (alternative)" "MySQL/3306, TLS 1.2+ (optional), Password"
        modelRegistryService -> s3Storage "References model artifacts" "HTTPS/443, TLS 1.2+, AWS credentials"

        # Relationships - OAuth Proxy
        oauthProxy -> oauthService "Validates bearer tokens" "HTTPS/443, TLS 1.2+"
        oauthProxy -> modelRegistryService "Forwards authenticated requests" "HTTP/8080"

        # Relationships - ODH Components
        notebooks -> modelRegistryService "Registers models" "HTTPS/8443, Bearer Token"
        dataSciencePipelines -> modelRegistryService "Tracks pipeline models" "HTTPS/8443, Bearer Token"
        kserve -> modelRegistryService "Links InferenceServices to model versions" "HTTPS/8443, Bearer Token"
        odhDashboard -> modelRegistryService "Queries and displays models" "HTTPS/8443, Bearer Token"
        trustyai -> modelRegistryService "Accesses model metadata for monitoring" "HTTPS/8443, Bearer Token"

        # Relationships - Monitoring
        prometheus -> modelRegistryOperator "Scrapes operator metrics" "HTTPS/8443, mTLS"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOperator "Containers" {
            include *
            autoLayout
        }

        component modelRegistryService "Components" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Database" {
                background #6c8ebf
                color #ffffff
                shape Cylinder
            }
            element "External Auth" {
                background #d79b00
                color #ffffff
            }
            element "External Storage" {
                background #d6b656
                color #ffffff
                shape Folder
            }
            element "External Monitoring" {
                background #b85450
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Optional" {
                border dashed
            }
        }

        theme default
    }
}
