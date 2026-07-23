workspace {
    model {
        pipelineEngineer = person "Pipeline Engineer" "Creates and monitors ML pipelines that produce metadata"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server for recording and retrieving metadata associated with ML workflows -- artifacts, executions, contexts, and lineage" {
            grpcServer = container "metadata_store_server" "C++ gRPC server implementing MetadataStoreService. Connects to database backends and exposes metadata CRUD + lineage query APIs" "C++ / gRPC / BoringSSL"
            protobufSchemas = container "Protobuf Schemas" "Protocol Buffer definitions for data model (Artifact, Execution, Context, Event) and service RPC interface" "Protocol Buffers"
            pythonClient = container "ml_metadata Python Library" "Python API client for interacting with the metadata store via direct DB connection or gRPC" "Python / PyPI"
        }

        dsp = softwareSystem "Data Science Pipelines" "RHOAI pipeline orchestrator that deploys MLMD and records pipeline metadata" "Internal RHOAI"
        kfpSdk = softwareSystem "Kubeflow Pipelines SDK" "Pipeline SDK used by pipeline steps to record artifacts, executions, and events" "Internal RHOAI"
        pipelineUI = softwareSystem "Pipeline UI (Dashboard)" "Web UI for visualizing pipeline runs and artifact lineage" "Internal RHOAI"
        mysql = softwareSystem "MySQL / MariaDB" "Relational database for persistent metadata storage" "External Database"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database for persistent metadata storage" "External Database"

        # Relationships
        pipelineEngineer -> pipelineUI "Views pipeline runs and lineage"
        pipelineEngineer -> dsp "Creates pipeline runs"

        dsp -> mlmd "Deploys MLMD server and records metadata" "gRPC/8080"
        kfpSdk -> mlmd "Records artifacts, executions, contexts, events" "gRPC/8080"
        pipelineUI -> mlmd "Queries metadata for visualization" "gRPC/8080"

        mlmd -> mysql "Stores/retrieves metadata" "MySQL protocol/3306"
        mlmd -> postgresql "Stores/retrieves metadata" "PostgreSQL protocol/5432"

        # Container-level relationships
        dsp -> grpcServer "PutExecution, PutArtifacts, PutContexts" "gRPC/8080 Optional TLS/mTLS"
        kfpSdk -> grpcServer "PutExecution, PutArtifacts, PutEvents" "gRPC/8080 Optional TLS/mTLS"
        pipelineUI -> grpcServer "GetLineageSubgraph, GetArtifacts" "gRPC/8080 Optional TLS/mTLS"
        pythonClient -> grpcServer "All MetadataStoreService RPCs" "gRPC/8080"

        grpcServer -> mysql "CRUD operations on metadata tables" "MySQL protocol/3306 Optional TLS"
        grpcServer -> postgresql "CRUD operations on metadata tables" "PostgreSQL protocol/5432 Optional TLS"
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
            element "External Database" {
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
