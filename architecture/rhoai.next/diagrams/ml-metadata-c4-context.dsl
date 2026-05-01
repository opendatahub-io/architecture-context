workspace {
    model {
        pipelineEngineer = person "Pipeline Engineer" "Creates and monitors ML pipelines that produce metadata"
        dataScientist = person "Data Scientist" "Queries lineage and artifact metadata for ML experiments"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server and client library for recording and retrieving metadata associated with ML workflows" {
            grpcServer = container "metadata_store_server" "C++ gRPC server providing MetadataStoreService API with 40+ RPC methods" "C++ / gRPC / BoringSSL"
            pythonClient = container "ml-metadata Python Client" "Python client library with pybind11 bindings and gRPC connectivity" "Python / pybind11"
            protoService = container "MetadataStoreService Proto" "Protocol Buffers service definition for metadata CRUD and lineage queries" "Protocol Buffers"
        }

        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "RHOAI pipeline infrastructure for artifact and lineage tracking" "Internal RHOAI"
        mysql = softwareSystem "MySQL / MariaDB" "Relational database for persistent metadata storage" "External"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database for persistent metadata storage" "External"

        # Relationships
        pipelineEngineer -> kubeflowPipelines "Creates and runs ML pipelines"
        dataScientist -> mlmd "Queries lineage and artifact metadata" "gRPC/HTTP2 8080/TCP"

        kubeflowPipelines -> mlmd "Records pipeline run metadata: artifacts, executions, contexts, events" "gRPC/HTTP2 8080/TCP"
        dataSciencePipelines -> mlmd "Records artifact and lineage tracking metadata" "gRPC/HTTP2 8080/TCP"

        mlmd -> mysql "Stores metadata persistently" "MySQL Protocol 3306/TCP, Optional TLS"
        mlmd -> postgresql "Stores metadata persistently (alternative)" "PostgreSQL Protocol 5432/TCP, Optional TLS"

        # Container-level relationships
        kubeflowPipelines -> grpcServer "PutExecution, PutArtifacts, PutEvents" "gRPC/HTTP2"
        pythonClient -> grpcServer "All 40+ RPC methods" "gRPC/HTTP2"
        grpcServer -> mysql "INSERT, SELECT, UPDATE, DELETE" "MySQL Protocol"
        grpcServer -> postgresql "INSERT, SELECT, UPDATE, DELETE" "PostgreSQL Protocol"
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
            element "Person" {
                shape Person
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
