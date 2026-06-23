workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, registers, and deploys ML models via UI or API"
        mlopsEngineer = person "MLOps Engineer" "Manages model lifecycle, serving environments, and catalog configuration"

        modelRegistry = softwareSystem "Model Registry" "Central metadata repository for ML models, versions, artifacts, and serving environments with REST API, web UI, model catalog, and KServe integration" {
            restProxy = container "REST Proxy" "OpenAPI v1alpha3 REST API for model metadata CRUD operations" "Go Service, 8080/TCP" {
                tags "Core"
            }
            uiBFF = container "UI BFF" "Backend-for-Frontend aggregation layer proxying to Registry and Catalog APIs" "Go Service, 8080/TCP" {
                tags "Core"
            }
            uiFrontend = container "React Frontend" "Web interface for model browsing, registration, and management" "React/TypeScript SPA" {
                tags "Core"
            }
            catalogServer = container "Model Catalog" "Plugin-based catalog server for model and MCP server discovery" "Go Service, 8080/TCP" {
                tags "Optional"
            }
            controller = container "Controller" "Watches KServe InferenceService CRs and synchronizes with Model Registry" "Go Operator (controller-runtime)" {
                tags "Optional"
            }
            csiInitializer = container "Storage Initializer (CSI)" "Downloads model artifacts from registry using model-registry:// URI scheme" "Go CLI Tool (init container)" {
                tags "Optional"
            }
            asyncUploadJob = container "Async Upload Job" "Transfers models between storage backends with optional Sigstore signing" "Python 3.12 K8s Job" {
                tags "Optional"
            }
        }

        # External Systems
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" {
            tags "Internal ODH"
        }
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management, RBAC, and service discovery" {
            tags "Infrastructure"
        }
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, and authorization policies" {
            tags "Infrastructure"
        }
        mysql = softwareSystem "MySQL 8.3+" "Relational database for model registry metadata storage" {
            tags "Data Store"
        }
        postgresql = softwareSystem "PostgreSQL 16+" "Alternative relational database for registry and catalog metadata" {
            tags "Data Store"
        }
        s3 = softwareSystem "AWS S3" "Object storage for model artifacts" {
            tags "External"
        }
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for model images" {
            tags "External"
        }
        huggingFace = softwareSystem "Hugging Face" "Model hub for catalog data source" {
            tags "External"
        }
        sigstore = softwareSystem "Sigstore" "Supply chain security (Fulcio/Rekor/TUF) for model signing" {
            tags "External"
        }

        # User interactions
        dataScientist -> modelRegistry "Browses, registers, and manages models" "HTTPS/443"
        mlopsEngineer -> modelRegistry "Configures serving environments and catalog sources" "HTTPS/443"

        # System context relationships
        modelRegistry -> mysql "Stores model metadata" "TCP/3306"
        modelRegistry -> postgresql "Stores model and catalog metadata" "TCP/5432"
        modelRegistry -> kserve "Syncs InferenceService state" "HTTPS/443"
        modelRegistry -> kubernetesAPI "Service discovery, RBAC, job management" "HTTPS/443"
        modelRegistry -> istio "Traffic routing, mTLS, authorization" "HTTP/80"
        modelRegistry -> s3 "Upload/download model artifacts" "HTTPS/443"
        modelRegistry -> ociRegistry "Push/pull model images" "HTTPS/443"
        modelRegistry -> huggingFace "Fetches model catalog metadata" "HTTPS/443"
        modelRegistry -> sigstore "Signs models and images" "HTTPS/443"
        kserve -> modelRegistry "Triggers CSI model download via model-registry:// URIs"

        # Container-level relationships
        uiFrontend -> uiBFF "API calls" "HTTP(S)/8080"
        uiBFF -> restProxy "Proxies model registry operations" "HTTP/8080 ISTIO_MUTUAL"
        uiBFF -> catalogServer "Proxies catalog queries" "HTTP/8080 ISTIO_MUTUAL"
        uiBFF -> kubernetesAPI "SAR checks, namespace listing, job management" "HTTPS/443"
        restProxy -> mysql "GORM queries" "TCP/3306"
        restProxy -> postgresql "GORM queries" "TCP/5432"
        catalogServer -> postgresql "GORM + pglock queries" "TCP/5432"
        catalogServer -> huggingFace "Fetches model metadata" "HTTPS/443"
        controller -> kubernetesAPI "Watches InferenceService CRs" "HTTPS/443"
        controller -> restProxy "Creates/updates registry resources" "HTTP(S)/8080"
        csiInitializer -> restProxy "Resolves model URIs" "HTTP(S)/8080"
        csiInitializer -> s3 "Downloads model artifacts" "HTTPS/443"
        asyncUploadJob -> restProxy "Registers models/versions/artifacts" "HTTP(S)/443"
        asyncUploadJob -> s3 "Downloads/uploads model files" "HTTPS/443"
        asyncUploadJob -> ociRegistry "Pushes model images" "HTTPS/443"
        asyncUploadJob -> sigstore "Signs models" "HTTPS/443"
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
            element "Core" {
                background #4a90e2
            }
            element "Optional" {
                background #6c8ebf
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #e8e8e8
                color #333333
            }
            element "Data Store" {
                background #f5a623
                color #ffffff
                shape cylinder
            }
            element "External" {
                background #999999
                color #ffffff
            }
        }
    }
}
