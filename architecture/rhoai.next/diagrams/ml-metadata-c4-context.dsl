workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines, queries experiment metadata and artifact lineage"
        platformeng = person "Platform Engineer" "Deploys and configures the Data Science Pipelines stack including MLMD"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server and client library for recording and retrieving metadata associated with ML workflows -- artifacts, executions, contexts, events, and lineage" {
            grpcServer = container "metadata_store_server" "Standalone gRPC server binary exposing MetadataStoreService API (~45 RPCs) for CRUD operations on ML metadata entities" "C++ gRPC Service, Port 8080/TCP"
            protoAPI = container "MetadataStoreService" "Protobuf/gRPC API definition for metadata operations including type management, entity CRUD, event recording, and lineage graph traversal" "Protobuf/gRPC"
            pythonClient = container "ml_metadata Python Client" "Python client with pybind11 C++ bindings for direct DB access or gRPC client connection to the metadata store server" "Python, pybind11"

            grpcServer -> protoAPI "Implements"
            pythonClient -> grpcServer "Connects via gRPC/HTTP2" "gRPC/8080"
        }

        kfp = softwareSystem "Kubeflow Pipelines (KFP)" "Pipeline orchestration engine that records pipeline run metadata through MLMD" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "RHOAI pipeline platform that deploys and manages MLMD as its metadata backend" "Internal RHOAI"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Kubernetes operator that deploys, configures, and manages the DSP stack including MLMD" "Internal RHOAI"
        tfx = softwareSystem "TFX (TensorFlow Extended)" "ML pipeline framework that records component metadata through MLMD" "External"

        mysql = softwareSystem "MySQL / MariaDB" "Relational database for persistent metadata storage" "External"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database for persistent metadata storage" "External"

        # User interactions
        datascientist -> kfp "Creates and runs ML pipelines"
        datascientist -> mlmd "Queries experiment metadata and artifact lineage via KFP SDK" "gRPC/8080"
        platformeng -> dspOperator "Configures DSP stack deployment"

        # Platform interactions
        kfp -> mlmd "Records pipeline artifacts, executions, contexts, events, and lineage" "gRPC/8080"
        dsp -> mlmd "Connects for pipeline run tracking" "gRPC/8080"
        dspOperator -> mlmd "Deploys and configures MLMD server, provides database credentials"
        tfx -> mlmd "Records component metadata through MLMD" "gRPC/8080"

        # Storage
        mlmd -> mysql "Persistent metadata storage" "MySQL/3306, Optional SSL"
        mlmd -> postgresql "Alternative persistent metadata storage" "PostgreSQL/5432, Optional SSL"
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
                shape person
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
