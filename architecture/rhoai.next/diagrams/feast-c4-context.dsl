workspace {
    model {
        dataScientist = person "Data Scientist" "Creates FeatureStore CRs and uses features for ML model training and inference"
        mlApplication = person "ML Application" "Consumes online features for real-time inference"

        feast = softwareSystem "Feast (Feature Store)" "Open-source feature store for ML that manages offline/online feature storage and serving" {
            feastOperator = container "Feast Operator" "Manages FeatureStore CRs; deploys and reconciles feature store infrastructure" "Go 1.25 / controller-runtime v0.18.0" {
                feastController = component "FeatureStore Controller" "Reconciles FeatureStore CRs" "controller-runtime"
                notebookController = component "Notebook ConfigMap Controller" "Injects feast client config into KubeFlow notebooks" "controller-runtime"
                tlsWatcher = component "TLS Profile Watcher" "Watches OpenShift TLS cipher suite policies" "controller-runtime"
                accessController = component "Auto-Access RBAC Controller" "Creates K8s RBAC from feast permission policies" "controller-runtime"
            }

            featureServer = container "Feature Server" "Serves online features via REST/gRPC, manages registry, runs materialization" "Python 3.12 / FastAPI / uvicorn" {
                onlineServing = component "Online Serving" "GET/POST /get-online-features" "FastAPI"
                registryAPI = component "Registry REST API" "CRUD for entities, feature views, data sources, permissions" "FastAPI"
                offlineProcessing = component "Offline Server" "Batch feature processing" "Python"
                metricsExporter = component "Prometheus Metrics" "Exposes /metrics on port 8000" "prometheus_client"
            }

            feastUI = container "Feast UI" "Web interface for browsing feature store objects" "React / TypeScript"

            cronJob = container "Materialization CronJob" "Scheduled feature materialization from offline to online store" "origin-cli / kubectl exec"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External Platform"
        openshiftAPI = softwareSystem "OpenShift API" "OpenShift-specific API for TLS profiles and routes" "External Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages ServiceMonitor CRDs for metrics collection" "Internal Platform"
        kubeflowNotebooks = softwareSystem "KubeFlow Notebook Controller" "Manages Notebook CRDs for data science workflows" "Internal Platform"
        sparkOperator = softwareSystem "Spark Operator" "Manages SparkApplication CRDs for batch compute" "Internal Platform"
        certSigner = softwareSystem "OpenShift Cert Signer" "Auto-provisions TLS certificates via service annotations" "Internal Platform"

        redis = softwareSystem "Redis" "In-memory data store for low-latency online feature serving" "External Service"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline store or registry" "External Service"
        dynamodb = softwareSystem "DynamoDB" "AWS managed NoSQL for online store" "External Service"
        bigquery = softwareSystem "BigQuery" "GCP managed data warehouse for offline store" "External Service"
        snowflake = softwareSystem "Snowflake" "Cloud data platform for online/offline store" "External Service"
        oidcProvider = softwareSystem "OIDC Provider" "Identity provider for JWT token validation" "External Service"
        openlineage = softwareSystem "OpenLineage" "Data lineage tracking platform" "External Service"

        # Relationships - Users
        dataScientist -> feast "Creates FeatureStore CRs, browses features via UI" "kubectl / HTTP"
        mlApplication -> feast "Retrieves online features for inference" "HTTP/gRPC 6566"

        # Relationships - Operator to Platform
        feast -> kubernetesAPI "Manages Deployments, Services, ConfigMaps, RBAC, CronJobs" "HTTPS/6443 SA token"
        feast -> openshiftAPI "Discovers TLS profiles, manages Routes" "HTTPS/6443 SA token"
        feast -> prometheusOperator "Creates ServiceMonitor for metrics" "CRD"
        feast -> kubeflowNotebooks "Watches Notebooks with feast-integration label" "CRD Watch"
        feast -> sparkOperator "Creates RBAC for SparkApplication jobs" "CRD"
        certSigner -> feast "Auto-provisions TLS certificates" "Annotation"

        # Relationships - Feature Server to Data Stores
        feast -> redis "Read/write online features" "TCP/6379 Password"
        feast -> postgresql "Read/write features, registry storage" "TCP/5432 Credentials"
        feast -> dynamodb "Read/write online features" "HTTPS/443 AWS IAM"
        feast -> bigquery "Read historical features" "HTTPS/443 GCP IAM"
        feast -> snowflake "Read/write features" "HTTPS/443 Credentials"
        feast -> oidcProvider "Validate JWT tokens" "HTTPS/443 OIDC Discovery"
        feast -> openlineage "Track data lineage" "HTTPS/443 API Key"
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

        component feastOperator "OperatorComponents" {
            include *
            autoLayout
        }

        component featureServer "FeatureServerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
        }
    }
}
