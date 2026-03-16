workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML model metadata and artifacts"
        admin = person "Platform Admin" "Deploys and configures Model Registry instances"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator that manages Model Registry service instances" {
            controllerManager = container "Controller Manager" "Reconciles ModelRegistry CRs and manages lifecycle" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and defaults ModelRegistry resources" "Go Service (9443/TCP HTTPS)"
        }

        modelRegistryService = softwareSystem "Model Registry Service" "ML model metadata store with REST and gRPC APIs (managed by operator)" {
            restContainer = container "REST Container" "HTTP REST API for model registry operations" "Go Service (8080/TCP)"
            grpcContainer = container "gRPC Container" "ML Metadata gRPC service" "Go Service (9090/TCP)"
        }

        # External Dependencies
        k8s = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS and traffic management" "External"
        authorino = softwareSystem "Authorino" "External authorization service for Kubernetes token validation" "External"
        postgresql = softwareSystem "PostgreSQL Database" "Primary metadata storage backend" "External"
        mysql = softwareSystem "MySQL Database" "Alternative metadata storage backend" "External"

        # Internal ODH/RHOAI Dependencies
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Platform operator that installs components" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for platform management" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics and monitoring" "Internal ODH"

        # Relationships
        user -> modelRegistryService "Stores/retrieves model metadata via REST API" "HTTPS/8080"
        user -> modelRegistryService "Stores/retrieves model metadata via gRPC API" "gRPC/9090"
        admin -> modelRegistryOperator "Creates ModelRegistry CRs" "kubectl/HTTPS"

        controllerManager -> k8s "Watches ModelRegistry CRs, manages resources" "HTTPS/443"
        controllerManager -> modelRegistryService "Creates and manages deployments" "HTTPS/443"

        modelRegistryService -> postgresql "Stores ML metadata" "PostgreSQL/5432 (TLS optional)"
        modelRegistryService -> mysql "Alternative metadata storage" "MySQL/3306 (TLS optional)"
        modelRegistryService -> istio "Routes traffic, enforces mTLS" "mTLS"
        modelRegistryService -> authorino "Authenticates/authorizes requests" "gRPC ext-authz/50051"

        restContainer -> grpcContainer "Proxies REST to gRPC" "gRPC/9090 localhost"
        grpcContainer -> postgresql "SQL queries for MLMD storage" "PostgreSQL/5432"
        grpcContainer -> mysql "SQL queries for MLMD storage" "MySQL/3306"

        authorino -> k8s "TokenReview, SubjectAccessReview" "HTTPS/443"
        k8s -> webhookServer "Admission webhooks" "HTTPS/9443 mTLS"

        odhOperator -> modelRegistryOperator "Installs and configures operator" "HTTPS/443"
        dashboard -> modelRegistryService "Reads external endpoint annotations" "Annotations"
        prometheus -> controllerManager "Scrapes operator metrics" "HTTPS/8443 mTLS"

        istio -> modelRegistryService "Routes external traffic via Gateway" "HTTPS/443"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOperator "OperatorContainers" {
            include *
            autoLayout
        }

        container modelRegistryService "ModelRegistryContainers" {
            include *
            autoLayout
        }

        systemContext modelRegistryService "ModelRegistryContext" {
            include *
            autoLayout
        }

        dynamic modelRegistryService "ExternalClientFlow" "External client accessing Model Registry with Istio" {
            user -> modelRegistryService "1. POST /api/model_registry/v1alpha3/registered_models (Bearer token)"
            modelRegistryService -> istio "2. Traffic routed via Gateway"
            istio -> authorino "3. ext-authz: validate token"
            authorino -> k8s "4. TokenReview + SubjectAccessReview"
            k8s -> authorino "5. Authorization decision"
            authorino -> istio "6. Approved"
            istio -> modelRegistryService "7. Forward request (mTLS)"
            modelRegistryService -> postgresql "8. Store model metadata"
            postgresql -> modelRegistryService "9. Metadata stored"
            modelRegistryService -> user "10. 200 OK"
            autoLayout
        }

        dynamic modelRegistryOperator "ReconciliationFlow" "Operator reconciling ModelRegistry CR" {
            admin -> k8s "1. Create ModelRegistry CR"
            k8s -> controllerManager "2. Watch event: ModelRegistry created"
            controllerManager -> k8s "3. Create Deployment"
            controllerManager -> k8s "4. Create Service (8080, 9090)"
            controllerManager -> k8s "5. Create ServiceAccount + RBAC"
            controllerManager -> k8s "6. Create Istio Gateway/VirtualService"
            controllerManager -> k8s "7. Create Authorino AuthConfig"
            k8s -> modelRegistryService "8. Model Registry pods start"
            modelRegistryService -> postgresql "9. Connect to database"
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
