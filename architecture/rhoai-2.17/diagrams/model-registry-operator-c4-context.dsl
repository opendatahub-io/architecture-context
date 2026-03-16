workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages ML model metadata and model registry instances"
        admin = person "Platform Administrator" "Deploys and configures Model Registry Operator"

        modelRegistryOp = softwareSystem "Model Registry Operator" "Kubernetes operator that manages Model Registry service instances for ML model metadata storage" {
            controller = container "Operator Controller" "Reconciles ModelRegistry CRs and manages lifecycle" "Go Operator" {
                manager = component "Manager" "Controller reconciliation logic" "Go"
                rbacProxy = component "Kube-RBAC Proxy" "Metrics endpoint security" "Go"
            }

            registryInstance = container "Model Registry Instance" "Per-CR deployment providing REST and gRPC APIs" "Containers" {
                restProxy = component "REST Proxy" "HTTP REST API on port 8080" "Go"
                grpcServer = component "gRPC Server" "ML Metadata gRPC API on port 9090" "Python/C++"
                istioSidecar = component "Envoy Sidecar" "mTLS and traffic management" "Istio"
            }
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Orchestration and RBAC enforcement" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for mTLS, traffic management, and ingress" "External"
        authorino = softwareSystem "Authorino" "Kubernetes-native authentication and authorization" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        database = softwareSystem "PostgreSQL / MySQL Database" "Backend storage for ML Metadata" "External"

        dashboardUser = softwareSystem "ODH Dashboard" "Web UI for managing model registries" "Internal ODH"
        pipelinesUser = softwareSystem "Data Science Pipelines" "ML pipeline orchestration and model tracking" "Internal ODH"
        kserveUser = softwareSystem "KServe" "Model serving platform consuming model metadata" "Internal ODH"

        # User interactions
        admin -> modelRegistryOp "Deploys operator and creates ModelRegistry CRs via kubectl"
        user -> modelRegistryOp "Accesses Model Registry APIs (REST/gRPC) for model metadata operations"

        # Operator interactions
        modelRegistryOp -> kubernetes "Reconciles CRs and manages Deployments, Services, RBAC via API" "HTTPS/6443"
        modelRegistryOp -> istio "Creates Gateways, VirtualServices, DestinationRules" "Kubernetes API"
        modelRegistryOp -> authorino "Creates AuthConfig resources for API authentication" "Kubernetes API"
        modelRegistryOp -> database "Stores and retrieves ML Metadata" "PostgreSQL/MySQL Protocol, 5432/3306"

        # Service mesh integration
        istio -> modelRegistryOp "Routes external traffic to Model Registry services" "mTLS/HTTPS"
        authorino -> kubernetes "Validates bearer tokens and checks RBAC permissions" "TokenReview/SubjectAccessReview API"
        prometheus -> modelRegistryOp "Scrapes operator metrics" "HTTPS/8443"

        # ODH ecosystem integrations
        dashboardUser -> modelRegistryOp "Manages model registry instances via UI" "REST API/8080"
        pipelinesUser -> modelRegistryOp "Registers models and artifacts from pipelines" "gRPC/9090"
        kserveUser -> modelRegistryOp "Fetches model metadata for inference services" "gRPC/9090"
    }

    views {
        systemContext modelRegistryOp "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOp "Containers" {
            include *
            autoLayout
        }

        component controller "OperatorComponents" {
            include *
            autoLayout
        }

        component registryInstance "RegistryComponents" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
