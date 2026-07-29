workspace {
    model {
        datascientist = person "Data Scientist" "Runs ML pipelines that produce metadata"
        platformadmin = person "Platform Admin" "Deploys and configures RHOAI components"

        mlmetadata = softwareSystem "ML Metadata (MLMD)" "gRPC metadata store server that tracks artifacts, executions, contexts, and lineage for ML pipelines" {
            server = container "metadata_store_server" "C++ gRPC binary hosting MetadataStoreService with ~45 RPCs for metadata CRUD and lineage queries" "C++ / gRPC"
            pythonclient = container "Python Client Library" "MetadataStore class providing programmatic access to the metadata store" "Python"
        }

        dsp = softwareSystem "Data Science Pipelines" "Orchestrates ML workflows and pipeline executions" "Internal RHOAI"
        mysql = softwareSystem "MySQL" "Relational database for persistent metadata storage" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for persistent metadata storage" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        # Relationships
        datascientist -> dsp "Submits ML pipelines"
        dsp -> mlmetadata "Records pipeline metadata via gRPC" "gRPC/8080"
        pythonclient -> server "Connects to metadata store" "gRPC/8080"
        server -> mysql "Persists metadata" "MySQL Protocol/3306"
        server -> postgresql "Persists metadata" "PostgreSQL Protocol/5432"
        platformadmin -> kubernetes "Deploys ml-metadata server"
        kubernetes -> server "Manages container lifecycle"
    }

    views {
        systemContext mlmetadata "SystemContext" {
            include *
            autoLayout
        }

        container mlmetadata "Containers" {
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
                background #4a90e2
                color #ffffff
            }
        }
    }
}
