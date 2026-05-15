workspace {
    model {
        dataScientist = person "Data Scientist" "Creates feature definitions, deploys FeatureStore CRs, and queries online features for ML models"
        mlEngineer = person "ML Engineer" "Manages feature pipelines, materialization schedules, and production feature serving"
        platformAdmin = person "Platform Admin" "Deploys and configures the Feast operator via RHOAI platform operator"

        feast = softwareSystem "Feast Feature Store" "Operator-managed feature store platform providing online/offline feature serving, registry, and materialization for ML workloads" {
            feastOperator = container "feast-operator" "Watches FeatureStore CRDs, deploys feature server pods, manages TLS/auth/scaling/materialization CronJobs, integrates with ODH Notebooks" "Go Operator (controller-runtime)" "operator"
            featureServerPython = container "Feature Server (Python)" "Serves online features via REST/gRPC, hosts registry REST API, handles push/materialize operations, Feast Permission RBAC enforcement" "Python FastAPI + Uvicorn" "service"
            featureServerGo = container "Feature Server (Go)" "High-performance online feature serving via HTTP and gRPC with Arrow columnar format" "Go net/http + gRPC" "service"
            feastUI = container "Feast UI" "Web UI for browsing feature store metadata, entities, feature views, and data lineage" "React TypeScript" "webapp"
            materializationCronJob = container "Materialization CronJob" "Scheduled batch job to materialize features from offline to online stores" "Kubernetes CronJob" "cronjob"
        }

        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys feast-operator via kustomize overlays" "Internal RHOAI"
        odhNotebookController = softwareSystem "ODH Notebook Controller" "Manages Notebook CRDs; feast-operator auto-injects Feast config into labeled notebooks" "Internal ODH"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring stack; feast-operator creates ServiceMonitors for metrics scraping" "Internal Platform"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRUD on Deployments, Services, RBAC, CronJobs, HPAs, TokenReview, SubjectAccessReview" "Platform"
        openShiftAPI = softwareSystem "OpenShift API Server" "Route creation, service serving certificate detection and auto-provisioning" "Platform"
        oidcProvider = softwareSystem "OIDC Provider" "Identity provider (Keycloak, Azure AD, etc.) for JWT token validation via JWKS discovery" "External"

        redis = softwareSystem "Redis" "High-throughput online store backend for feature serving (port 6379/TCP)" "External Store"
        postgresql = softwareSystem "PostgreSQL" "Online/offline store and registry backend (port 5432/TCP)" "External Store"
        dynamoDB = softwareSystem "DynamoDB" "AWS-managed online store backend (HTTPS/443)" "External Store"
        s3 = softwareSystem "S3" "AWS object storage for registry backend (HTTPS/443)" "External Store"
        gcs = softwareSystem "GCS" "GCP object storage for registry backend (HTTPS/443)" "External Store"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for offline store and registry (HTTPS/443)" "External Store"
        bigQuery = softwareSystem "BigQuery" "GCP data warehouse for offline store (HTTPS/443)" "External Store"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing collector for Go feature server (OTLP HTTP/4317)" "External"

        # System Context relationships
        dataScientist -> feast "Creates FeatureStore CRs, queries features" "kubectl, REST API"
        mlEngineer -> feast "Manages feature pipelines, monitors materialization" "kubectl, REST API"
        platformAdmin -> rhoaiOperator "Configures platform" "kubectl"
        rhoaiOperator -> feast "Deploys feast-operator" "Kustomize overlay"

        feast -> k8sAPI "CRUD operations, TokenReview, SubjectAccessReview" "HTTPS/443, SA token"
        feast -> openShiftAPI "Route creation, cert detection" "HTTPS/443, SA token"
        feast -> oidcProvider "JWT validation via JWKS" "HTTPS/443"
        feast -> redis "Online feature storage" "Redis/6379, TLS optional"
        feast -> postgresql "Feature storage and registry" "PostgreSQL/5432, TLS optional"
        feast -> dynamoDB "Online feature storage (AWS)" "HTTPS/443, AWS IAM"
        feast -> s3 "Registry storage" "HTTPS/443, AWS IAM"
        feast -> gcs "Registry storage" "HTTPS/443, GCP SA"
        feast -> snowflake "Offline store" "HTTPS/443, OAuth"
        feast -> bigQuery "Offline store" "HTTPS/443, GCP SA"
        feast -> otelCollector "Distributed tracing" "OTLP HTTP/4317"

        odhNotebookController -> feast "Feast config injection triggered by label" "CRD watch"
        prometheusOperator -> feast "Scrapes metrics" "HTTP/8000"

        # Container relationships
        dataScientist -> featureServerPython "Query online features" "REST POST /get-online-features, Bearer JWT"
        dataScientist -> feastUI "Browse feature metadata" "HTTPS/443 via Route"
        mlEngineer -> featureServerPython "Push features, trigger materialization" "REST POST /push, /materialize"

        feastOperator -> featureServerPython "Deploys, manages lifecycle"
        feastOperator -> featureServerGo "Deploys, manages lifecycle"
        feastOperator -> feastUI "Deploys, manages lifecycle"
        feastOperator -> materializationCronJob "Creates and schedules" "CronJob spec"
        feastOperator -> featureServerPython "Fetches permission policies" "HTTP(S), Intra-comm JWT (HMAC-SHA256)"
        feastOperator -> k8sAPI "CRUD on all managed resources" "HTTPS/443, SA token"
        feastOperator -> openShiftAPI "Route management, cert detection" "HTTPS/443, SA token"

        featureServerPython -> redis "Feature read/write" "Redis/6379"
        featureServerPython -> postgresql "Feature read/write" "PostgreSQL/5432"
        featureServerPython -> dynamoDB "Feature read/write" "HTTPS/443"
        featureServerPython -> oidcProvider "JWT validation" "HTTPS/443"
        featureServerPython -> k8sAPI "TokenReview for K8s auth" "HTTPS/443"
        featureServerPython -> snowflake "Offline store queries" "HTTPS/443"
        featureServerPython -> bigQuery "Offline store queries" "HTTPS/443"
        featureServerPython -> s3 "Registry storage" "HTTPS/443"
        featureServerPython -> gcs "Registry storage" "HTTPS/443"

        featureServerGo -> redis "Feature read" "Redis/6379"
        featureServerGo -> postgresql "Feature read" "PostgreSQL/5432"
        featureServerGo -> dynamoDB "Feature read" "HTTPS/443"
        featureServerGo -> otelCollector "Tracing" "OTLP HTTP/4317"

        materializationCronJob -> featureServerPython "Trigger materialization" "HTTP/6566, Intra-comm JWT"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Store" {
                background #d4a017
                color #ffffff
            }
            element "Platform" {
                background #555555
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
            element "Internal Platform" {
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
            element "service" {
                shape RoundedBox
                background #7ed321
            }
            element "webapp" {
                shape WebBrowser
                background #f5a623
            }
            element "cronjob" {
                shape Circle
                background #9b59b6
            }
        }
    }
}
