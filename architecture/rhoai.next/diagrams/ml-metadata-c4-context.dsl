workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines that produce metadata"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and pipeline infrastructure"

        mlmd = softwareSystem "ML Metadata (MLMD)" "Records and retrieves metadata for ML workflows: artifacts, executions, contexts, events, and lineage" {
            grpcServer = container "metadata_store_server" "Standalone gRPC server exposing MetadataStoreService API (42 RPCs) on port 8080. Supports type management, node CRUD, edge management, atomic operations, and graph queries." "C++ gRPC Service"
            protoDefinitions = container "Proto Definitions" "Defines data model (Artifact, Execution, Context, Event) and MetadataStoreService gRPC API" "Protocol Buffers"
            pythonClient = container "ml_metadata Python SDK" "Python client library providing MetadataStore class for direct DB or gRPC access" "Python Library"
            pywrapExtension = container "pywrap Extension" "Native C++ extension enabling direct database access from Python without gRPC" "C++ pybind11 Extension"
        }

        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "RHOAI wrapper around Kubeflow Pipelines" "Internal RHOAI"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and manages MLMD server, services, and configuration" "Internal RHOAI"
        kubeflowUI = softwareSystem "Kubeflow Pipelines UI" "Web UI for experiment visualization, artifact inspection, and lineage display" "Internal RHOAI"
        tfx = softwareSystem "TFX (TensorFlow Extended)" "Original upstream consumer for TFX pipeline component metadata" "External"

        postgresql = softwareSystem "PostgreSQL" "Persistent storage for all metadata (types, artifacts, executions, contexts, events, lineage)" "External Database"
        mysql = softwareSystem "MySQL/MariaDB" "Alternative persistent metadata storage backend" "External Database"

        # Relationships
        datascientist -> kubeflowPipelines "Defines and triggers ML pipelines"
        datascientist -> kubeflowUI "Views experiment results and lineage"

        kubeflowPipelines -> mlmd "Records pipeline execution metadata, artifacts, and lineage" "gRPC/8080, Optional TLS/mTLS"
        dataSciencePipelines -> mlmd "Records metadata via Kubeflow Pipelines" "gRPC/8080, Optional TLS/mTLS"
        kubeflowUI -> mlmd "Queries metadata for visualization and lineage display" "gRPC/8080, Optional TLS/mTLS"
        tfx -> mlmd "Records TFX pipeline component metadata" "gRPC/8080, Optional TLS/mTLS"

        dspOperator -> mlmd "Deploys and manages MLMD gRPC server" "Kubernetes API"

        mlmd -> postgresql "Stores and retrieves all metadata" "PostgreSQL/5432, Optional TLS"
        mlmd -> mysql "Stores and retrieves all metadata (alternative)" "MySQL/3306, Optional TLS"

        # Internal container relationships
        pythonClient -> grpcServer "Sends gRPC requests" "gRPC/8080"
        pythonClient -> pywrapExtension "Uses for direct DB access" "In-process call"
        protoDefinitions -> grpcServer "Defines API contract"
        pywrapExtension -> postgresql "Direct database queries" "PostgreSQL/5432"

        platformadmin -> dspOperator "Configures pipeline infrastructure"
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
            element "External Database" {
                background #f5a623
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
