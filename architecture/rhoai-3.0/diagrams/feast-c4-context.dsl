workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates feature definitions and retrieves historical features for model training"
        mlEngineer = person "ML Engineer" "Deploys ML models that consume real-time features from online store"
        admin = person "Platform Administrator" "Manages Feast infrastructure and configures feature stores"

        # Feast System
        feast = softwareSystem "Feast Operator" "Kubernetes operator that deploys and manages Feast feature stores for machine learning workloads" {
            operator = container "Feast Operator" "Reconciles FeatureStore CRs and manages feast service deployments" "Go Operator" {
                controller = component "Controller" "Watches FeatureStore CRs and reconciles desired state"
                webhook = component "Webhook Server" "Validates and mutates FeatureStore CRs (future)"
            }

            onlineStore = container "Online Store Server" "Low-latency serving of real-time features for online inference" "Python/Feast SDK" {
                onlineAPI = component "Online API" "REST endpoints for feature retrieval and push operations"
                onlineCache = component "Online Cache Client" "Interfaces with Redis/Cassandra/DynamoDB"
            }

            offlineStore = container "Offline Store Server" "Serves historical feature data for training and batch inference" "Python/Feast SDK" {
                offlineAPI = component "Offline API" "REST endpoints for historical feature queries"
                offlineEngine = component "Query Engine" "Executes queries against S3/Snowflake/Postgres"
            }

            registry = container "Registry Server" "Manages feature definitions, metadata, and feature store configuration" "Python/Feast SDK" {
                registryAPI = component "Registry API" "gRPC and REST endpoints for registry operations"
                registryStore = component "Registry Storage Client" "Persists metadata to S3/Postgres"
            }

            ui = container "Feast UI" "Web UI for feature discovery, exploration, and monitoring" "Python/React" {
                webUI = component "Web Interface" "React-based UI for feature browsing"
                backendAPI = component "UI Backend API" "Python backend serving UI data"
            }

            cronJob = container "Materialization CronJob" "Executes scheduled feast commands (e.g., materialization)" "Kubernetes CronJob"
        }

        # External Systems
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        objectStorage = softwareSystem "Object Storage" "Cloud storage for feature data (S3, GCS)" "External"
        database = softwareSystem "Database" "Relational database for online store and registry (Postgres, Snowflake)" "External"
        cache = softwareSystem "Cache" "Low-latency key-value store (Redis, Cassandra, DynamoDB)" "External"
        oidcProvider = softwareSystem "OIDC Provider" "Authentication provider (OpenShift OAuth, Keycloak)" "External"
        gitRepo = softwareSystem "Git Repository" "Feature definition source repository" "External"

        # Internal ODH/RHOAI Systems
        serviceMesh = softwareSystem "Service Mesh" "Istio for mTLS and traffic management" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "Internal ODH"
        trustedCA = softwareSystem "ODH Trusted CA Bundle" "Custom CA certificate injection" "Internal ODH"

        # Relationships - Users to Feast
        dataScientist -> feast "Creates FeatureStore CRs, retrieves historical features via Python SDK"
        mlEngineer -> feast "Retrieves real-time features for model inference via REST API"
        admin -> feast "Manages FeatureStore resources via kubectl"

        # Feast Internal Relationships
        operator -> onlineStore "Creates and manages deployments"
        operator -> offlineStore "Creates and manages deployments"
        operator -> registry "Creates and manages deployments"
        operator -> ui "Creates and manages deployments"
        operator -> cronJob "Creates and manages CronJobs"

        onlineStore -> registry "Fetches feature metadata" "gRPC/HTTP"
        offlineStore -> registry "Fetches feature metadata" "gRPC/HTTP"
        ui -> registry "Fetches feature definitions for display" "REST"
        cronJob -> offlineStore "Reads historical features" "HTTP"
        cronJob -> onlineStore "Writes features to online store" "HTTP"
        cronJob -> registry "Reads materialization configuration" "HTTP"

        # Feast to External Systems
        operator -> kubernetes "Manages Kubernetes resources via API" "HTTPS/6443"
        onlineStore -> cache "Stores and retrieves feature values" "Native Protocol"
        offlineStore -> objectStorage "Reads historical feature data" "HTTPS/443"
        offlineStore -> database "Queries historical features" "Postgres/HTTPS"
        registry -> objectStorage "Persists feature registry metadata" "HTTPS/443"
        registry -> database "Persists feature registry metadata" "Postgres/HTTPS"

        onlineStore -> oidcProvider "Validates OIDC tokens" "HTTPS/443"
        offlineStore -> oidcProvider "Validates OIDC tokens" "HTTPS/443"
        registry -> oidcProvider "Validates OIDC tokens" "HTTPS/443"
        ui -> oidcProvider "Validates OIDC tokens" "HTTPS/443"

        registry -> gitRepo "Syncs feature definitions" "HTTPS/SSH"

        # Feast to Internal ODH Systems
        onlineStore -> serviceMesh "Participates in service mesh for mTLS"
        offlineStore -> serviceMesh "Participates in service mesh for mTLS"
        registry -> serviceMesh "Participates in service mesh for mTLS"
        ui -> serviceMesh "Participates in service mesh for mTLS"

        operator -> prometheus "Exposes metrics" "HTTPS/8443"

        onlineStore -> certManager "Obtains TLS certificates"
        offlineStore -> certManager "Obtains TLS certificates"
        registry -> certManager "Obtains TLS certificates"
        ui -> certManager "Obtains TLS certificates"

        onlineStore -> trustedCA "Loads custom CA certificates"
        offlineStore -> trustedCA "Loads custom CA certificates"
        registry -> trustedCA "Loads custom CA certificates"
    }

    views {
        systemContext feast "FeastSystemContext" {
            include *
            autoLayout
        }

        container feast "FeastContainers" {
            include *
            autoLayout
        }

        component operator "FeastOperatorComponents" {
            include *
            autoLayout
        }

        component onlineStore "OnlineStoreComponents" {
            include *
            autoLayout
        }

        component offlineStore "OfflineStoreComponents" {
            include *
            autoLayout
        }

        component registry "RegistryComponents" {
            include *
            autoLayout
        }

        component ui "UIComponents" {
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
                background #7ed321
                color #000000
            }
            element "Component" {
                background #f5a623
                color #000000
            }
        }
    }
}
