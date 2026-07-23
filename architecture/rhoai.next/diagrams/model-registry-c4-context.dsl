workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, registers, and deploys ML models"
        mlEngineer = person "ML Engineer" "Manages model lifecycle and deployments"

        modelRegistry = softwareSystem "Model Registry" "Central metadata service for ML model registration, versioning, artifact tracking, and curated catalogs" {
            proxyServer = container "model-registry (proxy)" "REST API server for model metadata CRUD operations (registered models, versions, artifacts, inference services, serving environments, experiments)" "Go REST Service" "8080/TCP"
            catalogServer = container "model-catalog" "Curates model catalogs (HuggingFace), MCP server catalogs, and agent catalogs with plugin architecture and leader election" "Go Service" "8080/TCP"
            isController = container "inference-service-controller" "Watches KServe InferenceService CRDs and synchronizes deployment state to Model Registry" "Go Controller (controller-runtime)"
            storageInitializer = container "storage-initializer (CSI)" "KServe storage provider for model-registry:// URI scheme, resolves model artifacts for download" "Go CLI"
            ui = container "model-registry-ui" "Web UI for browsing and managing models, versions, artifacts, and catalogs" "React/TypeScript + Go BFF" "8080/TCP"
            asyncUploadJob = container "async-upload-job" "K8s Job that copies models between S3/OCI storage backends with optional Sigstore signing" "Python Job"
        }

        registryDB = softwareSystem "Registry PostgreSQL" "Persistent metadata storage for model registry" "Database"
        catalogDB = softwareSystem "Catalog PostgreSQL" "Persistent metadata storage for catalogs" "Database"

        istio = softwareSystem "Istio Service Mesh" "Traffic routing, mTLS encryption, and authorization" "External Platform"
        kserve = softwareSystem "KServe" "Serverless ML inference platform with InferenceService CRD" "Internal ODH"
        kubeflowGateway = softwareSystem "Kubeflow Gateway" "Istio ingress gateway for unified access" "Internal ODH"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External Platform"

        huggingFace = softwareSystem "HuggingFace" "Model metadata and artifact source" "External SaaS"
        s3Storage = softwareSystem "S3 Storage" "ML model artifact storage (S3-compatible)" "External Storage"
        ociRegistry = softwareSystem "OCI Registry" "Container and model artifact registry" "External Storage"
        sigstore = softwareSystem "Sigstore" "Model and image signing (Fulcio, Rekor, TUF)" "External Security"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"

        # Person → System relationships
        dataScientist -> modelRegistry "Registers models, browses catalogs via" "HTTPS/443"
        mlEngineer -> modelRegistry "Manages model lifecycle, deploys models via" "HTTPS/443"

        # System → System relationships
        modelRegistry -> registryDB "Stores model metadata in" "TCP/5432"
        modelRegistry -> catalogDB "Stores catalog data in" "TCP/5432"
        modelRegistry -> huggingFace "Syncs model catalog from" "HTTPS/443"
        modelRegistry -> s3Storage "Uploads/downloads model artifacts via" "HTTPS/443"
        modelRegistry -> ociRegistry "Pushes/pulls OCI model artifacts via" "HTTPS/443"
        modelRegistry -> sigstore "Signs models and images via" "HTTPS/443"
        modelRegistry -> kserve "Syncs InferenceService state with" "K8s API + REST"
        modelRegistry -> k8sAPI "Manages resources, checks permissions via" "HTTPS/443"
        modelRegistry -> istio "Traffic secured by" "mTLS STRICT"
        kubeflowGateway -> modelRegistry "Routes external traffic to" "HTTP/8080"
        prometheus -> modelRegistry "Scrapes metrics from" "HTTPS/8443"

        # Container-level relationships
        dataScientist -> ui "Browses models and catalogs" "HTTPS/443 via Kubeflow Gateway"
        dataScientist -> proxyServer "Registers and queries models" "REST API via Kubeflow Gateway"

        proxyServer -> registryDB "GORM queries" "TCP/5432"
        catalogServer -> catalogDB "GORM queries + pglock leader election" "TCP/5432"
        catalogServer -> huggingFace "Fetches model metadata" "HTTPS/443 Bearer"
        isController -> proxyServer "Syncs InferenceService state" "HTTP(S)/8080"
        isController -> k8sAPI "Watches InferenceService CRDs" "HTTPS/443 SA token"
        storageInitializer -> proxyServer "Resolves model-registry:// URIs" "HTTP/8080"
        storageInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443"
        ui -> k8sAPI "SubjectAccessReview permission checks" "HTTPS/443 SA token"
        asyncUploadJob -> proxyServer "Registers/updates model artifacts" "HTTPS/443 Bearer"
        asyncUploadJob -> s3Storage "Uploads/downloads models" "HTTPS/443 AWS IAM"
        asyncUploadJob -> ociRegistry "Pushes/pulls OCI artifacts" "HTTPS/443 Docker"
        asyncUploadJob -> sigstore "Signs models" "HTTPS/443 OIDC"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External SaaS" {
                background #f5a623
                color #ffffff
            }
            element "External Storage" {
                background #e67e22
                color #ffffff
            }
            element "External Security" {
                background #e74c3c
                color #ffffff
            }
            element "Database" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
