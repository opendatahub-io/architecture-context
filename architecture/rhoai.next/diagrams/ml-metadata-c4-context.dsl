workspace {
    model {
        pipelineOrchestrator = person "Pipeline Orchestrator" "Data Science Pipelines (DSP) — records pipeline run metadata, artifact provenance, and lineage"
        dataScientist = person "Data Scientist" "Runs ML pipelines and views lineage in the UI"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server that records and retrieves metadata (artifacts, executions, contexts, lineage) for ML workflows" {
            grpcServer = container "metadata_store_server" "Stateless gRPC server exposing MetadataStoreService (46 RPCs) for metadata CRUD and lineage queries" "C++ gRPC Service"
            protoDefs = container "Protocol Buffer Definitions" "Proto files defining metadata data model (Artifact, Execution, Context, Event) and gRPC service interface" "Protobuf Schema"
        }

        dsp = softwareSystem "Data Science Pipelines (DSP)" "Pipeline orchestrator that manages ML workflow execution" "Internal RHOAI"
        kfUI = softwareSystem "Kubeflow Pipelines UI" "Web UI for viewing pipeline runs, artifacts, and lineage graphs" "Internal RHOAI"
        pythonClient = softwareSystem "ml-metadata Python Library" "Python client for interacting with MLMD gRPC server" "Client Library"

        mysql = softwareSystem "MySQL / MariaDB" "Relational database for persistent metadata storage (production)" "External Database"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database for persistent metadata storage" "External Database"

        platformOperator = softwareSystem "Platform Operator" "rhods-operator / opendatahub-operator — deploys and manages MLMD server" "Internal RHOAI"

        # Relationships
        pipelineOrchestrator -> dsp "Triggers pipeline runs"
        dataScientist -> kfUI "Views pipeline lineage and artifacts"

        dsp -> mlmd "Records metadata via gRPC" "gRPC/HTTP2 on 8080/TCP, Optional TLS/mTLS"
        kfUI -> mlmd "Queries artifacts and lineage via gRPC" "gRPC/HTTP2 on 8080/TCP, Optional TLS"
        pythonClient -> mlmd "Interacts with metadata store" "gRPC/HTTP2 on 8080/TCP"

        mlmd -> mysql "Stores/retrieves metadata" "MySQL protocol on 3306/TCP, Optional SSL, Username/Password"
        mlmd -> postgresql "Stores/retrieves metadata" "PostgreSQL protocol on 5432/TCP, Optional SSL, Username/Password"

        platformOperator -> mlmd "Deploys and configures" "Kubernetes API"
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
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Client Library" {
                background #50e3c2
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
