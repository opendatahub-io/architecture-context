workspace {
    model {
        dataScientist = person "Data Scientist" "Registers, versions, and tracks ML models"
        mlEngineer = person "ML Engineer" "Deploys models and manages inference services"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components"

        modelRegistry = softwareSystem "Model Registry" "Central metadata repository for ML model registration, versioning, and tracking (OpenAPI v1alpha3)" {
            proxy = container "model-registry proxy" "REST API server exposing OpenAPI v1alpha3 endpoints for model metadata CRUD" "Go REST Service (chi router)" {
                tags "Primary"
            }
            catalog = container "model-registry catalog" "Unified catalog API for querying models from HuggingFace and MCP servers" "Go REST Service" {
                tags "Optional"
            }
            controller = container "model-registry controller" "Watches KServe InferenceService CRDs and syncs lifecycle with registry metadata" "Go controller-runtime" {
                tags "Optional"
            }
            csi = container "CSI Storage Initializer" "Downloads model artifacts from registry for KServe inference pods via model-registry:// URI" "Go CLI (KServe Provider)" {
                tags "Sidecar"
            }
            asyncUpload = container "async-upload Job" "Transfers model artifacts between storage backends (S3, OCI, HTTP) and registers them" "Python 3.12 Kubernetes Job" {
                tags "Batch"
            }
        }

        # Internal Platform Systems
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" {
            tags "Internal RHOAI"
        }
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, and authorization" {
            tags "Internal RHOAI"
        }
        dashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform management" {
            tags "Internal RHOAI"
        }
        pythonClient = softwareSystem "Model Registry Python Client" "Python SDK for programmatic model registration (pip: model-registry>=0.3.7)" {
            tags "Internal RHOAI"
        }

        # External Systems
        mysql = softwareSystem "MySQL 8.3" "Relational database for model metadata storage" {
            tags "Database"
        }
        postgresql = softwareSystem "PostgreSQL 16+" "Relational database for model/catalog metadata storage" {
            tags "Database"
        }
        s3 = softwareSystem "S3-compatible Storage" "Object storage for model artifacts" {
            tags "External"
        }
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for model images" {
            tags "External"
        }
        huggingface = softwareSystem "HuggingFace Hub" "Public model hub for metadata and downloads" {
            tags "External"
        }
        sigstore = softwareSystem "Sigstore (Fulcio/Rekor)" "Code signing and transparency log service" {
            tags "External"
        }
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" {
            tags "Infrastructure"
        }

        # Person → System relationships
        dataScientist -> modelRegistry "Registers models, versions, artifacts via REST API or Python SDK"
        mlEngineer -> modelRegistry "Deploys models, manages inference services"
        platformAdmin -> modelRegistry "Configures model registry, manages catalog sources"

        # Container-level relationships
        dataScientist -> proxy "POST/GET /api/model_registry/v1alpha3/*" "HTTP/8080"
        dataScientist -> catalog "GET /api/model_catalog/v1alpha1/*" "HTTP/8080"

        proxy -> mysql "Stores/retrieves model metadata" "MySQL protocol/3306"
        proxy -> postgresql "Stores/retrieves model metadata" "PostgreSQL protocol/5432"

        catalog -> postgresql "Stores/retrieves catalog metadata" "PostgreSQL protocol/5432"
        catalog -> huggingface "Fetches model metadata" "HTTPS/443"

        controller -> proxy "Syncs InferenceService metadata" "HTTP/8080 Bearer Token"
        controller -> k8sApi "Watches InferenceService CRDs, updates labels/finalizers" "HTTPS/443 SA Token"

        csi -> proxy "Resolves model artifacts by name/version" "HTTP/8080"
        csi -> s3 "Downloads model files" "HTTPS/443"

        asyncUpload -> proxy "Registers models and artifacts" "HTTP/8080"
        asyncUpload -> s3 "Downloads/uploads model artifacts" "HTTPS/443 AWS IAM"
        asyncUpload -> ociRegistry "Pushes model artifacts as OCI images" "HTTPS/443 Docker creds"
        asyncUpload -> huggingface "Downloads models" "HTTPS/443 HF Token"
        asyncUpload -> sigstore "Signs model artifacts" "HTTPS/443 OIDC"

        # System-level relationships
        istio -> modelRegistry "Routes traffic via VirtualService, enforces mTLS and AuthorizationPolicy"
        dashboard -> modelRegistry "Reads/writes model metadata via REST API" "HTTP/8080"
        pythonClient -> modelRegistry "Programmatic model registration" "HTTP(S)/8080"
        kserve -> modelRegistry "InferenceService lifecycle sync (controller); model downloads (CSI)"
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
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Optional" {
                background #7ed321
                color #ffffff
            }
            element "Sidecar" {
                background #50e3c2
                color #333333
            }
            element "Batch" {
                background #b8e986
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Database" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #bd10e0
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
