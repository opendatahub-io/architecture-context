workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, registers, and deploys ML models"
        platformOperator = person "Platform Operator" "Deploys and configures Model Registry via RHOAI operator"

        modelRegistry = softwareSystem "Model Registry" "Central REST API service for recording and retrieving ML model lifecycle metadata" {
            proxy = container "model-registry (proxy)" "Core REST API server for ML model metadata management (v1alpha3, 50+ endpoints)" "Go REST Service" "Primary"
            catalog = container "model-catalog" "Curated model catalog with Hugging Face integration and MCP server discovery" "Go REST Service"
            controller = container "inferenceservice-controller" "Syncs KServe InferenceService CRs with Model Registry API tracking deployment state" "Go Controller (controller-runtime)"
            csi = container "mr-storage-initializer" "KServe storage initializer that resolves model-registry:// URIs to actual storage URIs" "Go CLI Tool"
            asyncJob = container "async-upload job" "Transfers model artifacts between storage backends (S3, OCI) and registers in Model Registry" "Python Kubernetes Job"
            ui = container "model-registry-ui" "Web interface for model discovery, management, and catalog browsing" "TypeScript/React + Go BFF"
            mysqlDB = container "MySQL Database" "Primary metadata storage (EmbedMD schema)" "MySQL 8.3" "Database"
            postgresDB = container "PostgreSQL Database" "Alternative metadata storage" "PostgreSQL 16+" "Database"
            catalogDB = container "Catalog PostgreSQL" "Catalog metadata storage" "PostgreSQL" "Database"
        }

        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform with InferenceService CRDs" "Internal ODH"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS, traffic routing, and authorization" "Internal ODH"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        rhoaiOperator = softwareSystem "RHOAI Platform Operator" "Manages deployment of RHOAI components via kustomize" "Internal ODH"

        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage and transfer" "External"
        ociRegistry = softwareSystem "OCI Registries" "Container image registries for model images" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Public model catalog and metadata source" "External"
        sigstore = softwareSystem "Sigstore (Fulcio, Rekor, TSA)" "Model signing and verification infrastructure" "External"

        # Person interactions
        dataScientist -> modelRegistry "Registers models, browses catalog, deploys inference services"
        platformOperator -> rhoaiOperator "Configures and deploys Model Registry"

        # Internal container interactions
        ui -> proxy "Queries model metadata" "REST/HTTP 8080"
        proxy -> mysqlDB "Reads/writes model metadata" "MySQL/3306"
        proxy -> postgresDB "Reads/writes model metadata" "PostgreSQL/5432"
        catalog -> catalogDB "Stores catalog metadata" "PostgreSQL/5432"
        controller -> proxy "Syncs InferenceService state" "HTTP/8080 Bearer Token"
        csi -> proxy "Resolves model-registry:// URIs" "HTTP/8080"
        asyncJob -> proxy "Updates artifact metadata" "HTTP/8080 Bearer Token"

        # External system interactions
        modelRegistry -> kserve "Controller watches InferenceService CRDs; CSI registered as ClusterStorageContainer" "K8s Watch API / TLS 1.2+"
        modelRegistry -> istio "Traffic routing via VirtualService, mTLS via DestinationRule, access control via AuthorizationPolicy" "mTLS ISTIO_MUTUAL"
        controller -> k8sAPI "Watches InferenceService CRs, patches labels/annotations" "HTTPS/443"
        catalog -> huggingFace "Fetches curated model metadata and gating validation" "HTTPS/443"
        asyncJob -> s3 "Reads/writes model artifacts" "HTTPS/443 AWS IAM"
        asyncJob -> ociRegistry "Pushes/pulls model container images" "HTTPS/443"
        asyncJob -> sigstore "Signs and verifies model artifacts" "HTTPS/443 OIDC"
        csi -> s3 "Downloads model artifacts via KServe storage providers" "HTTPS/443"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #666666
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
            element "Database" {
                shape cylinder
                background #f5a623
                color #000000
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
