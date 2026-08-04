workspace {
    model {
        pipelineOrchestrator = person "Pipeline Orchestrator" "Data Science Pipelines or other ML pipeline systems that record and query metadata"

        mlMetadata = softwareSystem "ml-metadata" "gRPC metadata store server that records and retrieves metadata associated with ML workflows, including artifacts, executions, and their lineage relationships" {
            server = container "metadata_store_server" "C++ gRPC server (~40 RPCs) for CRUD operations on artifacts, executions, contexts, types, events, and lineage graph traversal" "C++ Binary (Bazel-built)"
            grpcAPI = container "MetadataStoreService" "gRPC service definition with protobuf message types for ML metadata entities" "gRPC/Protobuf"
        }

        mariadb = softwareSystem "MariaDB/MySQL" "Relational database for persistent storage of ML metadata entities and relationships" "External"
        pythonClient = softwareSystem "Python Client Library" "ml_metadata Python package for programmatic access to the metadata store" "Client Library"

        # Relationships
        pipelineOrchestrator -> mlMetadata "Records artifacts, executions, events; queries lineage" "gRPC/8080"
        pythonClient -> mlMetadata "CRUD operations on ML metadata entities" "gRPC/8080"
        mlMetadata -> mariadb "Persists and queries metadata records" "MySQL wire protocol/3306"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Client Library" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
