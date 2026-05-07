workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, registers model metadata"
        mlEngineer = person "ML Engineer" "Manages model lifecycle, triggers async uploads"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and Model Registry instances"

        modelRegistry = softwareSystem "Model Registry" "Central REST API service for recording, retrieving, and managing ML model metadata" {
            proxy = container "model-registry (proxy)" "Primary REST API server — 91 OpenAPI v1alpha3 operations for model metadata CRUD" "Go REST API, Port 8080/TCP"
            embedmd = container "EmbedMD Datastore" "Metadata persistence layer using GORM ORM" "Go, GORM"
            controllerManager = container "controller-manager" "Kubernetes controller that watches KServe InferenceService CRs and syncs metadata" "Go Controller, Port 8081/TCP"
            storageInitializer = container "mr-storage-initializer" "KServe CSI storage initializer — resolves model-registry:// URIs to actual storage backends" "Go CLI"
            asyncUpload = container "async-upload job" "Kubernetes Job that copies models between S3/OCI storage and registers metadata" "Python 3.12, Batch Job"
            ui = container "model-registry-ui" "Web interface for browsing and managing model registry entries" "TypeScript/Go BFF, Port 8080/TCP"
            catalog = container "catalog" "Model catalog service for curating and discovering ML models" "Go REST API"

            proxy -> embedmd "Uses for data access" "Go function calls"
        }

        # External Dependencies
        mysql = softwareSystem "MySQL 8.3+" "Relational database for metadata persistence (MySQL mode)" "External"
        postgresql = softwareSystem "PostgreSQL 16+" "Relational database for metadata persistence (PostgreSQL mode)" "External"
        kserve = softwareSystem "KServe" "ML model serving platform — provides InferenceService CRD and ClusterStorageContainer" "Internal ODH"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS enforcement, traffic routing, and authorization policies" "External"
        kubeflowGateway = softwareSystem "Kubeflow Gateway" "Istio ingress gateway for external API traffic routing" "Internal ODH"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management, leader election, service discovery" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for ML model artifacts" "External"
        ociRegistry = softwareSystem "OCI Registries" "Container/model image registries" "External"
        sigstore = softwareSystem "Sigstore/Rekor" "Supply chain security — model and image signing" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator — deploys and configures Model Registry instances" "Internal ODH"

        # Person → System relationships
        dataScientist -> modelRegistry "Registers models, creates versions, browses catalog" "REST API / Web UI"
        mlEngineer -> modelRegistry "Triggers async uploads, manages model lifecycle" "REST API / K8s Jobs"
        platformAdmin -> rhodsOperator "Configures Model Registry instances" "Kubernetes CRDs"

        # Internal container relationships
        embedmd -> mysql "Persists metadata" "TCP/3306, username/password"
        embedmd -> postgresql "Persists metadata" "TCP/5432, username/password"
        controllerManager -> proxy "Syncs InferenceService metadata" "HTTP/8080, Bearer Token"
        controllerManager -> k8sAPI "Watches InferenceService CRs, leader election" "HTTPS/6443, SA token"
        storageInitializer -> proxy "Resolves model-registry:// URIs" "HTTP/8080"
        storageInitializer -> s3 "Downloads model artifacts" "HTTPS/443, Provider-specific"
        asyncUpload -> proxy "Registers/updates model metadata" "HTTP/8080, Bearer Token"
        asyncUpload -> s3 "Reads/writes model files" "HTTPS/443, AWS IAM"
        asyncUpload -> ociRegistry "Reads/writes model images" "HTTPS/443, username/password"
        asyncUpload -> sigstore "Signs models and images" "HTTPS/443, OIDC"
        ui -> proxy "Calls REST API" "HTTP/8080"
        ui -> k8sAPI "Service discovery, SubjectAccessReview" "HTTPS/6443, SA token"

        # System → External relationships
        modelRegistry -> kserve "Controller watches InferenceService CRs; CSI registers as storage provider" "HTTPS/6443"
        modelRegistry -> istio "mTLS enforcement, VirtualService routing, AuthorizationPolicy" "Istio mTLS"
        kubeflowGateway -> modelRegistry "Routes /api/model_registry/ to service" "HTTP/8080, mTLS"
        rhodsOperator -> modelRegistry "Deploys and manages instances" "Kubernetes API"
        prometheus -> modelRegistry "Scrapes /metrics from controller" "HTTPS/8443, TokenReview"
    }

    views {
        systemContext modelRegistry "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistry "Containers" {
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
