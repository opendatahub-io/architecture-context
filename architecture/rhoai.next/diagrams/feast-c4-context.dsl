workspace {
    model {
        datascientist = person "Data Scientist" "Creates feature definitions, explores features via UI, uses features in notebooks"
        mlmodel = person "ML Model / Client" "Consumes online features for real-time inference"
        datapipeline = person "Data Pipeline" "Pushes features to the feature store"

        feast = softwareSystem "Feast Feature Store" "Manages, stores, and serves ML features for training and online inference" {
            operator = container "Feast Operator" "Manages FeatureStore CRD lifecycle, creates Deployments, Services, RBAC, CronJobs, Routes" "Go (controller-runtime)" "operator"
            featureServer = container "Feature Server" "Serves online features via REST/gRPC, handles materialization and push operations" "Python (FastAPI/Uvicorn/Gunicorn)" "service"
            goServer = container "Go Feature Server" "High-performance online feature serving" "Go (gRPC/HTTP)" "service"
            registry = container "Registry Service" "Stores and serves feature definitions, permissions, and metadata" "Python" "service"
            ui = container "Feast UI" "Web-based feature store exploration and visualization" "React/TypeScript (Elastic UI)" "frontend"
            cronJob = container "Materialization CronJob" "Scheduled batch materialization from offline to online store" "ose-cli" "job"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Resource management, RBAC, token review" "External"
        openshiftAPI = softwareSystem "OpenShift API" "Route creation, service-serving certificates, CA bundles" "External"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Deploys feast-operator via kustomize overlays" "Internal Platform"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebook environment for data scientists" "Internal Platform"
        oidcProvider = softwareSystem "OIDC Provider" "JWT token validation via JWKS discovery" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor" "Internal Platform"

        redis = softwareSystem "Redis" "Online feature store backend" "External Store"
        postgresql = softwareSystem "PostgreSQL" "Online/offline store, SQL registry" "External Store"
        dynamodb = softwareSystem "DynamoDB" "Online feature store (AWS)" "External Store"
        bigquery = softwareSystem "BigQuery" "Offline feature store (GCP)" "External Store"
        snowflake = softwareSystem "Snowflake" "Online/offline store, registry" "External Store"
        s3 = softwareSystem "S3 Storage" "Registry file storage (AWS)" "External Store"
        gcs = softwareSystem "GCS" "Registry file storage (GCP)" "External Store"
        elasticsearch = softwareSystem "Elasticsearch" "Online store - vector search" "External Store"
        milvus = softwareSystem "Milvus" "Online store - vector search" "External Store"
        openlineage = softwareSystem "OpenLineage / Marquez" "Data lineage tracking" "External"

        # Relationships - Users
        datascientist -> feast "Creates FeatureStore CRs, explores features" "kubectl, UI"
        mlmodel -> feast "Retrieves online features" "REST/gRPC, Bearer Token"
        datapipeline -> feast "Pushes features" "REST, Bearer Token"

        # Relationships - Operator
        operator -> kubernetesAPI "Watches CRDs, manages resources, RBAC" "HTTPS/6443"
        operator -> openshiftAPI "Creates Routes, injects certs" "HTTPS/6443"
        operator -> registry "Fetches permission policies" "HTTP/8001, JWT"
        operator -> featureServer "Creates/manages Deployment" "Kubernetes API"
        operator -> goServer "Creates/manages Deployment" "Kubernetes API"
        operator -> ui "Creates/manages Deployment" "Kubernetes API"
        operator -> cronJob "Creates/manages CronJob" "Kubernetes API"
        operator -> kubeflowNotebooks "Injects feast client ConfigMaps" "K8s Watch"

        # Relationships - Feature Server
        featureServer -> redis "Reads/writes features" "TCP/6379, Password"
        featureServer -> postgresql "Reads/writes features, registry" "TCP/5432"
        featureServer -> dynamodb "Reads/writes features" "HTTPS/443, AWS IAM"
        featureServer -> bigquery "Reads historical features" "HTTPS/443, GCP SA"
        featureServer -> snowflake "Reads/writes features" "HTTPS/443"
        featureServer -> s3 "Reads/writes registry" "HTTPS/443, AWS IAM"
        featureServer -> gcs "Reads/writes registry" "HTTPS/443, GCP SA"
        featureServer -> elasticsearch "Vector search" "HTTPS/9200, API key"
        featureServer -> milvus "Vector search" "gRPC/19530, Token"
        featureServer -> oidcProvider "Validates JWT tokens" "HTTPS/443, JWKS"
        featureServer -> kubernetesAPI "Token review (K8s auth)" "HTTPS/6443"
        featureServer -> openlineage "Data lineage events" "HTTP/HTTPS"

        # Relationships - CronJob
        cronJob -> featureServer "Triggers materialization" "kubectl exec"

        # Relationships - Platform
        odhOperator -> operator "Deploys via kustomize" "Kustomize"
        prometheusOperator -> feast "Scrapes metrics" "ServiceMonitor"

        # Relationships - UI
        ui -> registry "Reads feature definitions" "gRPC/6001"
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
            element "External Store" {
                background #f5a623
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "operator" {
                background #4a90e2
                color #ffffff
            }
            element "service" {
                background #4a90e2
                color #ffffff
            }
            element "frontend" {
                background #50e3c2
                color #333333
            }
            element "job" {
                background #9013fe
                color #ffffff
            }
        }
    }
}
