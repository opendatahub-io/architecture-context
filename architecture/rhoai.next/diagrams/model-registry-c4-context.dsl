workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, browses model catalog"
        mlEngineer = person "ML Engineer" "Manages model serving and deployment pipelines"

        modelRegistry = softwareSystem "Model Registry" "Central repository for ML model metadata, versions, artifacts, and serving metadata" {
            proxy = container "model-registry (proxy)" "Core REST API server for ML metadata CRUD operations" "Go REST API" "Primary"
            controller = container "model-registry-controller" "Reconciles KServe InferenceService CRs with registry metadata" "Go Controller (controller-runtime)" "Optional"
            bff = container "model-registry-ui (BFF)" "Proxies UI requests to registry and catalog APIs, handles auth" "Go BFF Server"
            catalogServer = container "model-catalog-server" "Aggregates model metadata from Hugging Face, YAML, DB sources" "Go REST API" "Optional"
            csi = container "storage-initializer (CSI)" "Resolves model-registry:// URIs for KServe model download" "Go CLI (KServe Plugin)" "Utility"
            asyncUpload = container "async-upload-job" "Copies models between storage backends with signing support" "Python K8s Job" "Utility"
            frontend = container "model-registry-ui (frontend)" "User interface for browsing and managing models" "React/TypeScript SPA"
        }

        mysqlDB = softwareSystem "MySQL Database" "Primary metadata storage (8.3+)" "Database"
        postgresDB = softwareSystem "PostgreSQL Database" "Alternative metadata / catalog storage (16+)" "Database"

        istio = softwareSystem "Istio Service Mesh" "Traffic routing, mTLS, authorization policies" "External Infrastructure"
        kserve = softwareSystem "KServe" "Serverless ML inference platform, InferenceService CRD" "Internal ODH"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Platform UI for data science workflows" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator deploying model registry via kustomize" "Internal ODH"

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and RBAC" "External Infrastructure"
        huggingFace = softwareSystem "Hugging Face API" "External model metadata source" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for model images" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Infrastructure"

        # User relationships
        dataScientist -> modelRegistry "Registers models, browses catalog via UI"
        mlEngineer -> modelRegistry "Manages model versions and deployments via API"

        # Internal container relationships
        frontend -> bff "HTTP requests" "HTTPS/HTTP"
        bff -> proxy "Proxies model registry API calls" "HTTP/8080"
        bff -> catalogServer "Proxies catalog API calls" "HTTP/8080"
        bff -> k8sAPI "Namespace listing, RBAC checks" "HTTPS/443"
        controller -> proxy "Creates/updates InferenceService metadata" "HTTP/8080 Bearer Token"
        controller -> k8sAPI "Watches InferenceService CRs, updates labels" "HTTPS/443 ServiceAccount"
        csi -> proxy "Resolves model-registry:// URIs" "HTTP/8080"
        asyncUpload -> proxy "Registers model artifacts" "HTTP/8080 Bearer Token"

        # External dependencies
        proxy -> mysqlDB "Stores/retrieves model metadata" "MySQL/3306"
        proxy -> postgresDB "Stores/retrieves model metadata" "PostgreSQL/5432"
        catalogServer -> postgresDB "Stores catalog metadata" "PostgreSQL/5432"
        catalogServer -> huggingFace "Imports external model metadata" "HTTPS/443"
        asyncUpload -> s3Storage "Downloads model files" "HTTPS/443"
        asyncUpload -> ociRegistry "Pushes model OCI artifacts" "HTTPS/443"
        csi -> s3Storage "Delegates model download" "HTTPS/443"

        # Platform integration
        istio -> modelRegistry "mTLS traffic routing via VirtualService" "HTTP/8080 mTLS"
        rhoaiDashboard -> bff "Browses models, manages registries" "HTTP/8080"
        rhodsOperator -> modelRegistry "Deploys via kustomize manifests" "Kustomize"
        kserve -> controller "InferenceService CR events trigger reconciliation" "HTTPS/443 K8s API"
        prometheus -> controller "Scrapes /metrics endpoint" "HTTPS/8443 TokenReview"
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
            element "External Infrastructure" {
                background #888888
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #333333
            }
            element "Database" {
                background #4a90e2
                color #ffffff
                shape Cylinder
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                background #6ab0de
                color #ffffff
            }
            element "Utility" {
                background #95c8e8
                color #333333
            }
            element "Person" {
                background #f5a623
                color #333333
                shape Person
            }
        }
    }
}
