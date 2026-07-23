workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, versions, and manages ML models"
        mlEngineer = person "ML Engineer" "Deploys models and manages serving infrastructure"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and Model Registry instances"

        modelRegistry = softwareSystem "Model Registry" "Central metadata repository for ML models, versions, artifacts, and serving configurations" {
            proxy = container "model-registry proxy" "REST API server with OpenAPI v1alpha3 endpoints for model metadata CRUD" "Go REST Service" "Port: 8080/TCP"
            controller = container "InferenceService Controller" "Watches KServe InferenceService CRs and synchronizes deployment metadata into the registry" "Go Controller (controller-runtime)"
            csi = container "mr-storage-initializer (CSI)" "Resolves model-registry:// URIs to model artifact storage locations for KServe" "Go CLI / Init Container"
            asyncUpload = container "async-upload Job" "Copies models between S3/OCI storage backends and registers them with optional Sigstore signing" "Python Job"
        }

        mysql = softwareSystem "MySQL 8.3+" "Primary metadata storage backend" "Database"
        postgresql = softwareSystem "PostgreSQL 16+" "Alternative metadata storage backend" "Database"
        kserve = softwareSystem "KServe" "Kubernetes-native model serving with InferenceService CRDs" "Internal Platform"
        istio = softwareSystem "Istio" "Service mesh providing mTLS, traffic management, and AuthorizationPolicy" "Internal Platform"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        s3 = softwareSystem "S3-compatible Storage" "Model artifact storage (AWS S3, MinIO, etc.)" "External Service"
        oci = softwareSystem "OCI Container Registry" "Container and model image registry" "External Service"
        huggingface = softwareSystem "HuggingFace Hub" "Public model repository" "External Service"
        sigstore = softwareSystem "Sigstore" "Model and image signing infrastructure (Fulcio, Rekor)" "External Service"
        modelRegistryUI = softwareSystem "Model Registry UI (BFF)" "Dashboard UI for managing models" "Internal Platform"
        rhoaiOperator = softwareSystem "RHOAI Platform Operator" "Deploys and manages Model Registry instances" "Internal Platform"

        # Person interactions
        dataScientist -> modelRegistry "Registers models, creates versions, uploads artifacts"
        mlEngineer -> modelRegistry "Queries model metadata, deploys models for serving"
        platformAdmin -> rhoaiOperator "Configures Model Registry instances per namespace"

        # Internal container interactions
        proxy -> mysql "Stores/retrieves model metadata" "MySQL/3306"
        proxy -> postgresql "Stores/retrieves model metadata (alternative)" "PostgreSQL/5432"
        controller -> proxy "Syncs InferenceService deployment metadata" "HTTP/8080 mTLS"
        controller -> k8sApi "Watches InferenceService CRs, updates labels" "HTTPS/443"
        csi -> proxy "Resolves model-registry:// URIs" "HTTP/8080 mTLS"
        csi -> s3 "Downloads model artifacts" "HTTPS/443"
        asyncUpload -> s3 "Downloads/uploads model files" "HTTPS/443"
        asyncUpload -> oci "Pushes/pulls model images" "HTTPS/443"
        asyncUpload -> huggingface "Downloads models" "HTTPS/443"
        asyncUpload -> sigstore "Signs models and images" "HTTPS/443"
        asyncUpload -> proxy "Registers model metadata" "HTTPS/443"

        # External system interactions
        modelRegistryUI -> proxy "CRUD operations on models" "REST API/8080"
        rhoaiOperator -> modelRegistry "Deploys instances via kustomize manifests"
        kserve -> controller "InferenceService CR lifecycle events"
        kserve -> csi "Triggers storage initialization for model-registry:// URIs"
        istio -> proxy "mTLS enforcement and AuthorizationPolicy" "ISTIO_MUTUAL"
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
            element "Database" {
                shape Cylinder
                background #e8e8e8
            }
            element "External Service" {
                background #f5a623
            }
            element "Internal Platform" {
                background #7ed321
            }
            element "Infrastructure" {
                background #999999
            }
            element "Person" {
                shape Person
                background #4a90e2
            }
        }
    }
}
