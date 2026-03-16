workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages model registries for ML metadata tracking"
        admin = person "Platform Administrator" "Deploys and configures Model Registry Operator"

        modelRegistryOp = softwareSystem "Model Registry Operator" "Kubernetes operator that deploys and manages Model Registry service instances" {
            controller = container "Controller Manager" "Reconciles ModelRegistry CRs and manages lifecycle" "Go Operator" {
                reconciler = component "ModelRegistry Reconciler" "Watches and reconciles ModelRegistry CRs" "controller-runtime"
                resourceManager = component "Resource Manager" "Creates/updates Deployments, Services, Routes" "Go"
            }
            webhook = container "Webhook Server" "Validates and mutates ModelRegistry CRs" "Go Admission Webhook"
            metrics = container "Metrics Service" "Prometheus metrics endpoint" "Go HTTP Server"
        }

        modelRegistry = softwareSystem "Model Registry Service" "Deployed instance for ML model metadata tracking" {
            restAPI = container "REST API" "HTTP/HTTPS REST API for model metadata" "Python/FastAPI"
            grpcAPI = container "gRPC API" "gRPC API for ML metadata service" "Python/gRPC"
        }

        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS and traffic management" "External Platform"
        authorino = softwareSystem "Authorino" "External authorization service for API authentication" "External Platform"
        certManager = softwareSystem "cert-manager" "Certificate management and rotation" "External Platform"
        postgres = softwareSystem "PostgreSQL/MySQL" "Backend database for ML metadata storage" "External"
        k8s = softwareSystem "Kubernetes API Server" "Cluster orchestration and API" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"
        odhDashboard = softwareSystem "ODH Dashboard" "OpenShift AI web console" "Internal ODH"

        %% User interactions
        user -> modelRegistry "Stores/retrieves model metadata via REST/gRPC"
        admin -> modelRegistryOp "Creates ModelRegistry CR via kubectl"
        user -> odhDashboard "Manages model registries via UI (potential)"

        %% Operator interactions
        modelRegistryOp -> k8s "Watches/manages ModelRegistry CRs and resources" "HTTPS/6443"
        modelRegistryOp -> modelRegistry "Deploys and configures" "Creates Deployments/Services"
        modelRegistryOp -> istio "Creates Gateways, VirtualServices, DestinationRules" "Istio CRs"
        modelRegistryOp -> authorino "Creates AuthConfig resources" "Authorino CRs"

        %% Model Registry interactions
        modelRegistry -> postgres "Persists model metadata" "PostgreSQL/MySQL 5432/3306"
        modelRegistry -> istio "Uses for mTLS and gateway routing" "Service Mesh"
        modelRegistry -> authorino "Validates JWT and checks RBAC" "gRPC/50051"
        modelRegistry -> k8s "Auth via SubjectAccessReview API" "HTTPS/6443"

        %% Monitoring
        prometheus -> modelRegistryOp "Scrapes metrics" "HTTPS/8443"

        %% Optional integrations
        odhDashboard -> modelRegistry "Integrates with model registry UI (potential)" "REST API"
        certManager -> modelRegistry "Provisions TLS certificates for gateways" "Certificate issuance"
    }

    views {
        systemContext modelRegistryOp "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOp "OperatorContainers" {
            include *
            autoLayout
        }

        systemContext modelRegistry "ModelRegistryContext" {
            include *
            autoLayout
        }

        container modelRegistry "ModelRegistryContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Platform" {
                background #cccccc
            }
            element "Internal ODH" {
                background #7ed321
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
