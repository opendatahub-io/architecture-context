workspace {
    model {
        datascientist = person "Data Scientist" "Creates, registers, and deploys ML models"
        mlEngineer = person "ML Engineer" "Manages model lifecycle and serving infrastructure"

        modelRegistry = softwareSystem "Model Registry" "Central metadata store for ML models, versions, and artifacts with REST API, UI, controller, and catalog" {
            proxyServer = container "model-registry proxy" "Core REST API server for model metadata CRUD operations" "Go Service, :8080/TCP"
            uiBFF = container "UI BFF" "Backend-for-Frontend mediating between React UI and registry API + Kubernetes resources" "Go Service, :8080/TCP"
            controller = container "Controller (manager)" "Watches KServe InferenceService resources, syncs model serving state with registry" "Go controller-runtime Operator"
            catalogServer = container "model-catalog-server" "Federated model catalog with plugin-based sources" "Go Service, :8080/TCP"
            storageInitializer = container "mr-storage-initializer" "KServe storage initializer that downloads model artifacts from registry" "Go CLI (init container)"
            asyncUploadJob = container "async-upload Job" "Copies models between storage backends with sigstore signing" "Python Job"
        }

        postgresql = softwareSystem "PostgreSQL" "Primary metadata storage for model registry and catalog" "External"
        kserve = softwareSystem "KServe" "ML model serving platform providing InferenceService CRDs" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and RBAC" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, and authorization" "Internal RHOAI"
        huggingface = softwareSystem "HuggingFace" "External model metadata source for catalog discovery" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO)" "External"
        ociRegistries = softwareSystem "OCI Registries" "Container registries for model artifact push/pull" "External"

        datascientist -> modelRegistry "Registers models, browses catalog, deploys models via UI"
        mlEngineer -> modelRegistry "Manages model lifecycle via REST API"

        uiBFF -> proxyServer "Proxies model metadata requests" "HTTP/8080, Istio mTLS"
        uiBFF -> catalogServer "Fetches catalog models" "HTTP/8080"
        uiBFF -> kubernetesAPI "Manages ConfigMaps, Secrets, Jobs; RBAC checks" "HTTPS/6443"
        controller -> proxyServer "Syncs InferenceService state with registry" "HTTP/8080"
        controller -> kubernetesAPI "Watches InferenceService resources" "HTTPS/6443"
        storageInitializer -> proxyServer "Resolves model-registry:// URIs" "HTTP/8080"
        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443"
        asyncUploadJob -> s3Storage "Copies models between storage backends" "HTTPS/443"
        asyncUploadJob -> ociRegistries "Pushes/pulls model artifacts" "HTTPS/443"
        asyncUploadJob -> proxyServer "Registers model artifacts" "HTTP/8080"
        proxyServer -> postgresql "Stores model metadata" "SQL/5432"
        catalogServer -> postgresql "Stores catalog data" "SQL/5432"
        catalogServer -> huggingface "Fetches model metadata" "HTTPS/443"
        modelRegistry -> istio "Uses for traffic routing, mTLS, AuthorizationPolicy" ""
        modelRegistry -> kserve "Watches InferenceService CRs (conditional)" ""
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
