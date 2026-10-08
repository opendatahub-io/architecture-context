workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML features, trains models, retrieves online features"
        mlEngineer = person "ML Engineer" "Deploys and manages feature store instances, configures backends"

        feast = softwareSystem "Feast" "Feature store platform for ML feature management, storage, and serving" {
            operator = container "Feast Operator" "Reconciles FeatureStore CRs, manages lifecycle of all feature store sub-resources" "Go Operator (controller-runtime)" "Operator"
            featureServerPython = container "Feature Server (Python)" "Serves online features, registry API, lineage, monitoring via HTTP/gRPC" "Python (FastAPI/Starlette)" "Service"
            featureServerGo = container "Feature Server (Go)" "High-performance online feature retrieval via HTTP/gRPC" "Go Service" "Service"
            materializationCronJob = container "Materialization CronJob" "Scheduled batch materialization from offline to online store" "ose-cli" "CronJob"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external access via Routes" "External"

        redis = softwareSystem "Redis / Valkey" "In-memory online feature store backend" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational online/offline store backend" "External"
        bigquery = softwareSystem "BigQuery" "Google Cloud offline store for historical feature queries" "External"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse offline store" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for registry and feature artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for registry persistence" "External"

        notebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workspaces for data scientists" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model registry" "Internal RHOAI"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring and metrics collection" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Distributed batch processing for materialization" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing RHOAI components" "Internal RHOAI"

        # Relationships
        dataScientist -> feast "Creates FeatureStore CRs, retrieves features" "kubectl / REST API"
        mlEngineer -> feast "Deploys and configures feature store instances" "kubectl / CLI"

        operator -> kubernetesAPI "CRUD operations on resources" "HTTPS/6443, SA token"
        operator -> featureServerPython "Creates and manages deployments" "Kubernetes API"
        operator -> featureServerGo "Creates and manages deployments" "Kubernetes API"
        operator -> materializationCronJob "Creates CronJobs" "Kubernetes API"

        featureServerPython -> redis "Reads/writes online features" "TCP, Password/TLS"
        featureServerPython -> postgresql "Reads/writes features" "TCP, Username/password"
        featureServerPython -> bigquery "Queries historical features" "HTTPS/443, Google creds"
        featureServerPython -> snowflake "Queries historical features" "HTTPS/443, OAuth"
        featureServerPython -> s3 "Registry/artifact storage" "HTTPS/443, AWS IAM"
        featureServerPython -> gcs "Registry persistence" "HTTPS/443, Google creds"

        featureServerGo -> redis "Reads online features" "TCP, Password/TLS"

        materializationCronJob -> featureServerPython "Triggers materialization" "HTTP/6566"

        operator -> notebooks "Watches Notebook CRs, injects client config" "Kubernetes API"
        operator -> mlflow "Watches MLflow CRs" "Kubernetes API"
        operator -> prometheusOperator "Creates ServiceMonitor resources" "Kubernetes API"
        operator -> sparkOperator "Creates SparkApplication resources" "Kubernetes API"

        dataScientist -> openshiftRouter "Accesses features via Route" "HTTPS/443"
        openshiftRouter -> featureServerPython "Routes traffic" "HTTP/6566"

        dashboard -> feast "Manages feature stores via UI" "Kubernetes API"
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
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Service" {
                background #50c878
                color #ffffff
            }
            element "CronJob" {
                background #f5a623
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
