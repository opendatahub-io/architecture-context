workspace {
    model {
        pipelineComponent = person "Pipeline Component" "Data Science Pipelines driver that records metadata during pipeline execution"
        pipelineUser = person "Pipeline UI User" "Views pipeline run metadata and lineage graphs"

        mlmd = softwareSystem "ML Metadata" "gRPC server for recording and retrieving metadata associated with ML workflows — artifacts, executions, contexts, and lineage" {
            server = container "metadata_store_server" "C++ gRPC server exposing MetadataStoreService (~45 RPCs) for persistent metadata storage" "C++ / gRPC / Bazel"
            serviceImpl = container "MetadataStoreServiceImpl" "Thread-safe gRPC service implementation that delegates to MetadataStore backend" "C++ Service"
            metadataStore = container "MetadataStore" "Core storage abstraction supporting MySQL, PostgreSQL, SQLite backends" "C++ Storage Layer"
        }

        dsp = softwareSystem "Data Science Pipelines" "RHOAI pipeline orchestration system" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Upstream pipeline orchestration" "Internal ODH"
        postgresql = softwareSystem "PostgreSQL" "Relational database for persistent metadata storage" "External"
        mysql = softwareSystem "MySQL" "Alternative relational database backend" "External"
        pipelineUI = softwareSystem "Pipeline UI" "Web interface for viewing pipeline runs and lineage" "Internal RHOAI"

        pipelineComponent -> mlmd "Records artifacts, executions, contexts, events" "gRPC/8080"
        pipelineUser -> pipelineUI "Views pipeline metadata and lineage"
        pipelineUI -> mlmd "Queries metadata and lineage graphs" "gRPC/8080"
        dsp -> mlmd "Stores pipeline run metadata and artifact lineage" "gRPC/8080"
        kubeflowPipelines -> mlmd "Stores pipeline run metadata" "gRPC/8080"
        mlmd -> postgresql "Persists metadata (types, entities, events, lineage)" "PostgreSQL/5432"
        mlmd -> mysql "Persists metadata (alternative backend)" "MySQL/3306"

        server -> serviceImpl "Delegates RPC calls"
        serviceImpl -> metadataStore "Storage operations"
        metadataStore -> postgresql "SQL queries" "PostgreSQL/5432"
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
            }
            element "Internal ODH" {
                background #7ed321
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
