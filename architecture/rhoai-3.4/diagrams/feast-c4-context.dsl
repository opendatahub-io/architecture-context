workspace {
    model {
        dataScientist = person "Data Scientist" "Creates feature definitions, deploys FeatureStore CRs, queries features from notebooks"
        mlApplication = person "ML Application" "Requests online features at inference time for model predictions"

        feast = softwareSystem "Feast" "Feature store for ML - manages storage, retrieval, and serving of ML features on Kubernetes/OpenShift" {
            feastOperator = container "Feast Operator" "Manages FeatureStore CRDs, deploys and reconciles Feast service infrastructure" "Go (controller-runtime)" "operator"
            notebookController = container "Notebook ConfigMap Controller" "Watches Kubeflow Notebooks, injects Feast client configuration" "Go (controller-runtime)" "operator"
            onlineServer = container "Online Store Server" "Serves online features via HTTP REST and gRPC for model inference" "Python (FastAPI/Gunicorn)" "service"
            offlineServer = container "Offline Store Server" "Serves historical features for training and batch predictions" "Python (FastAPI/Gunicorn)" "service"
            registryServer = container "Registry Server" "Stores and serves feature definitions, entities, data sources metadata" "Python (gRPC + REST)" "service"
            uiServer = container "UI Server" "Web interface for exploring feature store definitions" "Python" "service"
            cronJob = container "Materialization CronJob" "Periodically materializes features from offline to online store" "ose-cli (kubectl exec)" "cronjob"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Auto-provisions TLS certificates for services" "External"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Platform operator that deploys Feast via kustomize manifests" "Internal ODH"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook environment for data scientists" "Internal ODH"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection and monitoring" "External"

        redis = softwareSystem "Redis" "In-memory data store for online feature persistence" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline/registry persistence" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for registry file persistence" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for registry file persistence" "External"
        snowflake = softwareSystem "Snowflake" "Cloud data warehouse for online/offline/registry persistence" "External"
        oidcProvider = softwareSystem "OIDC Identity Provider" "External identity provider for token validation" "External"

        # User interactions
        dataScientist -> feast "Creates FeatureStore CRs via kubectl, defines features via SDK"
        mlApplication -> feast "POST /get-online-features for inference" "HTTP/HTTPS"

        # Internal container interactions
        feastOperator -> k8sAPI "CRUD Deployments, Services, ConfigMaps, RBAC, CronJobs" "HTTPS/443"
        feastOperator -> registryServer "Fetches permissions for auto-access RBAC" "HTTP(S)/6572-6573, JWT"
        feastOperator -> onlineServer "Deploys and manages lifecycle" "K8s API"
        feastOperator -> offlineServer "Deploys and manages lifecycle" "K8s API"
        feastOperator -> registryServer "Deploys and manages lifecycle" "K8s API"
        feastOperator -> uiServer "Deploys and manages lifecycle" "K8s API"
        feastOperator -> cronJob "Creates materialization CronJobs" "K8s API"
        notebookController -> kubeflowNotebooks "Watches Notebook CRs with feast-integration label" "K8s API"
        notebookController -> k8sAPI "Creates client ConfigMaps for notebooks" "HTTPS/443"
        cronJob -> onlineServer "kubectl exec: feast materialize" "K8s exec API"

        # External dependencies
        onlineServer -> redis "Read/write online features" "Redis/6379, Optional TLS"
        onlineServer -> postgresql "Read/write online features" "PG/5432, Optional TLS"
        offlineServer -> postgresql "Read historical features" "PG/5432, Optional TLS"
        offlineServer -> snowflake "Read historical features" "HTTPS/443"
        registryServer -> postgresql "Persist feature definitions" "PG/5432, Optional TLS"
        registryServer -> s3 "Persist registry files" "HTTPS/443"
        registryServer -> gcs "Persist registry files" "HTTPS/443"
        onlineServer -> oidcProvider "Validate OIDC tokens" "HTTPS/443"

        # Platform integrations
        odhOperator -> feast "Deploys via kustomize overlays"
        feast -> openshiftServiceCA "Auto-provisions TLS certificates" "Annotation-driven"
        feast -> prometheusOperator "Creates ServiceMonitor for metrics scraping" "K8s API"
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
            element "operator" {
                background #4a90e2
                color #ffffff
            }
            element "service" {
                background #50c878
                color #ffffff
            }
            element "cronjob" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
