workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, registers, and deploys ML models via UI or CLI"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration and operations"

        modelRegistry = softwareSystem "Model Registry" "Central metadata repository for ML model lifecycle management — registration, versioning, tracking, and serving" {
            proxyServer = container "Model Registry Server" "Core REST API server (OpenAPI v1alpha3) for CRUD operations on models, versions, artifacts, experiments" "Go, chi, GORM" "Service"
            catalogServer = container "Catalog Server" "Plugin-based catalog for model, agent, and MCP server discovery" "Go, chi" "Service"
            isvcController = container "InferenceService Controller" "Watches KServe InferenceService CRs and syncs metadata to registry" "Go, controller-runtime" "Controller"
            csiInitializer = container "CSI Storage Initializer" "KServe init container for downloading models via model-registry:// URIs" "Go" "CLI Tool"
            uiBFF = container "UI BFF" "Backend-for-Frontend serving React UI, proxying API calls with SubjectAccessReview authorization" "Go, chi" "Service"
            asyncUploadJob = container "Async Upload Job" "Batch job copying models between storage backends (S3, OCI, HuggingFace) with Sigstore signing" "Python" "K8s Job"
        }

        mysql = softwareSystem "MySQL" "Relational database (8.3+) for model metadata storage" "External Database"
        postgresql = softwareSystem "PostgreSQL" "Relational database (16+) for model metadata and catalog storage" "External Database"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal Platform"
        istio = softwareSystem "Istio Service Mesh" "Service mesh providing mTLS, AuthorizationPolicy, traffic routing" "Internal Platform"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Platform UI for ML workflow management" "Internal Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and access control" "Internal Platform"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts" "External Service"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for model OCI artifacts" "External Service"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Public model repository" "External Service"
        sigstore = softwareSystem "Sigstore" "Software supply chain signing service" "External Service"

        # User interactions
        dataScientist -> modelRegistry "Registers models, creates versions, deploys inference services" "REST API / UI"
        platformAdmin -> modelRegistry "Configures catalog sources, manages model governance" "REST API / kubectl"

        # Internal container relationships
        uiBFF -> proxyServer "Proxies model registry API calls" "HTTP/8080, Bearer token passthrough"
        uiBFF -> catalogServer "Proxies catalog API calls" "HTTP/8080, Bearer token passthrough"
        uiBFF -> k8sAPI "SubjectAccessReview, namespace listing" "HTTPS/443, SA/user token"
        isvcController -> proxyServer "Registers/updates model serving metadata" "HTTP/8080, Bearer token (K8s SA)"
        isvcController -> k8sAPI "Watches InferenceService CRs, patches labels" "HTTPS/443, SA token"
        csiInitializer -> proxyServer "Looks up model artifact URIs" "HTTP/8080"
        csiInitializer -> s3Storage "Downloads model artifacts" "HTTPS/443, Cloud credentials"
        asyncUploadJob -> proxyServer "Registers models, versions, artifacts" "REST/443, Bearer token"
        asyncUploadJob -> s3Storage "Downloads/uploads model files" "HTTPS/443, AWS credentials"
        asyncUploadJob -> ociRegistry "Pushes models as OCI artifacts" "HTTPS/443, Username/password"
        asyncUploadJob -> huggingFaceHub "Downloads models" "HTTPS/443, API key"
        asyncUploadJob -> sigstore "Signs model artifacts" "HTTPS/443, OIDC identity token"

        # Database connections
        proxyServer -> mysql "Stores/retrieves model metadata" "MySQL/3306, TLS 1.2+ optional"
        proxyServer -> postgresql "Stores/retrieves model metadata (alternative)" "PostgreSQL/5432, TLS 1.2+ optional"
        catalogServer -> postgresql "Stores catalog data" "PostgreSQL/5432"

        # Platform integrations
        rhoaiDashboard -> uiBFF "Accesses model registry and catalog via UI" "HTTP/8080, Istio mTLS"
        istio -> proxyServer "Enforces AuthorizationPolicy and mTLS" "mTLS ISTIO_MUTUAL"
        kserve -> isvcController "Creates InferenceService CRs triggering reconciliation" "K8s Watch API"
        kserve -> csiInitializer "Spawns as init container for model downloads" "Process spawn"
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
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External Database" {
                shape cylinder
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Service" {
                shape roundedBox
            }
            element "Controller" {
                shape hexagon
            }
            element "CLI Tool" {
                shape component
            }
            element "K8s Job" {
                shape component
            }
        }
    }
}
