workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages feature store deployments for ML pipelines"

        feast = softwareSystem "Feast" "Kubernetes operator and feature store platform for ML feature management" {
            operator = container "Feast Operator" "Manages FeatureStore CRDs, reconciles deployments, services, RBAC, routes, CronJobs" "Go Operator (controller-runtime)"
            featureServerPython = container "Feature Server (Python)" "Serves features via REST/gRPC, provides registry API, monitoring, lineage, MCP" "Python FastAPI/Starlette, Port 6566"
            featureServerGo = container "Feature Server (Go)" "High-performance online feature serving with post-quantum TLS" "Go HTTP/gRPC Server"
            feastCLI = container "Feast CLI" "Command-line interface for feature store management" "Python CLI"
        }

        kubeAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"
        openshift = softwareSystem "OpenShift" "OpenShift platform APIs (Routes, TLS profiles)" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook environments for data scientists" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model registry" "Internal RHOAI"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Distributed compute for batch materialization" "Internal RHOAI"

        redis = softwareSystem "Redis / Valkey" "In-memory data store for online features" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline store and registry" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for registry and data" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for registry and data" "External"
        bigquery = softwareSystem "BigQuery" "Data warehouse for offline feature queries" "External"
        snowflake = softwareSystem "Snowflake" "Data warehouse for offline feature queries" "External"

        user -> feast "Creates FeatureStore CR via kubectl/CLI"
        user -> feastCLI "Manages feature definitions"
        feastCLI -> featureServerPython "Applies feature definitions" "REST/gRPC"

        operator -> kubeAPI "Watches CRDs, reconciles resources" "HTTPS/6443"
        operator -> openshift "Fetches TLS profiles, creates Routes" "HTTPS/6443"
        operator -> kubeflowNotebooks "Injects feature store config into notebooks" "Kubernetes API Watch"
        operator -> mlflow "Reads MLflow instances for lineage" "Kubernetes API Watch"
        operator -> prometheusOperator "Creates ServiceMonitors" "Kubernetes API"
        operator -> sparkOperator "Creates SparkApplications for batch materialization" "Kubernetes API"

        featureServerPython -> redis "Reads/writes online features" "TCP"
        featureServerPython -> postgresql "Reads/writes features and registry" "TCP"
        featureServerPython -> s3 "Stores/retrieves registry and data" "HTTPS/443"
        featureServerPython -> gcs "Stores/retrieves registry and data" "HTTPS/443"
        featureServerPython -> bigquery "Queries offline features" "HTTPS/443"
        featureServerPython -> snowflake "Queries offline features" "HTTPS/443"

        featureServerGo -> redis "Reads online features" "TCP"
        featureServerGo -> postgresql "Reads online features" "TCP"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
