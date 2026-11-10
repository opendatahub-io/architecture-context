workspace "Data Connect Hub" "RHOAI 3.7-ea.1 - data-connect-hub architecture context" {
    model {
        user = person "Data Scientist / Application" "Manages connections and reads data via REST, Python SDK, or Arrow Flight"
        admin = person "Cluster Admin" "Creates DataConnectService, provisions dch-database-config, binds tenant roles"

        dch = softwareSystem "Data Connect Hub" "Central data-source connection service: connection metadata REST API and Arrow Flight data plane" {
            controller = container "dc-controller" "Reconciles DataConnectService; renders kustomize manifests; seeds connection types; migrates ODH dashboard connections" "Go, controller-runtime v0.25.2"
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination and per-path TokenReview + SubjectAccessReview keyed on X-Tenant-Id" "Sidecar, 8443/TCP HTTPS"
            rest = container "rest-service" "Connection / connection-type / flight-registration CRUD, credential testing, readiness audit, binary download, secret export" "Rust, actix-web, 127.0.0.1:8080"
            flight = container "flight-service" "Streams Arrow record batches from external sources; TokenReview/SAR auth; connector registry" "Rust, tonic + arrow-flight, 8443/TCP gRPC TLS"
            connectors = container "Connectors" "postgres, sqlite, s3, milvus, elasticsearch, neo4j, uri connector crates implementing SQLReader" "Rust libraries"
            sdk = container "Python SDK" "REST (httpx/pydantic) and optional Flight client; not shipped in an image" "Python"
        }

        gateway = softwareSystem "odh-gateway" "Gateway API ingress deployed by rhods-operator" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Source of legacy connection-type ConfigMaps and connection Secrets" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator / DSC" "Platform operator; future owner of opendatahub-dataconnecthub-config" "Internal ODH"
        prometheus = softwareSystem "prometheus-operator / ODH monitoring" "Scrapes REST, Flight and controller metrics via ServiceMonitor" "Internal ODH"
        serviceCA = softwareSystem "OpenShift service-CA" "Issues serving certs and injects CA bundles" "Internal ODH"
        k8s = softwareSystem "Kubernetes / OpenShift API" "Resources, TokenReview/SAR, Secrets, APIServer TLS profile, IngressController" "External"
        postgres = softwareSystem "PostgreSQL metastore" "Stores connections, connection types, flight services (shared, tenant_id filtered)" "External"
        sources = softwareSystem "External data sources" "PostgreSQL, S3, Milvus, Elasticsearch, Neo4j, HTTP URIs / HuggingFace" "External"
        otlp = softwareSystem "OTLP collector" "Optional trace export" "External"

        user -> gateway "REST and Flight requests" "HTTPS / gRPC 443, Bearer + X-Tenant-Id"
        user -> sdk "Uses"
        sdk -> gateway "Calls" "HTTPS / gRPC 443"
        admin -> k8s "Creates DataConnectService, RoleBindings" "kubectl"
        gateway -> kubeRbacProxy "Routes /health, connections, connection-types, test" "HTTPS 8443 TLS"
        gateway -> flight "Routes FlightService, grpc.health" "gRPC 8443 TLS"
        kubeRbacProxy -> k8s "TokenReview + SAR" "HTTPS 443"
        kubeRbacProxy -> rest "Proxies with x-remote-user" "HTTP loopback 8080"
        rest -> flight "Audits, credential tests, data reads" "gRPC 8443 TLS, REST SA token"
        rest -> postgres "Reads/writes metadata" "PostgreSQL 5432, optional TLS"
        rest -> k8s "Secret get/create/patch/delete, export" "HTTPS 443"
        flight -> postgres "Loads connection metadata" "PostgreSQL 5432"
        flight -> k8s "TokenReview/SAR, reads connection Secrets" "HTTPS 443"
        flight -> connectors "Dispatches reads"
        connectors -> sources "Reads data" "PG / HTTPS / Bolt, per-connection creds"
        controller -> k8s "Reconciles; applies Deployments, Services, NetworkPolicies, CRBs, HTTPRoute, ServiceMonitor" "HTTPS 443"
        controller -> kubeRbacProxy "Connection-type sync, migration, Flight registration" "HTTPS 8443, controller SA bearer"
        controller -> gateway "Creates HTTPRoute; reads Gateway hostname/status"
        controller -> dashboard "Migrates labelled ConfigMaps/Secrets (secret_ref only)"
        controller -> prometheus "Creates ServiceMonitor (OpenShift overlay)"
        rhodsOperator -> controller "Provides platform ConfigMap (future)"
        serviceCA -> dch "Serving certs rest-service-tls, flight-service-tls; CA bundle flight-service-ca"
        prometheus -> rest "Scrapes metrics" "HTTP 9090"
        prometheus -> flight "Scrapes metrics" "HTTP 9090"
        rest -> otlp "Traces (optional)" "gRPC/HTTP"
        flight -> otlp "Traces (optional)" "gRPC/HTTP"
    }

    views {
        systemContext dch "SystemContext" {
            include *
            autoLayout
        }

        container dch "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
        }
    }
}
