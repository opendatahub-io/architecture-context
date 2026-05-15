workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines that produce metadata"
        pipelinedev = person "Pipeline Developer" "Queries lineage and metadata for debugging/auditing"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server that records and retrieves metadata associated with ML workflows — artifacts, executions, contexts, and lineage" {
            server = container "metadata_store_server" "Main gRPC server exposing MetadataStoreService API for CRUD operations on ML metadata entities" "C++ gRPC Service"
            core = container "metadata_store (core)" "Core metadata store logic including database access, query execution, and transaction management" "C++ Library"
            queryEngine = container "Query Engine" "SQL query construction and filter parsing using ZetaSQL for flexible metadata queries" "C++ Library"

            server -> core "Delegates persistence operations"
            core -> queryEngine "Constructs SQL queries with ZetaSQL"
        }

        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration system that records pipeline run metadata" "Internal RHOAI"
        tfx = softwareSystem "TFX / Kubeflow Pipelines" "Legacy pipeline system integration" "External"
        mysql = softwareSystem "MySQL / MariaDB" "Relational database for production metadata storage" "External"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database for production metadata storage" "External"
        pythonLib = softwareSystem "ml_metadata Python Library" "Client library for interacting with MLMD via Python" "PyPI Package"

        datascientist -> dsp "Runs ML pipelines"
        pipelinedev -> pythonLib "Queries metadata and lineage"
        dsp -> mlmd "Records pipeline artifacts, executions, events, and contexts" "gRPC/HTTP2 8080/TCP"
        tfx -> mlmd "Records lineage metadata" "gRPC/HTTP2 8080/TCP"
        pythonLib -> mlmd "CRUD operations on metadata entities" "gRPC/HTTP2 8080/TCP"
        mlmd -> mysql "Stores and retrieves metadata entities" "MySQL wire protocol 3306/TCP"
        mlmd -> postgresql "Stores and retrieves metadata entities" "PostgreSQL wire protocol"
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
            element "PyPI Package" {
                background #6cb4ee
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
