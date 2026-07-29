workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML models, versions, and artifacts"

        modelRegistry = softwareSystem "Model Registry" "Central repository for model metadata with BFF-backed web UI, catalog plugin server, and KServe InferenceService reconciliation" {
            bff = container "BFF Server" "Backend-for-Frontend serving React SPA and REST API at /api/v1/ with Kubernetes SAR-based authorization" "Go 1.26 / distroless"
            reactUI = container "React SPA" "Web interface for model registry management, catalog browsing, agent catalog, and settings" "React / Node.js"
            registryProxy = container "model-registry" "Core registry API proxy server with FIPS-enabled Go runtime" "Go 1.26 / UBI9-minimal / FIPS"
            catalogServer = container "model-catalog-server" "Plugin-based catalog server with dynamic route registration and lifecycle management" "Go / Deployment"
            catalogDB = container "model-catalog-postgres" "Persistent storage for model catalog data" "PostgreSQL 17.6 / StatefulSet"
            manager = container "Manager Controller" "Watches KServe InferenceService resources and reconciles model serving state" "Go / controller-runtime 0.24.1"
            pythonClient = container "Python Client" "Programmatic model registry and S3/OCI artifact operations" "Python / model-registry 0.3.9"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource operations and authorization" "Platform"
        kserve = softwareSystem "KServe" "Model serving platform providing InferenceService custom resources" "Internal RHOAI"
        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3 or compatible)" "External"
        oci = softwareSystem "OCI Registry" "Container and model artifact registry" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Public model catalog and repository" "External"

        # User interactions
        user -> bff "Manages models via REST API /api/v1/" "HTTP/8080"
        user -> reactUI "Browses models and catalogs" "HTTPS"
        user -> pythonClient "Programmatic model operations" "Python SDK"

        # Internal interactions
        bff -> reactUI "Serves" "HTTP"
        bff -> registryProxy "Proxies registry requests" "HTTP/8080"
        bff -> catalogServer "Proxies catalog requests" "HTTP/8080"
        bff -> k8sAPI "SAR/SSAR authorization checks" "HTTPS/6443"
        catalogServer -> catalogDB "Stores catalog data" "PostgreSQL/5432"
        manager -> k8sAPI "Watches InferenceService, reconciles resources" "HTTPS/6443"

        # External interactions
        registryProxy -> s3 "Uploads/downloads model artifacts" "HTTPS/443"
        registryProxy -> oci "Pushes/pulls model artifacts" "HTTPS/443"
        catalogServer -> huggingface "Fetches model catalog data" "HTTPS/443"
        pythonClient -> registryProxy "Model CRUD operations" "HTTP/8080"
        pythonClient -> s3 "Direct artifact upload" "HTTPS/443"
        pythonClient -> oci "Direct artifact push/pull" "HTTPS/443"

        # Platform interactions
        k8sAPI -> kserve "Manages InferenceService CRs" "Kubernetes API"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Platform" {
                background #999999
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
        }
    }
}
