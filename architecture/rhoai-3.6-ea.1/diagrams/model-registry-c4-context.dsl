workspace {
    model {
        user = person "Data Scientist" "Creates, versions, and manages ML model metadata and artifacts"

        modelRegistry = softwareSystem "Model Registry" "Central repository for ML model metadata, versions, and artifacts with REST API, controller operator, and UI" {
            hubProxy = container "Hub Proxy" "HTTP REST API for model metadata CRUD operations backed by relational database via GORM" "Go Binary" "FIPS"
            controller = container "Controller Operator" "Watches KServe InferenceService resources and synchronizes serving URLs back into the registry" "Go controller-runtime"
            bff = container "BFF (Backend-for-Frontend)" "Serves Model Registry UI and proxies authenticated API requests with Bearer/SA token auth" "Go Service"
            asyncUpload = container "Async Upload Job" "Background model artifact uploads to S3-compatible storage with sigstore signing" "Python Batch Job"
        }

        database = softwareSystem "PostgreSQL / MySQL" "Relational database for model metadata persistence" "External"
        kserve = softwareSystem "KServe" "ML model serving platform providing InferenceService CRDs" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh providing VirtualServices, AuthorizationPolicies, and mTLS" "Internal RHOAI"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource operations and RBAC" "External"

        # User interactions
        user -> modelRegistry "Manages model metadata and artifacts via UI and API"
        user -> bff "Accesses Model Registry UI" "HTTPS"

        # Internal component interactions
        hubProxy -> database "Persists model metadata" "TCP/TLS (GORM)"
        controller -> kserve "Watches InferenceService resources" "HTTPS (Kubernetes API)"
        controller -> hubProxy "Syncs serving URLs via OpenAPI client" "HTTP"
        controller -> kubernetesAPI "Leader election, RBAC, service discovery" "HTTPS/6443"
        bff -> hubProxy "Proxies API requests" "HTTP"
        bff -> kubernetesAPI "SubjectAccessReview, ConfigMap, Secret operations" "HTTPS/6443"
        asyncUpload -> s3 "Uploads model artifacts" "HTTPS/443 (AWS IAM)"
        asyncUpload -> hubProxy "Updates artifact metadata" "HTTP"

        # Istio ingress
        istio -> hubProxy "Routes /api/model_registry/* with AuthorizationPolicy" "mTLS"
        istio -> bff "Routes /model-registry/* with AuthorizationPolicy" "mTLS"
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
            element "FIPS" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
