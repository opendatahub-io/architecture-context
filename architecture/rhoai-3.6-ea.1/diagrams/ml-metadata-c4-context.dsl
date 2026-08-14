workspace {
    model {
        pipelineComponent = person "Pipeline Component" "ML pipeline step (e.g. Argo workflow task) that records metadata during execution"
        dataScientist = person "Data Scientist" "Queries pipeline metadata and lineage for experiment tracking"

        mlMetadata = softwareSystem "ML Metadata (MLMD)" "gRPC metadata store service that records and retrieves metadata associated with ML workflows, including artifacts, executions, contexts, and their lineage relationships" {
            grpcServer = container "metadata_store_server" "C++ gRPC server implementing MetadataStoreService with ~35 RPCs for CRUD and lineage operations" "C++ / Bazel / gRPC"
            pythonClient = container "ml_metadata Python Package" "Python client bindings for programmatic access to the MLMD gRPC service" "Python"
        }

        mysql = softwareSystem "MySQL / MariaDB" "Relational database backend for persistent metadata storage" "External"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and manages the MLMD server as a companion service alongside pipeline components" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "Orchestrates ML pipeline workflows using Argo/Tekton and records metadata via MLMD" "Internal RHOAI"

        pipelineComponent -> mlMetadata "Records artifacts, executions, contexts, events, and lineage" "gRPC/8080"
        dataScientist -> mlMetadata "Queries metadata and lineage graphs" "gRPC/8080 (via Python client)"
        mlMetadata -> mysql "Persists metadata records" "MySQL/3306 (SSL optional)"
        dspOperator -> mlMetadata "Deploys and configures" "Kubernetes API"
        dsPipelines -> mlMetadata "Writes pipeline run metadata" "gRPC/8080"

        pythonClient -> grpcServer "Sends gRPC requests" "gRPC/8080"
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
