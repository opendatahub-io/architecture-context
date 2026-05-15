workspace {
    model {
        // Actors
        dataScientist = person "Data Scientist" "Registers models, creates versions, deploys inference services"
        mlEngineer = person "ML Engineer" "Manages model lifecycle, uploads models, monitors serving"
        securityTeam = person "Security Team" "Reviews access policies, audits model provenance"

        // Model Registry System
        modelRegistry = softwareSystem "Model Registry" "Central metadata repository for registering, versioning, and serving ML models with catalog discovery" {
            proxy = container "Model Registry Proxy" "Core REST API server for ML model metadata (registered models, versions, artifacts, inference services, experiments)" "Go REST Service" "Primary"
            catalog = container "Model Catalog" "Aggregates and indexes models from external catalog sources (HuggingFace, MCP servers) with leader election" "Go REST Service"
            controller = container "MR Controller" "Watches KServe InferenceService CRDs and synchronizes state with Model Registry" "Go Controller (controller-runtime)"
            csi = container "CSI Storage Initializer" "Downloads model artifacts via model-registry:// URIs as KServe init container" "Go CLI (KServe Provider)"
            ui = container "Model Registry UI" "Web frontend with Go BFF for browsing and managing models" "TypeScript + Go BFF"
            asyncJob = container "Async Upload Job" "Kubernetes Job for async model transfer between storage backends with Sigstore signing" "Python 3.12 Job"
        }

        // Internal Platform Dependencies
        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService CRDs" "Internal ODH"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS, traffic routing, and authorization policies" "Internal Platform"
        dashboard = softwareSystem "ODH Dashboard" "Platform dashboard UI that discovers and links to Model Registry" "Internal ODH"
        rhoaiOperator = softwareSystem "RHOAI Platform Operator" "Deploys and configures Model Registry instances" "Internal Platform"

        // External Dependencies
        mysql = softwareSystem "MySQL 8.3+" "Primary metadata storage backend for proxy" "External Datastore"
        postgresql = softwareSystem "PostgreSQL 16+" "Catalog metadata storage and leader election backend" "External Datastore"
        s3 = softwareSystem "S3 Object Stores" "Model artifact source and destination storage" "External Service"
        ociRegistry = softwareSystem "OCI Registries" "Container registries for model images via Skopeo" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "External model catalog source for discovery and download" "External Service"
        sigstore = softwareSystem "Sigstore (Fulcio, Rekor, TUF)" "Digital signing and verification of model artifacts" "External Service"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for service discovery, CRD watching, and RBAC" "External Platform"

        // Relationships - Users
        dataScientist -> modelRegistry "Registers models, browses catalog, creates inference services via REST API and UI"
        mlEngineer -> modelRegistry "Uploads models, manages versions, monitors deployments"
        securityTeam -> modelRegistry "Reviews model provenance, audits access policies"

        // Relationships - Internal containers
        proxy -> mysql "Reads/writes model metadata" "TCP/3306 Optional TLS"
        proxy -> postgresql "Alternative metadata storage" "TCP/5432 Optional TLS"
        catalog -> postgresql "Catalog metadata + leader election" "TCP/5432 Optional TLS"
        catalog -> huggingface "Imports models from catalog sources" "HTTPS/443"
        controller -> proxy "Registers/updates inference services via REST API" "HTTP/8080 mTLS + Bearer Token"
        controller -> kubernetesAPI "Watches InferenceService CRDs" "HTTPS/443 SA Token"
        csi -> proxy "Fetches model artifact storage URIs" "HTTP/8080"
        csi -> s3 "Downloads model artifacts" "HTTPS/443"
        ui -> proxy "Browses and manages models via REST API" "HTTP/8080 mTLS"
        ui -> kubernetesAPI "Creates SubjectAccessReviews, lists services" "HTTPS/443 SA Token"
        asyncJob -> proxy "Updates model artifact metadata after transfer" "HTTP/8080"
        asyncJob -> s3 "Downloads/uploads model artifacts" "HTTPS/443 AWS IAM"
        asyncJob -> ociRegistry "Pushes/pulls model images via Skopeo" "HTTPS/443 Docker Auth"
        asyncJob -> huggingface "Downloads models from HuggingFace" "HTTPS/443 API Key"
        asyncJob -> sigstore "Signs model artifacts with OIDC" "HTTPS/443 OIDC"

        // Relationships - Platform integrations
        istio -> modelRegistry "Provides mTLS encryption, VirtualService routing, AuthorizationPolicy enforcement"
        kserve -> modelRegistry "InferenceService CRDs watched by controller; CSI provides storage provider"
        dashboard -> modelRegistry "Discovers and links to Model Registry UI" "HTTP/8080"
        rhoaiOperator -> modelRegistry "Deploys and configures Model Registry instances"
    }

    views {
        systemContext modelRegistry "SystemContext" {
            include *
            autoLayout
            description "Model Registry in the context of the RHOAI platform and external services"
        }

        container modelRegistry "Containers" {
            include *
            autoLayout
            description "Internal components of the Model Registry system"
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Primary" {
                background #1168BD
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #85BBF0
                color #000000
            }
            element "External Datastore" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
            element "External Service" {
                background #999999
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
        }
    }
}
