workspace {
    model {
        user = person "Data Scientist" "Creates, versions, and manages ML models"
        platformOp = person "Platform Operator" "Manages RHOAI platform and model serving"

        modelRegistry = softwareSystem "Model Registry" "Central metadata service for ML model artifacts, versions, and serving state" {
            proxy = container "Model Registry Proxy" "HTTP proxy exposing OpenAPI-defined model metadata API" "Go / OpenAPI" "Port 8080"
            bff = container "BFF (Backend for Frontend)" "Mediates between UI and registry API + Kubernetes API with pluggable auth" "Go / chi" "Port 4000/8080"
            controller = container "InferenceService Controller" "Reconciles KServe InferenceService CRs with registry metadata (conditional)" "Go / controller-runtime"
            asyncUpload = container "Async Upload Job" "Handles artifact upload to S3-compatible storage" "Python"
            database = container "Database" "Stores model metadata, versions, artifacts" "PostgreSQL / MySQL" "Database"
        }

        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic routing, and authorization policies" "External"
        kserve = softwareSystem "KServe" "Model serving platform providing InferenceService CRD" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes" "Container orchestration and API server" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Model artifact object storage" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "RHOAI web console" "Internal RHOAI"

        # User interactions
        user -> modelRegistry "Registers models, queries metadata via UI"
        platformOp -> modelRegistry "Manages model registry configuration"

        # Container-level interactions
        user -> bff "HTTPS via Istio Gateway" "HTTPS/443"
        bff -> proxy "REST API calls" "HTTP/8080"
        bff -> k8s "RBAC checks, ConfigMap/Secret CRUD" "HTTPS/6443"
        proxy -> database "Queries and stores metadata" "TCP"
        controller -> k8s "Watches InferenceService CRs, lists Services" "HTTPS/6443"
        controller -> proxy "Updates inference service URLs" "HTTP"
        asyncUpload -> s3 "Uploads model artifacts" "HTTPS/443"

        # External system interactions
        modelRegistry -> istio "Protected by AuthorizationPolicies and mTLS"
        modelRegistry -> kserve "Watches InferenceService CRs" "HTTPS"
        modelRegistry -> k8s "ServiceAccount authentication, RBAC" "HTTPS/6443"
        modelRegistry -> s3 "Stores model artifacts" "HTTPS/443"
        odhDashboard -> modelRegistry "Links to model registry UI" "HTTPS"
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
            element "Database" {
                shape Cylinder
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
