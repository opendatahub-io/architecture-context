workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, registers, and deploys ML models via Dashboard or SDK"
        mlEngineer = person "ML Engineer" "Manages model lifecycle, uploads, and serving configurations"

        modelRegistry = softwareSystem "Model Registry" "Central metadata repository for ML models, versions, artifacts, experiments, and serving environments" {
            proxy = container "Model Registry Proxy" "Core REST API server implementing Kubeflow Model Registry OpenAPI v1alpha3" "Go Service" "8080/TCP"
            catalogServer = container "Model Catalog Server" "Catalog browsing service for curated models and MCP servers from HuggingFace" "Go Service" "8080/TCP"
            controller = container "Model Registry Controller" "Watches KServe InferenceService CRs and syncs metadata with Model Registry" "Go Kubernetes Controller"
            csi = container "CSI Storage Initializer" "Resolves model-registry:// URIs to download model artifacts" "Go Init Container"
            asyncUpload = container "Async Upload Job" "Copies models between S3/OCI/HuggingFace backends with optional Sigstore signing" "Python K8s Job"
            uiBff = container "UI BFF" "Backend-For-Frontend proxy serving React UI and forwarding API calls" "Go HTTP Server" "8080/TCP"
            uiFrontend = container "React Frontend" "Web interface for browsing and managing registered models" "TypeScript React SPA"
            embedMD = container "EmbedMD" "Embedded metadata store using GORM ORM for SQL persistence" "Go Library"
        }

        # Internal Platform Dependencies
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal ODH"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for transport encryption (mTLS) and access control (AuthorizationPolicy)" "Internal Platform"
        dashboard = softwareSystem "OpenShift AI Dashboard" "Web UI for managing data science workloads" "Internal ODH"
        kubeAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Internal Platform"

        # External Dependencies
        postgresql = softwareSystem "PostgreSQL" "Primary relational database for metadata storage (v16+)" "External Database"
        mysql = softwareSystem "MySQL" "Alternative relational database for metadata storage (v8.3+)" "External Database"
        huggingface = softwareSystem "HuggingFace" "ML model hub for catalog model metadata" "External Service"
        s3 = softwareSystem "S3 Storage" "Object storage for model artifacts" "External Service"
        ociRegistry = softwareSystem "OCI Registry" "Container image registry for model artifacts" "External Service"
        sigstore = softwareSystem "Sigstore" "Artifact signing and verification (Fulcio/Rekor/TUF)" "External Service"

        # Person relationships
        dataScientist -> modelRegistry "Registers models, browses catalog, manages versions" "REST API / Web UI"
        mlEngineer -> modelRegistry "Uploads models, configures serving, monitors deployments" "REST API / Web UI"

        # Container relationships
        uiFrontend -> uiBff "Serves SPA and forwards API calls"
        uiBff -> proxy "Forwards Model Registry API calls" "HTTP/8080"
        uiBff -> catalogServer "Forwards Catalog API calls" "HTTP/8080"
        proxy -> embedMD "Stores and retrieves metadata" "Go function calls"
        embedMD -> postgresql "SQL queries via GORM" "TCP/5432 Configurable TLS"
        embedMD -> mysql "SQL queries via GORM" "TCP/3306 Configurable TLS"
        catalogServer -> postgresql "Catalog metadata and leader election" "TCP/5432"
        catalogServer -> huggingface "Fetches model metadata" "HTTPS/443"
        controller -> proxy "Syncs InferenceService metadata" "HTTP/8080 mTLS Bearer Token"
        controller -> kubeAPI "Watches InferenceService CRs" "HTTPS/443 ServiceAccount"
        csi -> proxy "Resolves model-registry:// URIs" "HTTP/8080"
        csi -> s3 "Downloads model artifacts" "HTTPS/443"
        asyncUpload -> proxy "Registers/updates model artifacts" "HTTPS/443 Bearer Token"
        asyncUpload -> s3 "Downloads/uploads models" "HTTPS/443 AWS IAM"
        asyncUpload -> ociRegistry "Pushes/pulls model images" "HTTPS/443 Docker auth"
        asyncUpload -> huggingface "Downloads models" "HTTPS/443 API key"
        asyncUpload -> sigstore "Signs model artifacts" "HTTPS/443 OIDC"

        # External system relationships
        kserve -> controller "InferenceService CR events" "Kubernetes Watch"
        dashboard -> proxy "Queries model registry" "HTTP/8080 Istio mTLS"
        istio -> proxy "Transport encryption and access control" "mTLS + AuthorizationPolicy"
        istio -> catalogServer "Transport encryption" "mTLS"
    }

    views {
        systemContext modelRegistry "SystemContext" {
            include *
            autoLayout
            description "System context diagram showing Model Registry in the RHOAI ecosystem"
        }

        container modelRegistry "Containers" {
            include *
            autoLayout
            description "Container diagram showing Model Registry internal architecture"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "External Database" {
                background #336791
                color #ffffff
            }
            element "External Service" {
                background #999999
                color #ffffff
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
