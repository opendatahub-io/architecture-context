workspace {
    model {
        dataScientist = person "Data Scientist" "Connects to heterogeneous data sources for ML workflows"
        platformAdmin = person "Platform Admin" "Deploys and configures Data Connect Hub instances"

        dataConnectHub = softwareSystem "Data Connect Hub" "Centralised data connection management platform exposing heterogeneous data sources through REST and Apache Arrow Flight APIs" {
            dcController = container "dc-controller" "Reconciles DataConnectService CRDs and manages lifecycle of service deployments, RBAC, HTTPRoutes, and NetworkPolicies" "Go Operator (controller-runtime)"
            restService = container "rest-service" "REST API for connection metadata CRUD, credential testing, binary data download, and flight service registration" "Rust (actix-web)"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication and authorization sidecar fronting the REST API via TokenReview and SubjectAccessReview" "Sidecar"
            flightService = container "flight-service" "Apache Arrow Flight gRPC server for high-throughput columnar data transfer across pluggable connectors" "Rust (tonic)"
            connectors = container "Connector Plugins" "Pluggable data source connectors: PostgreSQL, SQLite, S3, Milvus, Elasticsearch, Neo4j, URI" "Rust Libraries"
            pythonSDK = container "Python SDK" "REST client SDK for programmatic access to the DCH REST API" "Python"
        }

        odhGateway = softwareSystem "ODH Gateway" "Platform gateway providing external ingress routing via Gateway API (HTTPRoute)" "Internal Platform"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management, authentication (TokenReview), and authorization (SubjectAccessReview)" "Platform"
        openshiftApi = softwareSystem "OpenShift APIServer" "Provides dynamic TLS profile resolution and cluster ingress domain discovery" "Platform"
        serviceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning via service-serving-cert-signer annotations" "Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor resources" "Platform"
        postgresql = softwareSystem "PostgreSQL" "Shared metadata persistence backend for connections and connection types" "External"
        dataSources = softwareSystem "Data Source Backends" "Heterogeneous data sources: PostgreSQL, SQLite, S3, Milvus, Elasticsearch, Neo4j, URI endpoints" "External"

        # User interactions
        dataScientist -> dataConnectHub "Manages connections and queries data via REST API and Arrow Flight" "HTTPS/gRPC"
        dataScientist -> pythonSDK "Uses SDK for programmatic access" "Python"
        platformAdmin -> dcController "Deploys DataConnectService CR" "kubectl"

        # Internal flows
        pythonSDK -> restService "REST API calls" "HTTPS/8443"
        kubeRbacProxy -> restService "Proxies authenticated traffic" "HTTP/8080 (localhost)"
        restService -> flightService "Data operations, credential testing" "gRPC/8443 TLS"
        flightService -> connectors "Delegates data retrieval" "In-process"

        # External flows
        odhGateway -> kubeRbacProxy "Routes REST traffic" "HTTPS/8443"
        odhGateway -> flightService "Routes Flight traffic" "gRPC/8443"
        dcController -> k8sApi "CRD reconciliation, resource management" "HTTPS/6443"
        kubeRbacProxy -> k8sApi "TokenReview + SubjectAccessReview" "HTTPS/6443"
        flightService -> k8sApi "TokenReview + SubjectAccessReview" "HTTPS/6443"
        dcController -> openshiftApi "TLS profile + ingress domain" "HTTPS/6443"
        serviceCA -> restService "TLS certificate provisioning" "Annotation"
        serviceCA -> flightService "TLS certificate provisioning" "Annotation"
        restService -> postgresql "Connection metadata CRUD" "TCP/5432"
        flightService -> postgresql "Connection metadata lookup" "TCP/5432"
        connectors -> dataSources "Data retrieval" "Various protocols"
        dcController -> prometheusOperator "ServiceMonitor management" "HTTPS/6443"
    }

    views {
        systemContext dataConnectHub "SystemContext" {
            include *
            autoLayout
        }

        container dataConnectHub "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Sidecar" {
                background #d79b00
                color #ffffff
            }
        }
    }
}
