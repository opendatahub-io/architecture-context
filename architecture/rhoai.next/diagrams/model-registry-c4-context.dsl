workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, registers, and deploys ML models"
        mlEngineer = person "ML Engineer" "Manages model serving and deployment pipelines"

        modelRegistry = softwareSystem "Model Registry" "Central repository for ML model metadata, versions, artifacts, and serving environments" {
            proxy = container "model-registry (proxy)" "Core REST API server for ML metadata CRUD operations" "Go REST API" "Primary"
            controller = container "model-registry-controller" "Reconciles KServe InferenceService CRs with registry metadata" "Go Controller (controller-runtime)" "Optional"
            bff = container "model-registry-ui (BFF)" "Backend-For-Frontend proxying UI requests to registry and catalog APIs" "Go BFF Server"
            frontend = container "model-registry-ui (frontend)" "User interface for browsing and managing models" "React/TypeScript SPA"
            catalogServer = container "model-catalog-server" "Aggregates model catalog data from multiple sources" "Go REST API" "Optional"
            csi = container "storage-initializer (CSI)" "Resolves model-registry:// URIs for KServe model download" "Go CLI (KServe Plugin)" "Utility"
            asyncJob = container "async-upload-job" "Orchestrates model file transfers between storage backends" "Python K8s Job" "Utility"
        }

        # External Dependencies
        mysql = softwareSystem "MySQL 8.3+" "Primary metadata storage for model registry" "External Database"
        postgresql = softwareSystem "PostgreSQL 16+" "Alternative metadata storage; catalog database" "External Database"
        kserve = softwareSystem "KServe" "ML model serving platform with InferenceService CRDs" "Internal ODH"
        istio = softwareSystem "Istio Service Mesh" "Traffic routing, mTLS, and authorization" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for resource management and RBAC" "Internal Platform"

        # Internal ODH Components
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Platform dashboard UI for model management" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys model registry via kustomize" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal ODH"

        # External Services
        huggingFace = softwareSystem "Hugging Face API" "External model metadata source for catalog import" "External Service"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (S3, GCS, MinIO)" "External Service"
        ociRegistry = softwareSystem "OCI Registry" "Container/model image registry" "External Service"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"

        # User interactions
        dataScientist -> modelRegistry "Registers models, creates versions, browses catalog via UI"
        mlEngineer -> modelRegistry "Manages serving environments, deploys models via API/CLI"

        # Frontend → BFF
        frontend -> bff "API requests" "HTTP/8080"
        bff -> proxy "Proxies model registry API calls" "HTTP/8080"
        bff -> catalogServer "Proxies catalog API calls" "HTTP/8080"
        bff -> k8sAPI "Namespace listing, RBAC checks, service discovery" "HTTPS/443"

        # Core API → Database
        proxy -> mysql "Metadata CRUD (default backend)" "MySQL/3306"
        proxy -> postgresql "Metadata CRUD (alternative backend)" "PostgreSQL/5432"

        # Catalog
        catalogServer -> postgresql "Catalog metadata storage" "PostgreSQL/5432"
        catalogServer -> huggingFace "Model metadata import" "HTTPS/443"

        # Controller
        controller -> proxy "Syncs InferenceService metadata" "HTTP/8080"
        controller -> k8sAPI "Watches InferenceService CRs, updates labels/finalizers" "HTTPS/443"
        kserve -> k8sAPI "Creates InferenceService CRs" "HTTPS/443"

        # CSI Storage Initializer
        csi -> proxy "Resolves model-registry:// URIs" "HTTP/8080"
        csi -> s3Storage "Downloads model artifacts" "HTTPS/443"

        # Async Upload
        asyncJob -> proxy "Registers/updates model artifacts" "HTTP/8080"
        asyncJob -> s3Storage "Downloads model files" "HTTPS/443"
        asyncJob -> ociRegistry "Pushes models as OCI artifacts" "HTTPS/443"

        # Platform Integration
        istio -> modelRegistry "Traffic routing, mTLS, AuthorizationPolicy" "mTLS"
        rhodsOperator -> modelRegistry "Deploys via kustomize manifests" "Kustomize"
        rhoaiDashboard -> bff "UI for browsing and managing models" "HTTP/8080"
        prometheus -> controller "Scrapes /metrics endpoint" "HTTPS/8443"
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
            element "External Database" {
                shape Cylinder
                background #f5a623
                color #ffffff
            }
            element "External Service" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Primary" {
                background #1a5276
                color #ffffff
            }
            element "Optional" {
                background #2e86c1
                color #ffffff
            }
            element "Utility" {
                background #9b59b6
                color #ffffff
            }
        }
    }
}
