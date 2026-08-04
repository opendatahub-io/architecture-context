workspace {
    model {
        dataScientist = person "Data Scientist" "Creates FeatureStore CRs, retrieves features for ML training and serving"
        mlEngineer = person "ML Engineer" "Manages feature pipelines and materialization jobs"

        feast = softwareSystem "Feast" "Feature store platform for ML — manages feature registry, online/offline serving via Kubernetes operator" {
            operator = container "Feast Operator" "Watches FeatureStore CRs, reconciles Deployments, Services, RBAC, HPA, PDB, CronJobs, Routes" "Go controller-runtime" "Operator"
            goFeatureServer = container "Go Feature Server" "Serves online features via HTTP (/get-online-features) and gRPC (ServingService)" "Go binary"
            pyFeatureServer = container "Python Feature Server" "Serves online features and REST registry API via FastAPI/Starlette on :6566" "Python FastAPI"
            offlineServer = container "Python Offline Server" "Serves historical features via Apache Arrow Flight with FIPS cipher enforcement" "Python Arrow Flight"
            registryServer = container "Registry Server" "Manages feature definitions — gRPC RegistryServer (40+ RPCs) and REST API" "Python gRPC"
            feastUI = container "Feast UI" "Web interface for feature store exploration and chat" "React SPA"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database used as online feature store backend" "External"
        redis = softwareSystem "Redis / Valkey" "In-memory store used as online feature store backend" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for registry and feature artifacts" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for registry and feature artifacts" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system — operator manages ServiceMonitor resources" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook workbench platform — operator generates integration ConfigMaps" "Internal ODH"
        sparkOperator = softwareSystem "Spark Operator" "Batch compute engine — operator creates SparkApplication resources for materialization" "External"

        # User interactions
        dataScientist -> feast "Creates FeatureStore CRs, retrieves features via HTTP/gRPC"
        mlEngineer -> feast "Manages feature definitions, triggers materialization"

        # Operator interactions
        operator -> k8sAPI "Manages cluster resources (Deployments, Services, RBAC, etc.)" "HTTPS/6443 ServiceAccount"
        operator -> kubeflowNotebooks "Watches Notebooks, generates integration ConfigMaps" "Kubernetes API"
        operator -> prometheus "Creates/manages ServiceMonitor resources" "Kubernetes API"
        operator -> sparkOperator "Creates SparkApplication resources for batch materialization" "Kubernetes API"

        # Data plane interactions
        goFeatureServer -> postgresql "Reads online features" "TCP pgx pool"
        goFeatureServer -> redis "Reads online features" "TCP go-redis"
        pyFeatureServer -> postgresql "Reads online features" "TCP"
        pyFeatureServer -> redis "Reads online features" "TCP"
        registryServer -> s3 "Stores/retrieves feature registry" "HTTPS/443 AWS IAM"
        registryServer -> gcs "Stores/retrieves feature registry" "HTTPS/443 GCP SA"

        # Internal container relationships
        operator -> goFeatureServer "Creates and manages deployment"
        operator -> pyFeatureServer "Creates and manages deployment"
        operator -> offlineServer "Creates and manages deployment"
        operator -> registryServer "Creates and manages deployment"
        operator -> feastUI "Creates and manages deployment"

        dataScientist -> goFeatureServer "Retrieves online features" "HTTP POST /get-online-features"
        dataScientist -> pyFeatureServer "Retrieves online features, manages registry" "HTTP :6566"
        dataScientist -> offlineServer "Retrieves historical features" "Arrow Flight gRPC"
        dataScientist -> feastUI "Explores feature store" "HTTPS"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
