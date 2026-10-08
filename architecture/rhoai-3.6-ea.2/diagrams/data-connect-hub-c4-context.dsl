workspace {
    model {
        dataScientist = person "Data Scientist" "Connects to data sources for ML workflows"
        platformAdmin = person "Platform Admin" "Manages DCH deployment via DataConnectService CRs"

        dch = softwareSystem "Data Connect Hub" "Unified middleware for data source integration via REST and Arrow Flight gRPC APIs" {
            dcController = container "dc-controller" "Reconciles DataConnectService CRDs; manages data plane lifecycle, networking, RBAC" "Go Operator (controller-runtime v0.25.1)"
            restService = container "rest-service" "REST API for connection metadata CRUD, credential testing, binary data download" "Rust (actix-web)"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication and authorization sidecar for REST API" "Go Sidecar"
            flightService = container "flight-service" "Apache Arrow Flight gRPC server for high-throughput columnar data ingestion" "Rust (tonic)"
            postgresConnector = container "postgres-connector" "PostgreSQL data source connector" "Rust Library (SQLx)"
            s3Connector = container "s3-connector" "S3-compatible object store connector" "Rust Library (OpenDAL)"
            esConnector = container "elasticsearch-connector" "Elasticsearch data source connector" "Rust Library (reqwest)"
            milvusConnector = container "milvus-connector" "Milvus vector database connector" "Rust Library (reqwest)"
            neo4jConnector = container "neo4j-connector" "Neo4j graph database connector" "Rust Library (neo4rs)"
            uriConnector = container "uri-connector" "URI-based data source connector" "Rust Library (reqwest)"
            pythonSdk = container "python-sdk" "REST client SDK for programmatic DCH access" "Python Library"
        }

        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External"
        odhGateway = softwareSystem "ODH Gateway" "Platform Gateway API for external routing" "Internal RHOAI"
        odhOperator = softwareSystem "OpenDataHub Operator" "Platform operator that enables DCH component" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Metadata storage for connections and connection types" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning" "External"

        s3Storage = softwareSystem "S3 Storage" "S3-compatible object storage" "External"
        elasticSearch = softwareSystem "Elasticsearch" "Search and analytics engine" "External"
        milvus = softwareSystem "Milvus" "Vector database" "External"
        neo4j = softwareSystem "Neo4j" "Graph database" "External"
        pgDataSource = softwareSystem "PostgreSQL Data Source" "External PostgreSQL databases" "External"

        # User interactions
        dataScientist -> dch "Creates connections and ingests data via REST/gRPC" "HTTPS/gRPC"
        platformAdmin -> dch "Deploys DataConnectService CRs" "kubectl"

        # Container relationships
        kubeRbacProxy -> restService "Proxies authenticated requests" "HTTP/8080 localhost"
        restService -> flightService "Readiness checks, credential testing" "gRPC/8443 TLS"
        flightService -> postgresConnector "Uses" ""
        flightService -> s3Connector "Uses" ""
        flightService -> esConnector "Uses" ""
        flightService -> milvusConnector "Uses" ""
        flightService -> neo4jConnector "Uses" ""
        flightService -> uriConnector "Uses" ""
        dcController -> restService "Manages lifecycle" "Kubernetes API"
        dcController -> flightService "Manages lifecycle" "Kubernetes API"
        pythonSdk -> kubeRbacProxy "REST API calls" "HTTPS/8443"

        # External dependencies
        dch -> kubernetes "Controller reconciliation, auth delegation" "HTTPS/6443"
        dch -> odhGateway "Exposes services via HTTPRoute" "HTTPS/8443"
        dch -> postgresql "Stores connection metadata" "TCP/5432 TLS"
        dch -> serviceCa "TLS certificate provisioning" "Service annotations"
        odhOperator -> dch "Creates DataConnectService CR" ""
        kubeRbacProxy -> kubernetes "TokenReview + SubjectAccessReview" "HTTPS/6443"
        flightService -> kubernetes "TokenReview + SubjectAccessReview" "HTTPS/6443"

        # Data source connections
        postgresConnector -> pgDataSource "Data ingestion" "TCP/5432"
        s3Connector -> s3Storage "Data ingestion" "HTTPS/443"
        esConnector -> elasticSearch "Data ingestion" "HTTP(S)/9200"
        milvusConnector -> milvus "Data ingestion" "gRPC/19530"
        neo4jConnector -> neo4j "Data ingestion" "Bolt/7687"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
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
