workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, registers, and deploys ML models"
        mlEngineer = person "ML Engineer" "Manages model lifecycle and serving infrastructure"

        modelRegistry = softwareSystem "Model Registry" "Central REST API service for recording and retrieving ML model metadata, versions, artifacts, experiments, and inference services" {
            proxy = container "model-registry (proxy)" "Core REST API server for ML model metadata management" "Go REST Service" "Port: 8080/TCP"
            catalog = container "model-catalog" "Curated model catalog with Hugging Face integration and MCP server" "Go REST Service" "Port: 8080/TCP"
            ui = container "model-registry-ui" "Web interface for model discovery and management" "TypeScript/React + Go BFF" "Port: 8080/TCP"
            controller = container "inferenceservice-controller" "Syncs KServe InferenceService CRs with Model Registry API" "Go Controller (controller-runtime)" "Port: 8081/TCP"
            csi = container "mr-storage-initializer" "Resolves model-registry:// URIs to actual storage URIs for KServe" "Go CLI Tool" "Init Container"
            asyncUpload = container "async-upload Job" "Transfers model artifacts between storage backends and registers in Model Registry" "Python Kubernetes Job" "On-demand"
        }

        mysql = softwareSystem "MySQL 8.3" "Primary metadata storage backend" "Database"
        postgresql = softwareSystem "PostgreSQL 16+" "Alternative metadata storage backend" "Database"
        kserve = softwareSystem "KServe" "Kubernetes-native ML model serving with InferenceService CRDs" "Internal ODH"
        istio = softwareSystem "Istio Service Mesh" "Traffic management, mTLS enforcement, and authorization" "Internal ODH"
        k8sApi = softwareSystem "Kubernetes API" "Cluster resource management and watch streams" "Infrastructure"
        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage" "External"
        ociRegistry = softwareSystem "OCI Registries" "Model container image storage" "External"
        sigstore = softwareSystem "Sigstore" "Model signing and verification (Fulcio, Rekor, TSA)" "External"
        hfHub = softwareSystem "Hugging Face Hub" "Model metadata and gating validation" "External"
        rhoaiOperator = softwareSystem "RHOAI Platform Operator" "Deploys and manages Model Registry via kustomize manifests" "Internal ODH"

        # Person interactions
        dataScientist -> modelRegistry "Registers models, creates experiments, browses catalog"
        mlEngineer -> modelRegistry "Manages model versions, serving environments, and deployments"

        # Internal container interactions
        ui -> proxy "REST API calls" "HTTP/8080 Istio mTLS"
        controller -> proxy "CRUD InferenceService and ServingEnvironment" "HTTP/8080 Bearer Token"
        csi -> proxy "Resolve model-registry:// URIs" "HTTP/8080"
        asyncUpload -> proxy "Register/update model artifacts" "HTTP/8080 Bearer Token"

        # Database connections
        proxy -> mysql "Metadata persistence (EmbedMD schema)" "MySQL/3306 Optional TLS 1.2+"
        proxy -> postgresql "Metadata persistence (EmbedMD schema)" "PostgreSQL/5432 Optional TLS 1.2+"
        catalog -> postgresql "Catalog data storage" "PostgreSQL/5432"

        # External dependencies
        catalog -> hfHub "Fetch model metadata, validate gating" "HTTPS/443"
        controller -> k8sApi "Watch InferenceService CRs, patch labels" "HTTPS/443 SA Token"
        controller -> kserve "Monitors InferenceService CRs for state sync" "K8s Watch API"
        csi -> s3 "Download model artifacts" "HTTPS/443 Storage credentials"
        asyncUpload -> s3 "Read/write model artifacts" "HTTPS/443 AWS IAM"
        asyncUpload -> ociRegistry "Push/pull model container images" "HTTPS/443 Registry credentials"
        asyncUpload -> sigstore "Sign and verify models" "HTTPS/443 K8s SA OIDC"
        istio -> proxy "mTLS traffic routing via VirtualService" "HTTP/8080 ISTIO_MUTUAL"
        rhoaiOperator -> modelRegistry "Deploys via kustomize manifests" "K8s API"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Database" {
                background #f5a623
                shape Cylinder
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
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
