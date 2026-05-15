workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML features, deploys feature stores"
        mlApplication = person "ML Application" "Consumes online features for inference"

        feast = softwareSystem "Feast Feature Store" "ML feature management platform for storing, managing, and serving features for training and online inference" {
            feastOperator = container "feast-operator" "Manages FeatureStore CRs, deploys and configures all feast services" "Go Operator (controller-runtime)" "operator"
            pythonServer = container "Python Feature Server" "REST API for online feature serving, push ingestion, materialization, vector search" "Python 3.12 (FastAPI/Gunicorn)" "server"
            goServer = container "Go Feature Server" "High-performance online feature retrieval via HTTP and gRPC" "Go (net/http + gRPC)" "server"
            registry = container "Feature Registry" "Stores feature definitions, permissions, and metadata" "Python gRPC + REST" "server"
            feastUI = container "Feast UI" "Web dashboard for exploring features, data sources, entities" "React/TypeScript" "webapp"
            pythonSDK = container "Feast Python SDK" "Client library and CLI for defining, applying, and querying features" "Python Library" "library"
            cronJobs = container "Materialization CronJobs" "Scheduled jobs for materializing features from offline to online store" "Kubernetes CronJob" "batch"
        }

        # Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator, deploys feast-operator via Kustomize overlays" "Internal RHOAI"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook environment with feast integration label for auto-config" "Internal ODH"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRDs" "Internal Platform"
        openshiftRoutes = softwareSystem "OpenShift Route Controller" "Manages Routes for UI and Registry REST API exposure" "Internal Platform"
        openshiftCerts = softwareSystem "OpenShift Service Serving Certs" "Auto-provisions TLS certificates for feast services" "Internal Platform"

        # External Dependencies
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for resource management, RBAC, leader election" "External"
        oidcProvider = softwareSystem "OIDC Provider" "Authentication provider for JWT validation (RHOAI Gateway)" "External"
        redis = softwareSystem "Redis" "Online feature store backend" "External"
        postgresql = softwareSystem "PostgreSQL" "Online/offline feature store backend" "External"
        dynamodb = softwareSystem "DynamoDB" "AWS online feature store backend" "External"
        bigquery = softwareSystem "BigQuery" "GCP offline feature store backend" "External"
        snowflake = softwareSystem "Snowflake" "Online/offline feature store backend" "External"
        s3 = softwareSystem "S3 Storage" "Registry and model artifact storage" "External"
        gcs = softwareSystem "GCS" "Registry storage" "External"
        gitRepo = softwareSystem "Git Repository" "Feature definition repository" "External"
        otelCollector = softwareSystem "OTEL Collector" "Distributed tracing collector" "External"

        # User relationships
        dataScientist -> feast "Creates FeatureStore CRs, defines features via SDK/CLI"
        dataScientist -> feastUI "Browses feature definitions, data sources" "HTTPS/443"
        mlApplication -> pythonServer "POST /get-online-features" "HTTP/6566, TLS, OIDC JWT"
        mlApplication -> goServer "GetOnlineFeatures" "gRPC/8080, TLS"

        # Internal container relationships
        feastOperator -> kubernetesAPI "Manages resources (Deployments, Services, RBAC, CronJobs)" "HTTPS/6443"
        feastOperator -> registry "Fetches permissions for auto-access RBAC" "HTTP/8080, Bearer JWT"
        feastOperator -> pythonServer "Deploys and configures" "Kubernetes API"
        feastOperator -> goServer "Deploys and configures" "Kubernetes API"
        feastOperator -> feastUI "Deploys and configures" "Kubernetes API"
        feastOperator -> cronJobs "Creates scheduled materialization jobs" "Kubernetes API"

        pythonServer -> registry "Fetches feature metadata and permissions" "gRPC/6570, Bearer JWT"
        pythonServer -> redis "Reads/writes feature values" "TCP/6379, Password"
        pythonServer -> postgresql "Reads/writes feature values" "TCP/5432, User/Pass, SSL"
        pythonServer -> dynamodb "Reads/writes feature values" "HTTPS/443, AWS IAM"
        pythonServer -> bigquery "Reads historical features" "HTTPS/443, GCP SA"
        pythonServer -> snowflake "Reads/writes feature values" "HTTPS/443, User/Pass"
        pythonServer -> oidcProvider "OIDC discovery, JWKS key fetch" "HTTPS/443"

        goServer -> redis "Reads feature values" "TCP/6379, Password"
        goServer -> postgresql "Reads feature values" "TCP/5432, SSL"
        goServer -> dynamodb "Reads feature values" "HTTPS/443, AWS IAM"
        goServer -> otelCollector "Exports traces" "HTTP"

        registry -> s3 "Persists registry data" "HTTPS/443, AWS IAM"
        registry -> gcs "Persists registry data" "HTTPS/443, GCP SA"

        cronJobs -> gitRepo "Clones feature repository" "HTTPS/443 or SSH/22"
        cronJobs -> registry "Fetches feature definitions" "gRPC/6570, Bearer JWT"
        cronJobs -> bigquery "Reads historical features" "HTTPS/443"
        cronJobs -> redis "Writes materialized features" "TCP/6379"

        pythonSDK -> pythonServer "Queries features" "HTTP/6566"
        pythonSDK -> registry "Manages feature definitions" "gRPC/6570"

        # Platform relationships
        rhodsOperator -> feastOperator "Deploys via Kustomize overlays" "Kustomize"
        feastOperator -> kubeflowNotebooks "Watches Notebooks, injects feast-config ConfigMap" "Kubernetes API"
        feastOperator -> prometheusOperator "Creates ServiceMonitors for metrics scraping" "Kubernetes API"
        feastOperator -> openshiftRoutes "Creates Routes for UI and Registry REST API" "Kubernetes API"
        openshiftCerts -> feast "Auto-provisions TLS certificates for services" "Kubernetes API"
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
            element "External" {
                background #999999
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
                background #4ecdc4
                color #ffffff
            }
            element "operator" {
                shape hexagon
                background #4a90e2
                color #ffffff
            }
            element "server" {
                shape roundedbox
                background #4a90e2
                color #ffffff
            }
            element "webapp" {
                shape webbrowser
                background #4a90e2
                color #ffffff
            }
            element "library" {
                shape component
                background #b8d4e3
                color #333333
            }
            element "batch" {
                shape cylinder
                background #f5a623
                color #ffffff
            }
        }
    }
}
