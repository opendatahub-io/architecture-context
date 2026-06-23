workspace {
    model {
        pipelineController = person "ML Pipeline Controller" "Data Science Pipelines / Kubeflow Pipelines — records pipeline runs, artifacts, executions, and lineage"
        pipelineUI = person "Pipeline UI" "Frontend for querying artifact lineage and execution history"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server providing a metadata store for tracking ML artifacts, executions, contexts, and lineage relationships" {
            grpcServer = container "metadata_store_server" "C++ gRPC server binary exposing MetadataStoreService API (40+ RPCs) for CRUD on ML metadata entities" "C++ / gRPC / BoringSSL"
            serviceImpl = container "MetadataStoreServiceImpl" "Thin gRPC service wrapper delegating to MetadataStore core logic" "C++ / Protocol Buffers"
            metadataStore = container "MetadataStore" "Core metadata management logic with schema migration and transactional operations" "C++"
            rdbmsDAO = container "RDBMSMetadataAccessObject" "Storage abstraction over SQL backends with template-based query system" "C++ / MetadataSourceQueryConfig"
            pythonClient = container "ml-metadata Python Client" "Dual-mode client: direct DB access (pybind11) or gRPC remote client" "Python / pybind11 / grpc"
        }

        mysql = softwareSystem "MySQL / MariaDB" "Persistent metadata storage backend" "Database"
        postgresql = softwareSystem "PostgreSQL" "Alternative persistent metadata storage backend" "Database"
        sqlite = softwareSystem "SQLite" "In-memory / file-based metadata storage for testing" "Embedded Database"

        # Relationships - External consumers
        pipelineController -> mlmd "Records pipeline metadata via gRPC" "gRPC/HTTP2 :8080, Optional TLS/mTLS"
        pipelineUI -> mlmd "Queries lineage and execution history" "gRPC/HTTP2 :8080 (indirect via API server)"

        # Relationships - Internal
        grpcServer -> serviceImpl "Delegates RPCs"
        serviceImpl -> metadataStore "Invokes metadata operations"
        metadataStore -> rdbmsDAO "Persists/queries metadata"
        pythonClient -> grpcServer "gRPC remote mode" "gRPC/HTTP2 :8080"

        # Relationships - Database backends
        mlmd -> mysql "Stores/retrieves metadata" "MySQL Protocol :3306, Optional SSL, Username/password"
        mlmd -> postgresql "Stores/retrieves metadata" "PostgreSQL Protocol :5432, Optional SSL, Username/password"
        mlmd -> sqlite "Embedded storage" "In-process"

        # Python client direct mode
        pythonClient -> mysql "Direct DB access (pybind11)" "MySQL Protocol :3306"
        pythonClient -> postgresql "Direct DB access (pybind11)" "PostgreSQL Protocol :5432"
    }

    views {
        systemContext mlmd "SystemContext" {
            include *
            autoLayout
            description "ML Metadata system context showing consumers and database backends"
        }

        container mlmd "Containers" {
            include *
            autoLayout
            description "ML Metadata internal components: gRPC server, core logic, storage abstraction, and Python client"
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Database" {
                background #999999
                color #ffffff
                shape cylinder
            }
            element "Embedded Database" {
                background #cccccc
                color #333333
                shape cylinder
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
