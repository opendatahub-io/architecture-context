workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Registers, versions, and tracks ML models and metadata"
        operator = person "Platform Operator" "Deploys and manages Model Registry instances"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator that deploys and manages Model Registry service instances" {
            controller = container "Operator Controller" "Reconciles ModelRegistry CRs and manages lifecycle" "Go 1.21" {
                reconciler = component "Reconciler" "Watches ModelRegistry CRs and reconciles desired state"
                resourceManager = component "Resource Manager" "Creates/updates Deployments, Services, RBAC"
                istioManager = component "Istio Manager" "Manages Gateways, VirtualServices, DestinationRules"
                authManager = component "Auth Manager" "Manages AuthConfigs and AuthorizationPolicies"
            }

            modelRegistryService = container "Model Registry Service" "Provides REST and gRPC APIs for ML metadata" "Multi-container Pod" {
                restAPI = component "REST API" "HTTP API on port 8080"
                grpcAPI = component "ML Metadata gRPC API" "gRPC API on port 9090"
            }
        }

        # External Systems
        kubernetes = softwareSystem "Kubernetes API Server" "Manages cluster resources and RBAC" "External"
        database = softwareSystem "PostgreSQL / MySQL" "Persistent storage for ML metadata" "External"

        # Istio/Service Mesh
        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and Gateway routing" "External - Optional"
        authorino = softwareSystem "Authorino" "External authorization service for API authentication" "Internal ODH/RHOAI - Optional"

        # OpenShift Components
        openshift = softwareSystem "OpenShift" "OpenShift-specific features (Routes, Groups, Ingress)" "External - Optional"

        # Monitoring
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External - Optional"

        # Integration Points
        odhOperator = softwareSystem "ODH Operator" "Manages ODH/RHOAI component deployments" "Internal ODH/RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External - Optional"

        # User interactions
        user -> modelRegistryService "Registers models, queries metadata via REST/gRPC" "HTTPS/443 or gRPC/443, Bearer Token"
        operator -> modelRegistryOperator "Creates ModelRegistry CRs via kubectl/UI" "kubectl/HTTPS"

        # Operator interactions
        controller -> kubernetes "Watches CRs, creates/manages resources" "HTTPS/6443, SA Token"
        controller -> istio "Creates Gateways, VirtualServices, DestinationRules, AuthzPolicies" "HTTPS/6443, SA Token"
        controller -> authorino "Creates AuthConfig CRs" "HTTPS/6443, SA Token"
        controller -> openshift "Creates Routes, Groups, queries Ingress config" "HTTPS/6443, SA Token"
        controller -> prometheus "Exposes metrics" "HTTPS/8443, OpenShift Serving Cert"

        # Model Registry Service interactions
        modelRegistryService -> database "Persists ML metadata" "PostgreSQL/5432 or MySQL/3306, TLS, User/Pass"
        modelRegistryService -> kubernetes "Validates service accounts for internal calls" "HTTPS/6443"

        # External access flows
        istio -> modelRegistryService "Routes external traffic via Gateway" "HTTP/8080 or gRPC/9090, mTLS"
        istio -> authorino "Delegates authorization" "gRPC/50051, mTLS"
        authorino -> kubernetes "TokenReview + SubjectAccessReview" "HTTPS/6443, SA Token"
        openshift -> modelRegistryService "Routes traffic via OpenShift Route (alternative)" "HTTP/8080"

        # Integration points
        odhOperator -> modelRegistryOperator "Provides auth config via ConfigMap" "Configuration"
        certManager -> istio "Provisions TLS certificates for Gateways" "Certificate issuance"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container modelRegistryOperator "Containers" {
            include *
            autoLayout lr
        }

        component controller "OperatorComponents" {
            include *
            autoLayout lr
        }

        component modelRegistryService "ModelRegistryComponents" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External - Optional" {
                background #cccccc
                color #000000
            }
            element "Internal ODH/RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal ODH/RHOAI - Optional" {
                background #a8e063
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #2e7db8
                color #ffffff
            }
            element "Component" {
                background #1e5a8e
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape person
            }
        }

        theme default
    }
}
