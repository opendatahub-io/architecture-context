workspace {
    model {
        user = person "Data Scientist / Application" "Accesses data via REST or Arrow Flight APIs"
        admin = person "Platform Admin" "Deploys and configures DataConnectService CRs"

        dataConnectHub = softwareSystem "Data Connect Hub" "Centralises data connection metadata management and exposes heterogeneous data sources through REST and Arrow Flight gRPC APIs" {
            dcController = container "dc-controller" "Reconciles DataConnectService CRs; deploys and manages the data plane" "Go / controller-runtime"
            restService = container "rest-service" "HTTP REST API for connection metadata CRUD, credential testing, binary data download" "Rust / actix-web"
            kubeRBACProxy = container "kube-rbac-proxy" "Authentication and per-namespace authorization sidecar" "Go Sidecar"
            flightService = container "flight-service" "Apache Arrow Flight gRPC server for columnar data streaming" "Rust / tonic"
            connectors = container "Connector Layer" "PostgreSQL, SQLite, S3, Milvus, Elasticsearch, Neo4j, URI connectors" "Rust Crates"
            pgMetaStore = container "pg-meta-store" "PostgreSQL-backed metadata storage for connections and types" "Rust Library"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management, authentication, and authorization" "Platform"
        openshiftAPI = softwareSystem "OpenShift API" "OpenShift-specific configuration (TLS profiles, ingress)" "Platform"
        gateway = softwareSystem "ODH Gateway" "Gateway API implementation for external traffic routing" "Internal Platform"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring stack via ServiceMonitor resources" "Internal Platform"
        serviceCA = softwareSystem "OpenShift Service-CA" "TLS certificate provisioning for inter-service communication" "Platform"

        postgresql = softwareSystem "PostgreSQL" "Relational database for metadata storage" "External"
        dataSources = softwareSystem "Data Sources" "PostgreSQL, S3, Milvus, Elasticsearch, Neo4j, SQLite, URI endpoints" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection" "External"

        # User interactions
        user -> gateway "REST/gRPC requests via HTTPS/443"
        admin -> k8sAPI "Creates DataConnectService CR via kubectl"

        # Gateway routing
        gateway -> kubeRBACProxy "Routes REST traffic via HTTPRoute, HTTPS/8443"
        gateway -> flightService "Routes Flight traffic via HTTPRoute, gRPC/8443"

        # Internal flows
        kubeRBACProxy -> restService "Proxies to upstream, HTTP/8080 (localhost)"
        kubeRBACProxy -> k8sAPI "SubjectAccessReview for authorization, HTTPS/6443"
        restService -> pgMetaStore "Metadata queries"
        restService -> flightService "Connection readiness audit, gRPC/8443"
        flightService -> pgMetaStore "Metadata queries"
        flightService -> connectors "Data retrieval via connector traits"
        flightService -> k8sAPI "TokenReview authentication, HTTPS/6443"
        pgMetaStore -> postgresql "SQL queries, TCP/5432 TLS"
        connectors -> dataSources "Data ingestion, per-connector protocol"

        # Controller flows
        dcController -> k8sAPI "Reconciles CRDs, manages resources, HTTPS/6443"
        dcController -> openshiftAPI "Reads TLS profiles and ingress config, HTTPS/6443"
        dcController -> restService "Seeds InitDataConnections, HTTPS/8443"
        serviceCA -> kubeRBACProxy "Injects TLS certificates"
        serviceCA -> flightService "Injects TLS certificates"

        # Monitoring and tracing
        prometheusOp -> restService "Scrapes metrics, HTTP/9090"
        prometheusOp -> flightService "Scrapes metrics, HTTP/9090"
        flightService -> otlpCollector "Exports traces, gRPC/4317"
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
            element "Software System" {
                shape RoundedBox
            }
            element "Platform" {
                background #dae8fc
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
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
