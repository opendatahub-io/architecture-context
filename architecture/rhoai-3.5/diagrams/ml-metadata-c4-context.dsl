workspace {
    model {
        pipelineOrchestrator = person "Pipeline Orchestrator" "Kubeflow Pipelines / Data Science Pipelines component that records and queries ML metadata"
        pipelineUser = person "Pipeline UI User" "Views pipeline runs, artifacts, and lineage graphs via KFP UI"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server and Python client library for recording and retrieving metadata associated with ML workflows -- artifacts, executions, contexts, and lineage relationships" {
            grpcServer = container "MLMD gRPC Server" "C++ binary serving MetadataStoreService with ~45 RPC methods for CRUD operations on ML metadata entities and lineage graph traversal" "C++ / gRPC / BoringSSL" "metadata_store_server"
            metadataStore = container "MetadataStore" "Core business logic for metadata operations, schema migration, and storage abstraction" "C++"
            storageLayer = container "Storage Abstraction" "Pluggable database backends: MySQLMetadataSource, PostgreSQLMetadataSource, SqliteMetadataSource" "C++"
            pythonClient = container "ml_metadata Python Package" "Python client library providing MetadataStore API via gRPC or embedded C++ bindings (pybind11)" "Python"
        }

        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Pipeline orchestrator that stores and retrieves execution metadata, artifact metadata, and lineage" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines (DSP)" "RHOAI pipeline implementation that stores metadata through MLMD" "Internal RHOAI"
        kfpUI = softwareSystem "KFP UI" "Pipeline visualization UI that queries metadata for pipeline runs, artifacts, and lineage graphs" "Internal RHOAI"

        mysql = softwareSystem "MySQL / MariaDB" "Persistent metadata storage backend" "External Database"
        postgresql = softwareSystem "PostgreSQL" "Alternative persistent metadata storage backend" "External Database"

        # Relationships
        kubeflowPipelines -> mlmd "Records and retrieves pipeline metadata" "gRPC/HTTP2 8080/TCP, Optional TLS/mTLS"
        dsp -> mlmd "Stores pipeline execution metadata" "gRPC/HTTP2 8080/TCP, Optional TLS/mTLS"
        kfpUI -> mlmd "Queries metadata for visualization" "gRPC/HTTP2 8080/TCP, Optional TLS/mTLS"
        pipelineOrchestrator -> mlmd "Records artifacts, executions, contexts, events"
        pipelineUser -> kfpUI "Views pipeline runs and lineage"

        mlmd -> mysql "Stores metadata entities, types, properties, events, relationships" "MySQL/3306 Optional SSL"
        mlmd -> postgresql "Stores metadata (alternative backend)" "PostgreSQL/5432 Optional SSL"

        # Internal container relationships
        grpcServer -> metadataStore "Delegates RPC handling"
        metadataStore -> storageLayer "Executes SQL queries"
        pythonClient -> grpcServer "gRPC client mode" "gRPC/HTTP2"
    }

    views {
        systemContext mlmd "SystemContext" {
            include *
            autoLayout
        }

        container mlmd "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External Database" {
                background #f5a623
                shape Cylinder
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
