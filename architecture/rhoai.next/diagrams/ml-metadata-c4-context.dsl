workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines, queries metadata and lineage"
        platformadmin = person "Platform Admin" "Deploys and configures MLMD server and database backends"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server and client library for recording and retrieving metadata associated with ML workflows" {
            grpcServer = container "metadata_store_server" "gRPC server binary providing MetadataStoreService API (40+ RPC methods)" "C++ gRPC Service"
            metadataStore = container "MetadataStore" "Business logic layer for metadata CRUD operations and lineage queries" "C++ Library"
            dbAccessLayer = container "Database Access Layer" "Pluggable backend supporting MySQL, PostgreSQL, and SQLite" "C++ Library"
            pythonClient = container "ml-metadata Python Client" "Python client library for interacting with gRPC server or local database via pybind11" "Python Library"
            protoDefinitions = container "MetadataStoreService Proto" "Protocol Buffers service and message definitions" "Protocol Buffers"

            protoDefinitions -> grpcServer "Defines API for"
            grpcServer -> metadataStore "Delegates operations to"
            metadataStore -> dbAccessLayer "Queries via"
            pythonClient -> grpcServer "Connects to via gRPC" "gRPC/HTTP2 8080/TCP"
        }

        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        kubeflowPipelinesSDK = softwareSystem "Kubeflow Pipelines SDK" "Python SDK for pipeline authoring and metadata access" "Internal RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "RHOAI pipeline infrastructure for artifact and lineage tracking" "Internal RHOAI"
        mysql = softwareSystem "MySQL / MariaDB" "Relational database for persistent metadata storage" "External"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database backend" "External"
        rhodsOperator = softwareSystem "RHODS Operator" "Deploys and manages MLMD server and related resources" "Internal RHOAI"

        datascientist -> kubeflowPipelinesSDK "Authors and runs pipelines via"
        datascientist -> mlmd "Queries metadata and lineage via Python client"
        platformadmin -> rhodsOperator "Configures MLMD deployment via"

        kubeflowPipelines -> mlmd "Records pipeline run metadata" "gRPC/HTTP2 8080/TCP"
        kubeflowPipelinesSDK -> mlmd "Queries and updates metadata" "gRPC/HTTP2 8080/TCP"
        dataSciencePipelines -> mlmd "Stores artifact and lineage data" "gRPC/HTTP2 8080/TCP"
        rhodsOperator -> mlmd "Deploys and configures"

        mlmd -> mysql "Stores metadata records" "MySQL protocol 3306/TCP"
        mlmd -> postgresql "Stores metadata records (alternative)" "PostgreSQL protocol 5432/TCP"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
