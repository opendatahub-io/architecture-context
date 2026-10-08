workspace {
    model {
        pipelineComponent = person "ML Pipeline Component" "Kubeflow pipeline step recording metadata"
        dataScientist = person "Data Scientist" "Queries lineage and experiment metadata"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server for recording and retrieving ML workflow metadata, artifact lineage, and execution tracking" {
            server = container "metadata_store_server" "C++ gRPC server serving ~47 RPC methods for ML metadata CRUD and lineage queries" "C++ / gRPC / HTTP-2"
            proto = container "MetadataStoreService Proto" "Protobuf service definition with types, artifacts, executions, contexts, events, lineage RPCs" "Protobuf"
            sqliteAdapter = container "SQLite Adapter" "Embedded database for development and testing" "C++"
            mysqlAdapter = container "MySQL Adapter" "Database adapter for MySQL/MariaDB backends" "C++"
            pgAdapter = container "PostgreSQL Adapter" "Database adapter for PostgreSQL backends" "C++"
        }

        pythonLib = softwareSystem "ml_metadata Python Library" "Client library with SWIG-wrapped C++ (direct) and gRPC (remote) access modes" "Client Library"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform that records metadata via MLMD" "Internal RHOAI"
        mysql = softwareSystem "MySQL / MariaDB" "Persistent relational metadata storage backend" "External"
        postgresql = softwareSystem "PostgreSQL" "Alternative persistent relational metadata storage backend" "External"
        sqlite = softwareSystem "SQLite" "Embedded file-based metadata storage for development" "External"

        pipelineComponent -> dsp "Runs within pipeline"
        dsp -> mlmd "Records pipeline metadata" "gRPC/8080"
        dataScientist -> pythonLib "Queries metadata"
        pythonLib -> mlmd "gRPC client calls" "gRPC/8080"
        mlmd -> mysql "Stores metadata" "MySQL/3306"
        mlmd -> postgresql "Stores metadata" "PostgreSQL/5432"
        mlmd -> sqlite "Stores metadata" "Local file"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Client Library" {
                background #9ecae1
                color #333333
            }
        }
    }
}
