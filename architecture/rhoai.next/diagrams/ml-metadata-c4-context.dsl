workspace {
    model {
        pipelineEngineer = person "Pipeline Engineer" "Creates and manages ML pipelines that produce metadata"

        mlMetadata = softwareSystem "ML Metadata (MLMD)" "gRPC server and client library for recording and retrieving metadata associated with ML workflows" {
            grpcServer = container "metadata_store_server" "Standalone C++ gRPC server implementing MetadataStoreService API for CRUD operations on ML metadata entities" "C++ / Bazel / BoringSSL"
            pythonClient = container "ml_metadata Python Library" "Client library providing both direct-database and gRPC-based access to the metadata store" "Python / grpcio"
        }

        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures the MLMD server as part of the DSP stack" "Internal RHOAI"
        kfPipelinesSDK = softwareSystem "Kubeflow Pipelines SDK" "Pipeline SDK that records and retrieves pipeline run metadata" "Internal RHOAI"
        pipelineUI = softwareSystem "Pipeline UI (Data Science Pipelines)" "Web UI for visualizing pipeline artifacts and execution metadata" "Internal RHOAI"
        mysql = softwareSystem "MySQL / MariaDB" "Relational database for persistent metadata storage" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for persistent metadata storage (alternative)" "External"

        pipelineEngineer -> kfPipelinesSDK "Submits pipeline runs"
        pipelineEngineer -> pipelineUI "Views pipeline metadata and lineage"

        dspOperator -> mlMetadata "Deploys and configures lifecycle"
        kfPipelinesSDK -> grpcServer "Records pipeline metadata" "gRPC/8080, Optional TLS"
        pipelineUI -> grpcServer "Retrieves metadata for visualization" "gRPC/8080, Optional TLS"
        grpcServer -> mysql "Stores metadata entities" "MySQL/3306, Optional SSL"
        grpcServer -> postgresql "Stores metadata entities" "PostgreSQL/5432, Optional SSL"
    }

    views {
        systemContext mlMetadata "SystemContext" {
            include *
            autoLayout
        }

        container mlMetadata "Containers" {
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
                background #08427b
                color #ffffff
            }
        }
    }
}
