workspace {
    model {
        datascientist = person "Data Scientist" "Runs ML pipelines and views lineage"
        platformadmin = person "Platform Admin" "Deploys and configures RHOAI platform"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server that records and retrieves metadata associated with ML workflows, tracking artifacts, executions, contexts, and lineage" {
            grpcServer = container "metadata_store_server" "Main gRPC server binary providing metadata storage and retrieval API" "C++ gRPC Service"
            serviceImpl = container "MetadataStoreServiceImpl" "Implements the MetadataStoreService gRPC interface with database backends" "C++ gRPC Implementation"
            pythonClient = container "ml-metadata Python Library" "Python client for interacting with the metadata store" "Python Client Library"
        }

        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and manages the DSP stack including MLMD" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Orchestrates ML pipeline execution" "Internal RHOAI"
        kubeflowUI = softwareSystem "Kubeflow Pipelines UI" "Web UI for pipeline visualization and lineage" "Internal RHOAI"

        mysql = softwareSystem "MySQL / MariaDB" "Relational database for persistent metadata storage" "External Database"
        postgresql = softwareSystem "PostgreSQL" "Relational database for persistent metadata storage" "External Database"

        # Relationships
        datascientist -> kubeflowUI "Views pipeline runs and lineage"
        datascientist -> kubeflowPipelines "Submits ML pipelines"
        platformadmin -> dspOperator "Configures DSP stack"

        dspOperator -> mlmd "Deploys MLMD container as part of DSP stack"
        kubeflowPipelines -> mlmd "Records pipeline metadata, artifacts, executions, lineage" "gRPC/8080"
        kubeflowUI -> mlmd "Retrieves metadata for pipeline visualization" "gRPC/8080 (via backend)"

        mlmd -> mysql "Stores metadata records" "MySQL Protocol/3306"
        mlmd -> postgresql "Stores metadata records" "PostgreSQL Protocol/5432"
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
            element "External Database" {
                background #f5a623
                color #333333
                shape Cylinder
            }
            element "Internal RHOAI" {
                background #7ed321
                color #333333
            }
            element "Software System" {
                background #4a90e2
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
        }
    }
}
