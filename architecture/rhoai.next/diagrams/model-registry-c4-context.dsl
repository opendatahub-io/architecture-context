workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, registers, and deploys ML models"
        mlEngineer = person "ML Engineer" "Manages model lifecycle, serving environments, and async uploads"

        modelRegistry = softwareSystem "Model Registry" "Central metadata repository for ML models, versions, artifacts, experiments, and catalog browsing" {
            proxy = container "Model Registry Proxy" "REST API server for model metadata CRUD operations" "Go Service, chi router, GORM" "Primary"
            catalog = container "Catalog Server" "Model and MCP server catalog browsing with plugin architecture and leader election" "Go Service, pglock"
            controller = container "InferenceService Controller" "Watches KServe ISVCs and synchronizes metadata with model registry" "Go Controller, controller-runtime"
            csi = container "CSI Storage Initializer" "Resolves model-registry:// URIs for KServe model serving" "Go CLI, init container"
            asyncUpload = container "Async Upload Job" "Copies models between storage backends with optional Sigstore signing" "Python K8s Job, skopeo"
            ui = container "Model Registry UI" "Web UI for model registry browsing and management" "Go BFF + React"
        }

        mysql = softwareSystem "MySQL" "Primary metadata storage for proxy server" "External Database"
        postgresql = softwareSystem "PostgreSQL" "Metadata storage for proxy or catalog; leader election via pglock" "External Database"
        kserve = softwareSystem "KServe" "Kubernetes-native ML model serving with InferenceService CRD" "Internal ODH"
        istio = softwareSystem "Istio Service Mesh" "mTLS, AuthorizationPolicy, traffic routing via VirtualService" "Internal Platform"
        huggingface = softwareSystem "HuggingFace Hub" "External model metadata source for catalog" "External"
        s3 = softwareSystem "AWS S3" "Model artifact storage" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/model image storage (Docker Registry v2)" "External"
        sigstore = softwareSystem "Sigstore" "Model signing via Fulcio (certs), Rekor (transparency log), TUF (trust root)" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API for resource management" "Internal Platform"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys model registry instances via kustomize manifests" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Platform UI that integrates with model registry" "Internal ODH"

        # User interactions
        dataScientist -> modelRegistry "Registers models, creates versions, browses catalog via REST API"
        mlEngineer -> modelRegistry "Manages serving environments, triggers async uploads"

        # Internal container interactions
        proxy -> mysql "Stores metadata" "MySQL/3306 TCP, Optional TLS, user/pass"
        proxy -> postgresql "Stores metadata" "PostgreSQL/5432 TCP, Optional TLS, user/pass"
        catalog -> postgresql "Catalog data + leader election" "PostgreSQL/5432 TCP, pglock"
        catalog -> huggingface "Fetches model metadata" "HTTPS/443, Bearer HF_API_KEY"
        controller -> proxy "Syncs ISVC metadata" "HTTP/8080, Bearer token"
        controller -> k8sApi "Watches ISVCs, updates labels" "HTTPS/443, SA token"
        csi -> proxy "Resolves model-registry:// URIs" "HTTP/8080"
        csi -> s3 "Downloads model artifacts" "HTTPS/443, Provider auth"
        asyncUpload -> s3 "Downloads models" "HTTPS/443, AWS IAM"
        asyncUpload -> ociRegistry "Pushes models as OCI images" "HTTPS/443, Docker auth"
        asyncUpload -> sigstore "Signs models" "HTTPS/443, Identity token"
        asyncUpload -> proxy "Registers metadata" "HTTP(S)/8080-443, Bearer token"
        ui -> proxy "REST API calls" "HTTP/8080"
        ui -> catalog "REST API calls" "HTTP/8080"

        # Platform interactions
        istio -> proxy "mTLS + AuthorizationPolicy"
        istio -> catalog "mTLS + AuthorizationPolicy"
        rhodsOperator -> modelRegistry "Deploys instances" "Kustomize manifests"
        dashboard -> modelRegistry "UI integration" "REST API/8080"
        kserve -> controller "InferenceService CRD events" "K8s API watch"
        kserve -> csi "Triggers CSI for model-registry:// URIs" "ClusterStorageContainer"
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
            element "External Database" {
                background #999999
                color #ffffff
                shape Cylinder
            }
            element "Internal ODH" {
                background #7ed321
            }
            element "Internal Platform" {
                background #d5e8d4
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Primary" {
                background #4a90e2
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
