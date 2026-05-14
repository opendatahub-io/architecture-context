workspace {
    model {
        dataScientist = person "Data Scientist" "Creates FeatureStore CRs, explores features via UI, uses features in Jupyter notebooks"
        mlEngineer = person "ML Engineer / Pipeline" "Pushes features, triggers materialization, retrieves online features for inference"

        feast = softwareSystem "Feast" "Open-source feature store that manages, stores, and serves ML features for training and online inference" {
            operator = container "Feast Operator" "Manages FeatureStore CRD lifecycle, creates Deployments, Services, RBAC, CronJobs, and Routes" "Go / controller-runtime"
            featureServer = container "Feature Server" "Serves online features via REST and gRPC, handles materialization, push operations, and metrics" "Python / FastAPI / Uvicorn / Gunicorn"
            goFeatureServer = container "Go Feature Server" "High-performance online feature serving via gRPC" "Go / gRPC"
            registry = container "Registry Service" "Feature metadata store, permission policies, gRPC and REST APIs" "Python / FastAPI"
            ui = container "Feast UI" "Web-based feature store exploration and visualization" "React / TypeScript / Elastic UI"
            cronJob = container "Materialization CronJob" "Scheduled batch materialization from offline to online store" "Kubernetes CronJob / ose-cli"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management, RBAC, and token review" "Platform"
        openshiftAPI = softwareSystem "OpenShift API" "Route creation, service-serving certificate injection, CA bundle management" "Platform"
        oidcProvider = softwareSystem "Platform OIDC Provider" "JWT token validation via JWKS discovery for feature server authorization" "Platform"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebook Controller" "Manages Jupyter notebooks; Feast injects client ConfigMaps into labeled notebooks" "Internal ODH"
        odhOperator = softwareSystem "ODH / RHODS Operator" "Deploys feast-operator via kustomize overlays" "Internal ODH"
        prometheusOperator = softwareSystem "Prometheus Operator" "Scrapes metrics via ServiceMonitor CRD" "Platform"

        redis = softwareSystem "Redis" "Online feature store backend for real-time feature read/write" "External Data Store"
        postgresql = softwareSystem "PostgreSQL" "Online/offline store and SQL registry backend" "External Data Store"
        dynamodb = softwareSystem "DynamoDB" "AWS-managed online feature store backend" "External Data Store"
        bigquery = softwareSystem "BigQuery" "GCP-managed offline feature store backend" "External Data Store"
        snowflake = softwareSystem "Snowflake" "Online/offline store and registry backend" "External Data Store"
        s3 = softwareSystem "S3 Storage" "Registry file storage for feature definitions" "External Data Store"
        gcs = softwareSystem "GCS Storage" "Registry file storage for feature definitions" "External Data Store"
        elasticsearch = softwareSystem "Elasticsearch" "Online store for vector search features" "External Data Store"
        milvus = softwareSystem "Milvus" "Online store for vector search features" "External Data Store"
        openlineage = softwareSystem "OpenLineage / Marquez" "Data lineage tracking and event collection" "External"

        # User interactions
        dataScientist -> feast "Creates FeatureStore CR, explores features via UI"
        mlEngineer -> feast "Retrieves features, pushes features, triggers materialization"

        # Internal container relationships
        operator -> featureServer "Creates and manages Deployment" "Kubernetes API"
        operator -> goFeatureServer "Creates and manages Deployment" "Kubernetes API"
        operator -> registry "Fetches permission policies" "HTTP/8001, Intra-communication JWT"
        operator -> ui "Creates and manages Deployment" "Kubernetes API"
        operator -> cronJob "Creates and manages CronJob" "Kubernetes API"
        featureServer -> registry "Syncs feature metadata" "gRPC/6001"
        cronJob -> featureServer "Triggers materialization" "kubectl exec"

        # Platform dependencies
        operator -> kubernetesAPI "CRD watches, resource CRUD, RBAC, token review" "HTTPS/6443"
        operator -> openshiftAPI "Route creation, cert injection" "HTTPS/6443"
        featureServer -> oidcProvider "JWT token validation via JWKS" "HTTPS/443"
        featureServer -> kubernetesAPI "Token review for K8s SA auth" "HTTPS/6443"
        operator -> kubeflowNotebooks "Watches Notebook CRDs, injects ConfigMaps" "Kubernetes API"
        odhOperator -> feast "Deploys via kustomize overlays" "Kustomize"
        prometheusOperator -> feast "Scrapes metrics via ServiceMonitor" "HTTPS/8443"

        # External data store connections
        featureServer -> redis "Online feature read/write" "TCP/6379"
        featureServer -> postgresql "Online/offline store, SQL registry" "TCP/5432"
        featureServer -> dynamodb "Online feature store" "HTTPS/443"
        featureServer -> bigquery "Offline feature store" "HTTPS/443"
        featureServer -> snowflake "Online/offline store, registry" "HTTPS/443"
        featureServer -> s3 "Registry file storage" "HTTPS/443"
        featureServer -> gcs "Registry file storage" "HTTPS/443"
        featureServer -> elasticsearch "Online store (vector search)" "HTTPS/9200"
        featureServer -> milvus "Online store (vector search)" "gRPC/19530"
        featureServer -> openlineage "Data lineage events" "HTTP/HTTPS"
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
            element "Platform" {
                background #e1d5e7
                color #333333
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External Data Store" {
                background #fff2cc
                color #333333
            }
            element "External" {
                background #999999
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
