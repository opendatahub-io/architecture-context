workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, registers, and deploys ML models via the dashboard or CLI"
        mlEngineer = person "ML Engineer" "Manages model serving environments and deployments"

        modelRegistry = softwareSystem "Model Registry" "Central repository for ML model metadata, versions, artifacts, and serving metadata" {
            proxy = container "model-registry (proxy)" "Core REST API server for ML metadata CRUD operations" "Go REST API, Port 8080" "Service"
            controller = container "model-registry-controller" "Reconciles KServe InferenceService CRs with registry metadata" "Go Controller (controller-runtime), Port 8081/8443" "Controller"
            bff = container "model-registry-ui (BFF)" "Backend-For-Frontend proxying UI requests to registry and catalog APIs" "Go BFF Server, Port 8080" "Service"
            frontend = container "model-registry-ui (frontend)" "User interface for browsing and managing models" "React/TypeScript SPA" "WebApp"
            catalogServer = container "model-catalog-server" "Aggregates model catalog data from multiple sources" "Go REST API, Port 8080" "Service"
            csi = container "storage-initializer (CSI)" "Resolves model-registry:// URIs for KServe model downloads" "Go CLI, KServe Plugin" "Plugin"
            asyncUpload = container "async-upload-job" "Orchestrates model file transfers between storage backends" "Python K8s Job" "Job"
        }

        mysql = softwareSystem "MySQL 8.3+" "Primary metadata storage for model registry" "Database"
        postgresql = softwareSystem "PostgreSQL 16+" "Metadata storage (alternative) and catalog database" "Database"
        kserve = softwareSystem "KServe" "Kubernetes-native serverless ML inference platform" "Internal ODH"
        istio = softwareSystem "Istio Service Mesh" "Traffic routing, mTLS enforcement, and authorization" "Internal Platform"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for RHOAI platform management" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys managed components" "Internal Platform"
        huggingFace = softwareSystem "Hugging Face API" "External ML model metadata and artifacts source" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Cloud object storage for model artifacts" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for model images" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster control plane API server" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "Internal Platform"

        # External interactions
        dataScientist -> modelRegistry "Registers models, browses catalog via Dashboard" "HTTPS/443"
        mlEngineer -> modelRegistry "Manages serving environments and deployments" "HTTPS/443"

        # Internal container relationships
        frontend -> bff "API requests" "HTTP/8080"
        bff -> proxy "Proxy model registry CRUD" "HTTP/8080, Forwarded token"
        bff -> catalogServer "Proxy catalog browsing" "HTTP/8080, Forwarded token"
        bff -> k8sAPI "Namespace listing, RBAC checks, service discovery" "HTTPS/443, User/SA token"
        controller -> proxy "Sync InferenceService metadata" "HTTP/8080, Bearer Token"
        controller -> k8sAPI "Watch InferenceService CRs, update labels" "HTTPS/443, ServiceAccount"
        csi -> proxy "Resolve model-registry:// URIs" "HTTP/8080"
        asyncUpload -> proxy "Register/update model artifacts" "HTTP/8080, Bearer Token"

        # External dependencies
        proxy -> mysql "Store/retrieve model metadata" "MySQL/3306, user/pass"
        proxy -> postgresql "Store/retrieve model metadata (alt)" "PostgreSQL/5432, user/pass"
        catalogServer -> postgresql "Catalog metadata storage" "PostgreSQL/5432, user/pass"
        catalogServer -> huggingFace "Import model metadata" "HTTPS/443, API key"
        csi -> s3Storage "Download model artifacts" "HTTPS/443, Storage credentials"
        asyncUpload -> s3Storage "Download model files" "HTTPS/443, AWS credentials"
        asyncUpload -> ociRegistry "Push/pull model images" "HTTPS/443, Registry credentials"

        # Platform integrations
        istio -> modelRegistry "mTLS enforcement, traffic routing, AuthorizationPolicy" "mTLS ISTIO_MUTUAL"
        rhoaiDashboard -> bff "Browse and manage models via BFF API" "HTTP/8080, Istio mTLS"
        rhodsOperator -> modelRegistry "Deploys via kustomize manifests" "Kustomize"
        kserve -> controller "InferenceService CR lifecycle events" "K8s API watch"
        csi -> kserve "Delegates model download to KServe storage providers" "ClusterStorageContainer"
        prometheus -> controller "Scrape controller metrics" "HTTPS/8443, TokenReview+SAR"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Database" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Controller" {
                background #9b59b6
                color #ffffff
            }
            element "WebApp" {
                background #50c878
                color #ffffff
                shape WebBrowser
            }
            element "Plugin" {
                background #9b59b6
                color #ffffff
            }
            element "Job" {
                background #e67e22
                color #ffffff
            }
        }
    }
}
