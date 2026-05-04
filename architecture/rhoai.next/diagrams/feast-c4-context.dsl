workspace {
    model {
        dataScientist = person "Data Scientist" "Creates feature definitions, deploys feature stores, uses features in notebooks"
        mlModel = person "ML Model / Inference Service" "Retrieves online features for real-time predictions"
        dataPipeline = person "Data Pipeline" "Pushes features to online and offline stores"

        feast = softwareSystem "Feast" "Open-source feature store for ML - manages, stores, and serves features for training and inference" {
            feastOperator = container "Feast Operator" "Manages FeatureStore CRD lifecycle, creates Deployments, Services, RBAC, CronJobs, Routes" "Go Operator (controller-runtime)" "operator"
            featureServer = container "Feature Server" "Serves online features via REST/gRPC, handles materialization, push, and auth" "Python (FastAPI/Uvicorn/Gunicorn)" "service"
            feastUI = container "Feast UI" "Web-based feature store exploration and visualization" "React/TypeScript (Elastic UI)" "frontend"
            registry = container "Feature Registry" "Stores feature definitions, entities, data sources metadata" "Embedded in Feature Server" "service"
            materializationCronJob = container "Materialization CronJob" "Periodic batch materialization from offline to online store" "ose-cli (kubectl exec)" "cronjob"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftAPI = softwareSystem "OpenShift API" "Route creation, service-serving certificates, CA bundle injection" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Jupyter notebooks for data science" "Internal Platform"
        platformOperator = softwareSystem "ODH/RHOAI Operator" "Deploys feast-operator via kustomize overlays" "Internal Platform"
        platformOIDC = softwareSystem "Platform OIDC Provider" "JWT token validation via JWKS discovery" "Internal Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor" "Internal Platform"

        redis = softwareSystem "Redis" "Online feature store backend" "External Store"
        postgresql = softwareSystem "PostgreSQL" "Online/offline store, SQL registry backend" "External Store"
        dynamoDB = softwareSystem "DynamoDB" "Online feature store backend (AWS)" "External Store"
        bigQuery = softwareSystem "BigQuery" "Offline feature store backend (GCP)" "External Store"
        snowflake = softwareSystem "Snowflake" "Online/offline store, registry backend" "External Store"
        s3 = softwareSystem "S3 / GCS" "Registry file storage" "External Store"
        elasticsearch = softwareSystem "Elasticsearch" "Online store for vector search" "External Store"
        milvus = softwareSystem "Milvus" "Online store for vector search" "External Store"

        # User interactions
        dataScientist -> feast "Creates FeatureStore CR via kubectl/UI"
        mlModel -> feast "POST /get-online-features (Bearer Token)" "HTTPS/443"
        dataPipeline -> feast "POST /push (Bearer Token)" "HTTPS/443"

        # Operator interactions
        feastOperator -> k8sAPI "Watches CRDs, creates resources, RBAC" "HTTPS/6443"
        feastOperator -> openshiftAPI "Creates Routes, requests service-serving certs" "HTTPS/6443"
        feastOperator -> featureServer "Fetches permissions for auto-access RBAC" "HTTP/8001 (JWT)"
        feastOperator -> registry "Queries permission policies" "HTTP/8001 (JWT)"

        # Feature server interactions
        featureServer -> redis "Read/write online features" "TCP/6379 (Password)"
        featureServer -> postgresql "Read/write features, registry" "TCP/5432 (User/Pass)"
        featureServer -> dynamoDB "Read/write online features" "HTTPS/443 (AWS IAM)"
        featureServer -> bigQuery "Read offline features" "HTTPS/443 (GCP SA)"
        featureServer -> snowflake "Read/write features, registry" "HTTPS/443 (Creds)"
        featureServer -> s3 "Store/retrieve registry files" "HTTPS/443 (IAM/GCP)"
        featureServer -> elasticsearch "Vector search features" "HTTPS/9200 (API Key)"
        featureServer -> milvus "Vector search features" "gRPC/19530 (Token)"
        featureServer -> platformOIDC "Validate JWT tokens" "HTTPS/443 (JWKS)"
        featureServer -> k8sAPI "Token review (K8s auth)" "HTTPS/6443 (SA Token)"

        # CronJob interactions
        materializationCronJob -> featureServer "kubectl exec materialization" "SA RBAC"

        # Platform integrations
        platformOperator -> feast "Deploys via kustomize overlays" "Kustomize"
        feastOperator -> kubeflowNotebooks "Injects feast client ConfigMaps into labeled Notebooks" "K8s API Watch"
        feastOperator -> prometheusOperator "Creates ServiceMonitor for metrics" "CRD Creation"

        # UI interactions
        dataScientist -> feastUI "Browse features, entities, data sources" "HTTPS/443"
        feastUI -> registry "Query feature metadata" "Internal"
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
                background #50c878
                color #ffffff
            }
            element "frontend" {
                background #9b59b6
                color #ffffff
            }
            element "cronjob" {
                background #e67e22
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
