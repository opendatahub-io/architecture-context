workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages model registries for ML model metadata tracking"
        admin = person "Platform Administrator" "Deploys and configures Model Registry Operator"

        modelRegistryOp = softwareSystem "Model Registry Operator" "Kubernetes operator for deploying and managing Model Registry instances with REST/gRPC APIs for model metadata storage" {
            controller = container "Controller Manager" "Reconciles ModelRegistry CRs and manages instance lifecycle" "Go Operator" {
                tags "Operator"
            }
            webhook = container "Webhook Server" "Validates and mutates ModelRegistry CR changes" "Go Service" {
                tags "Operator"
            }
        }

        modelRegistryInstance = softwareSystem "Model Registry Instance" "REST and gRPC endpoints for model metadata management" {
            restServer = container "REST API Server" "Provides REST API for model registry operations" "Go Service" {
                tags "Registry"
            }
            grpcServer = container "gRPC Server" "Provides ML Metadata gRPC API for model artifacts" "Go Service" {
                tags "Registry"
            }
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication proxy with bearer token validation" "Go Proxy" {
                tags "Registry"
            }
        }

        k8s = softwareSystem "Kubernetes API Server" "Kubernetes control plane for CR management and RBAC" "External"
        postgresql = softwareSystem "PostgreSQL Database" "Model metadata persistence backend" "External Database"
        mysql = softwareSystem "MySQL Database" "Alternative model metadata persistence backend" "External Database"
        router = softwareSystem "OpenShift Router" "Ingress gateway for external access" "External OpenShift"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for advanced networking and mTLS" "External"
        serviceCA = softwareSystem "OpenShift Service CA" "Auto-generates and rotates TLS certificates" "External OpenShift"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External ODH"
        odhOperator = softwareSystem "OpenDataHub Operator" "Platform operator managing ODH components" "Internal ODH"

        # User interactions
        user -> modelRegistryOp "Creates ModelRegistry CR via kubectl"
        user -> modelRegistryInstance "Queries model metadata via REST API" "HTTPS/8443 (Bearer Token)"
        admin -> modelRegistryOp "Deploys and configures operator"

        # Operator interactions
        modelRegistryOp -> k8s "Watches ModelRegistry CRs, creates Deployments/Services/Routes" "HTTPS/6443 (SA Token)"
        controller -> webhook "Validates CR changes" "In-process"
        k8s -> webhook "Sends admission review requests" "HTTPS/9443 (TLS Client Cert)"

        # Operator manages instances
        modelRegistryOp -> modelRegistryInstance "Creates and manages deployments"

        # Registry instance interactions
        kubeRbacProxy -> restServer "Forwards authenticated requests" "HTTP/8080 (localhost)"
        restServer -> postgresql "Stores/retrieves model metadata" "PostgreSQL/5432 (TLS optional)"
        restServer -> mysql "Stores/retrieves model metadata" "MySQL/3306 (TLS optional)"
        grpcServer -> postgresql "Stores/retrieves ML metadata artifacts" "PostgreSQL/5432 (TLS optional)"
        grpcServer -> mysql "Stores/retrieves ML metadata artifacts" "MySQL/3306 (TLS optional)"

        # External access
        router -> kubeRbacProxy "Routes external HTTPS traffic" "HTTPS/8443 (Bearer Token)"
        istio -> kubeRbacProxy "Routes traffic via service mesh" "HTTPS/8443 (mTLS)"

        # Platform integrations
        serviceCA -> modelRegistryOp "Provisions TLS certificates for services"
        prometheus -> controller "Scrapes operator metrics" "HTTPS/8443 (Bearer Token)"
        odhOperator -> modelRegistryOp "Provides service-mesh-refs ConfigMap for Istio config"
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

        container modelRegistryInstance "RegistryContainers" {
            include *
            autoLayout
        }

        systemContext modelRegistryInstance "RegistrySystemContext" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Database" {
                background #777777
                color #ffffff
                shape Cylinder
            }
            element "External OpenShift" {
                background #cc0000
                color #ffffff
            }
            element "External ODH" {
                background #0088ce
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Registry" {
                background #f5a623
                color #000000
            }
        }
    }
}
