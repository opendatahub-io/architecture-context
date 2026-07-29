workspace {
    model {
        dataScientist = person "Data Scientist" "Creates FeatureStore CRs and queries features for ML workflows"
        mlEngineer = person "ML Engineer" "Manages feature pipelines and materialization jobs"

        feast = softwareSystem "Feast" "Feature store platform for managing and serving ML features on Kubernetes" {
            operator = container "Feast Operator" "Manages FeatureStore CRs, reconciles Kubernetes resources" "Go Operator (controller-runtime)"
            goFeatureServer = container "Go Feature Server" "High-performance online feature serving via HTTP and gRPC" "Go Service"
            pythonAPI = container "Python FastAPI Service" "Feature registry REST API, materialization, monitoring" "Python (FastAPI/Uvicorn)"
            cgoBridge = container "CGo Bridge" "Zero-copy feature transfer between Python and Go via Arrow C Data Interface" "CGo / Apache Arrow"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online feature storage" "External"
        redis = softwareSystem "Redis / Valkey" "In-memory data store for online feature serving" "External"
        dynamodb = softwareSystem "DynamoDB" "AWS managed NoSQL database for online features" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for feature registry and offline features" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for feature registry" "External"
        ray = softwareSystem "Ray" "Distributed compute framework for feature materialization" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook workbenches for data science" "Internal RHOAI"
        prometheusOperator = softwareSystem "prometheus-operator" "Prometheus monitoring resource management" "Internal RHOAI"
        openlineage = softwareSystem "OpenLineage" "Data lineage tracking and metadata" "External"

        dataScientist -> feast "Creates FeatureStore CRs, queries features"
        mlEngineer -> feast "Manages feature pipelines, triggers materialization"

        feast -> kubernetesAPI "Manages resources via ServiceAccount" "HTTPS/6443, TLS 1.2+"
        feast -> postgresql "Reads/writes online features" "TCP, sslmode=require"
        feast -> redis "Reads/writes online features" "TCP, optional TLS"
        feast -> dynamodb "Reads/writes online features" "HTTPS/443, AWS IAM"
        feast -> s3 "Stores/reads feature registry and artifacts" "HTTPS/443, AWS IAM"
        feast -> gcs "Stores/reads feature registry" "HTTPS/443, platform credentials"
        feast -> ray "Orchestrates distributed compute jobs" "SDK, RAY_AUTH_TOKEN"
        feast -> kubeflowNotebooks "Manages notebook workbenches" "K8s API, CRD CRUD"
        feast -> prometheusOperator "Creates ServiceMonitor resources" "K8s API, CRD CRUD"
        feast -> openlineage "Reports data lineage events" "HTTP, API Key"

        operator -> kubernetesAPI "Watches FeatureStore CRs, creates Deployments/Services/ConfigMaps" "HTTPS/6443"
        pythonAPI -> cgoBridge "Calls Go feature server for online features" "In-process, Arrow C ABI"
        cgoBridge -> goFeatureServer "Executes GetOnlineFeatures" "In-process"
        goFeatureServer -> postgresql "Queries feature vectors" "TCP/pgx"
        goFeatureServer -> redis "Queries feature vectors" "TCP/go-redis"
        goFeatureServer -> s3 "Loads registry data" "HTTPS/443"
        goFeatureServer -> gcs "Loads registry data" "HTTPS/443"
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
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
