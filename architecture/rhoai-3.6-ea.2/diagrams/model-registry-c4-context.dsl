workspace {
    model {
        dataScientist = person "Data Scientist" "Registers, versions, and queries ML model metadata"
        platformAdmin = person "Platform Admin" "Manages model registry instances and configuration"

        modelRegistry = softwareSystem "Model Registry (Kubeflow Hub)" "Central repository for ML model metadata, federated catalog discovery, and Kubernetes-native model serving integration" {
            server = container "model-registry" "Core REST API proxy for model metadata CRUD" "Go Service, chi router, GORM" "8080/TCP"
            controller = container "InferenceService Controller" "Watches KServe InferenceService CRDs and synchronizes serving state with registry" "Go, controller-runtime" "8081/TCP, 8443/TCP"
            bff = container "BFF Proxy" "Backend-for-Frontend for React UI with Kubernetes authorization" "Go Service" "4000/TCP"
            catalog = container "Catalog Service" "Federated model catalog with plugin-based discovery including MCP servers" "Go Service"
            asyncUpload = container "async-upload Job" "Batch job for model transfer between storage backends with sigstore signing" "Python, sigstore" "Batch Job"
            csi = container "mr-storage-initializer" "KServe-compatible CSI init container for downloading model artifacts" "Go CLI" "Init Container"
        }

        istio = softwareSystem "Istio Service Mesh" "Traffic routing, mTLS, and AuthorizationPolicy enforcement" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService CRDs" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management and authorization" "External"
        postgresql = softwareSystem "PostgreSQL / MySQL" "Relational database for model metadata persistence" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for model artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Public model repository" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for model images" "External"
        sigstore = softwareSystem "Sigstore / RHTAS" "Supply chain transparency and signing" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI platform dashboard UI" "Internal RHOAI"
        modelRegistryOperator = softwareSystem "model-registry-operator" "Manages ModelRegistry CR instances" "Internal RHOAI"

        # Person interactions
        dataScientist -> modelRegistry "Registers and queries models via REST API and UI"
        platformAdmin -> modelRegistryOperator "Manages registry instances via CRDs"

        # Container-level interactions
        dataScientist -> bff "Accesses UI" "HTTPS/443 via Istio"
        dataScientist -> server "REST API calls" "HTTPS/443 via Istio"
        odhDashboard -> bff "Proxies UI requests" "HTTP/4000"

        bff -> server "Proxies API requests" "HTTP/8080"
        bff -> k8sAPI "SubjectAccessReview, Job creation" "HTTPS/6443"
        bff -> asyncUpload "Creates batch Jobs" "Kubernetes API"

        controller -> server "Reads model metadata" "HTTP/8080"
        controller -> k8sAPI "Watches InferenceService, leader election" "HTTPS/6443"

        server -> postgresql "Persists model metadata" "TCP/5432 or 3306, GORM"

        asyncUpload -> server "Registers uploaded models" "HTTP/8080"
        asyncUpload -> s3 "Downloads/uploads model artifacts" "HTTPS/443, AWS IAM"
        asyncUpload -> huggingface "Downloads models" "HTTPS/443"
        asyncUpload -> ociRegistry "Push/pull model artifacts via ORAS" "HTTPS/443"
        asyncUpload -> sigstore "Signs model artifacts" "HTTPS/443"

        csi -> server "Downloads model artifacts for serving" "HTTP/8080"

        modelRegistry -> istio "Traffic routing and access control" "mTLS, AuthorizationPolicy"
        modelRegistry -> kserve "Watches InferenceService CRDs" "HTTPS/6443"
        modelRegistryOperator -> modelRegistry "Manages lifecycle" "CRD"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
