workspace {
    model {
        datascientist = person "Data Scientist" "Creates, versions, and deploys ML models"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and pipelines"

        modelRegistry = softwareSystem "Model Registry" "Central repository for ML model metadata, versions, and artifacts with REST API" {
            apiServer = container "REST API Server" "Core REST API for model metadata CRUD operations (v1alpha3)" "Go Service, Port 8080"
            catalogService = container "Model Catalog Service" "Read-only catalog browsing API for YAML and HuggingFace models (v1alpha1)" "Go Service, Port 8080"
            controller = container "InferenceService Controller" "Reconciles KServe InferenceService CRDs with registry metadata" "Go Controller (controller-runtime)"
            csiInitializer = container "CSI Storage Initializer" "Downloads model artifacts via model-registry:// URI scheme" "Go CLI (init container)"
            asyncUploadJob = container "Async Upload Job" "Copies models between S3/OCI/HF backends and registers artifacts" "Python Job"
            embedmd = container "EmbedMD Storage Layer" "ORM-based metadata storage with GORM and golang-migrate" "Go Library"
        }

        database = softwareSystem "MySQL / PostgreSQL" "Relational database for persistent model metadata storage" "External"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS, traffic routing, and authorization policies" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and CRD operations" "Infrastructure"
        s3 = softwareSystem "S3 / MinIO Storage" "Object storage for ML model artifacts" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Container registry for storing model images" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Public model hub for browsing and downloading models" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing models and ML workflows" "Internal RHOAI"

        # User interactions
        datascientist -> modelRegistry "Registers models, creates versions, browses catalogs" "REST API / Dashboard"
        mlEngineer -> modelRegistry "Manages serving environments and inference services" "REST API / Dashboard"
        dashboard -> modelRegistry "UI operations for model management" "HTTP/8080, Istio mTLS"

        # Internal container relationships
        apiServer -> embedmd "Uses for data access"
        embedmd -> database "SQL queries" "MySQL 3306/TCP or PostgreSQL 5432/TCP, Optional TLS"
        catalogService -> huggingface "Fetches model catalogs" "HTTPS/443, Bearer token"
        controller -> apiServer "CRUD on ServingEnvironments, InferenceServices" "HTTP/8080, Bearer token"
        controller -> k8sAPI "Watches InferenceService CRDs, updates labels/finalizers" "HTTPS/6443, ServiceAccount token"
        csiInitializer -> apiServer "Resolves model-registry:// URIs" "HTTP/8080"
        csiInitializer -> s3 "Downloads model artifacts" "HTTPS/443, AWS IAM"
        asyncUploadJob -> apiServer "Registers model artifacts" "HTTP/8080, Bearer token"
        asyncUploadJob -> s3 "Downloads models from source" "HTTPS/443, IAM credentials"
        asyncUploadJob -> ociRegistry "Pushes models to destination" "HTTPS/443, Docker config"
        asyncUploadJob -> huggingface "Downloads models" "HTTPS/443, API token"

        # External system interactions
        modelRegistry -> database "Stores model metadata" "MySQL/PostgreSQL, Optional TLS"
        modelRegistry -> istio "Network security and traffic management" "mTLS STRICT"
        modelRegistry -> kserve "Watches InferenceService CRDs" "HTTPS/6443"
        modelRegistry -> s3 "Model artifact storage" "HTTPS/443"
        modelRegistry -> ociRegistry "Model image storage" "HTTPS/443"
        prometheus -> modelRegistry "Scrapes controller metrics" "HTTPS/8443, TokenReview"
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
            element "Infrastructure" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
