workspace {
    model {
        dataScientist = person "Data Scientist" "Creates feature definitions, retrieves features for ML training and inference"
        mlEngineer = person "ML Engineer" "Deploys and manages FeatureStore instances via kubectl/GitOps"

        feast = softwareSystem "Feast Feature Store" "Kubernetes-native feature store for managing and serving ML features with online/offline stores, registry, and UI" {
            feastOperator = container "Feast Operator" "Manages FeatureStore CRD lifecycle, deploys services, configures RBAC/TLS/HPA" "Go (kubebuilder)" "operator"
            onlineServer = container "Online Server" "Low-latency feature serving via REST/gRPC" "Python (FastAPI)" "server"
            offlineServer = container "Offline Server" "Batch feature retrieval from historical stores" "Python (FastAPI)" "server"
            registryServer = container "Registry Server" "Feature metadata management via gRPC and REST" "Python (gRPC/FastAPI)" "server"
            uiServer = container "Web UI" "Visual exploration of feature store metadata" "TypeScript (React)" "webapp"
            goServer = container "Go Feature Server" "High-performance online feature serving" "Go" "server"
            cronJob = container "Materialization CronJob" "Periodic offline-to-online feature materialization" "kubectl exec" "cronjob"
        }

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys Feast via component manifests" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "Platform"
        openshiftRoutes = softwareSystem "OpenShift Router" "Ingress controller providing external Routes with TLS" "Platform"
        servingCertCtrl = softwareSystem "OpenShift Serving Cert Controller" "Auto-provisions TLS certificates for annotated Services" "Platform"
        prometheusOp = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRDs" "Platform"
        odhNotebooks = softwareSystem "OpenDataHub Notebooks" "Jupyter notebook platform for data science (kubeflow.org)" "Internal ODH"

        # External Dependencies
        oidcProvider = softwareSystem "OIDC Provider" "Token validation via JWKS discovery (Keycloak, Azure AD)" "External"
        redis = softwareSystem "Redis" "In-memory data store for online feature serving" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline feature storage" "External"
        dynamodb = softwareSystem "AWS DynamoDB" "Managed NoSQL database for online feature storage" "External"
        bigquery = softwareSystem "Google BigQuery" "Data warehouse for offline feature storage" "External"
        snowflake = softwareSystem "Snowflake" "Cloud data platform for offline store and registry" "External"
        s3gcs = softwareSystem "S3/GCS Object Storage" "Object storage for registry persistence" "External"
        milvus = softwareSystem "Milvus" "Vector database for similarity search features" "External"
        openlineage = softwareSystem "OpenLineage API" "Data lineage tracking service" "External"

        # Relationships - Users
        dataScientist -> feast "Retrieves features, pushes data, explores metadata" "HTTPS/443, OIDC Bearer"
        mlEngineer -> feast "Creates/manages FeatureStore CRs" "kubectl, HTTPS/443"

        # Relationships - Internal containers
        feastOperator -> k8sAPI "CRUD on managed resources (Deployments, Services, Routes, RBAC)" "HTTPS/443, SA token"
        feastOperator -> registryServer "Fetches permissions for RBAC sync" "HTTP/6572, Intra-comm JWT"
        feastOperator -> servingCertCtrl "Annotates Services for TLS cert provisioning" "Service annotation"
        feastOperator -> prometheusOp "Creates ServiceMonitor CRDs" "K8s API"
        feastOperator -> odhNotebooks "Watches Notebooks, injects feast-config ConfigMap" "K8s API watch"

        onlineServer -> redis "Read/write feature vectors" "TCP/6379, Password"
        onlineServer -> postgresql "Read/write feature vectors" "TCP/5432, User/Pass"
        onlineServer -> dynamodb "Read/write feature vectors" "HTTPS/443, AWS IAM"
        onlineServer -> milvus "Vector similarity search" "gRPC/19530"
        onlineServer -> oidcProvider "Validate Bearer tokens" "HTTPS/443, JWKS"

        offlineServer -> postgresql "Read historical features" "TCP/5432, User/Pass"
        offlineServer -> bigquery "Read historical features" "HTTPS/443, GCP SA"
        offlineServer -> snowflake "Read historical features" "HTTPS/443, User/Pass"
        offlineServer -> oidcProvider "Validate Bearer tokens" "HTTPS/443, JWKS"

        registryServer -> s3gcs "Persist registry metadata" "HTTPS/443, IAM/SA creds"
        registryServer -> postgresql "Persist registry metadata" "TCP/5432, User/Pass"
        registryServer -> snowflake "Persist registry metadata" "HTTPS/443, User/Pass"
        registryServer -> oidcProvider "Validate Bearer tokens" "HTTPS/443, JWKS"

        cronJob -> k8sAPI "kubectl exec into Feast pod" "HTTPS/443, SA token"

        # Relationships - Platform
        rhodsOperator -> feast "Deploys operator via Kustomize manifests" "Kustomize"
        openshiftRoutes -> feast "Routes external traffic to ClusterIP services" "TLS ReEncrypt"
        dataScientist -> odhNotebooks "Uses Jupyter notebooks with auto-injected Feast config" "HTTPS"

        onlineServer -> openlineage "Emit data lineage events" "HTTP/HTTPS, API key"
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

        styles {
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "operator" {
                shape Hexagon
                background #4a90e2
            }
            element "server" {
                shape RoundedBox
                background #50c878
            }
            element "webapp" {
                shape WebBrowser
                background #f5a623
            }
            element "cronjob" {
                shape Circle
                background #e8e8e8
                color #333333
            }
        }
    }
}
