workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines, queries metadata and lineage"
        mlEngineer = person "ML Engineer" "Builds pipeline components that record artifacts and executions"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server for recording, retrieving, and querying ML workflow metadata including artifacts, executions, contexts, and lineage" {
            grpcServer = container "metadata_store_server" "C++ gRPC server exposing MetadataStoreService API" "C++ / gRPC / BoringSSL" "Binary"
            metadataStore = container "MetadataStore Core" "Core metadata access layer managing schema, transactions, and query execution" "C++ Library"
            dbAdapters = container "Database Adapters" "SQLite, MySQL, PostgreSQL backend implementations" "C++ / libmysqlclient / libpq"
            protoDefinitions = container "Proto Definitions" "MetadataStoreService, data model types, query configs" "Protobuf / gRPC"

            grpcServer -> metadataStore "Delegates metadata operations"
            metadataStore -> dbAdapters "Executes queries via database-specific adapters"
            protoDefinitions -> grpcServer "Defines gRPC service contract"
        }

        pythonLib = softwareSystem "ml-metadata Python Library" "Python client with pybind11 bindings for direct DB or gRPC access" "Client Library"

        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "RHOAI-specific pipeline orchestrator" "Internal RHOAI"
        dspOperator = softwareSystem "DSP Operator" "Deploys and configures MLMD as part of pipeline infrastructure" "Internal RHOAI"
        pipelineUI = softwareSystem "Pipeline UI" "Web UI for pipeline visualization and lineage exploration" "Internal RHOAI"
        tfx = softwareSystem "TFX Components" "TensorFlow Extended pipeline components" "External"

        mysql = softwareSystem "MySQL / MariaDB" "Relational database for metadata persistence" "External Database"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database for metadata persistence" "External Database"

        # Relationships
        datascientist -> pipelineUI "Explores pipeline runs and lineage"
        mlEngineer -> kfp "Defines and submits ML pipelines"

        kfp -> mlmd "Records pipeline metadata (artifacts, executions, lineage)" "gRPC/HTTP2 :8080"
        dsp -> mlmd "Records pipeline metadata" "gRPC/HTTP2 :8080"
        pipelineUI -> mlmd "Queries metadata for visualization" "gRPC/HTTP2 :8080"
        tfx -> mlmd "Records component execution metadata" "gRPC/HTTP2 :8080"
        pythonLib -> mlmd "Client access to metadata store" "gRPC/HTTP2 :8080"

        dspOperator -> mlmd "Deploys and configures server" "Kubernetes API"

        mlmd -> mysql "Persists metadata" "MySQL protocol :3306"
        mlmd -> postgresql "Persists metadata" "PostgreSQL protocol :5432"
    }

    views {
        systemContext mlmd "SystemContext" {
            include *
            autoLayout
            description "ML Metadata in the RHOAI ecosystem"
        }

        container mlmd "Containers" {
            include *
            autoLayout
            description "Internal structure of the MLMD gRPC server"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External Database" {
                background #999999
                color #ffffff
                shape Cylinder
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Client Library" {
                background #9b59b6
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
            element "Binary" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
