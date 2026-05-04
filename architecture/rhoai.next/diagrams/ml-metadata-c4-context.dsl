workspace {
    model {
        pipelineOrchestrator = person "Pipeline Orchestrator" "Data Science Pipelines (DSP) — records pipeline run metadata, artifact provenance, and lineage"
        dataScientist = person "Data Scientist" "Views lineage and artifact metadata through Kubeflow Pipelines UI"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server that records and retrieves metadata (artifacts, executions, contexts, lineage) for ML workflows" {
            grpcServer = container "metadata_store_server" "C++ gRPC server exposing MetadataStoreService (46 RPCs) for metadata CRUD and lineage queries" "C++ / gRPC / UBI9"
            protoDefs = container "Protocol Buffer Definitions" "Proto files defining the metadata data model (Artifact, Execution, Context, Event) and gRPC service interface" "Protobuf"
            pythonClient = container "ml-metadata Python Library" "Python client for interacting with the gRPC server or in-process metadata store" "Python / PyPI"
        }

        dsp = softwareSystem "Data Science Pipelines" "Pipeline orchestrator that uses MLMD to store pipeline run metadata and lineage" "Internal RHOAI"
        kfUI = softwareSystem "Kubeflow Pipelines UI" "Web UI that reads artifact and lineage data from MLMD for visualization" "Internal RHOAI"
        mysql = softwareSystem "MySQL / MariaDB" "Relational database backend for persistent metadata storage (production)" "External"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database backend for persistent metadata storage" "External"
        platformOperator = softwareSystem "Platform Operator" "rhods-operator / opendatahub-operator — deploys and manages MLMD server as part of DSP stack" "Internal RHOAI"

        # Relationships
        pipelineOrchestrator -> dsp "Submits pipeline runs"
        dataScientist -> kfUI "Views lineage and artifacts"

        dsp -> mlmd "Records pipeline metadata, artifacts, executions, events, lineage" "gRPC/HTTP2 on 8080/TCP"
        kfUI -> mlmd "Queries artifact and lineage data for visualization" "gRPC/HTTP2 on 8080/TCP"
        mlmd -> mysql "Persists metadata (production backend)" "MySQL protocol on 3306/TCP"
        mlmd -> postgresql "Persists metadata (alternative backend)" "PostgreSQL protocol on 5432/TCP"
        platformOperator -> mlmd "Deploys and configures MLMD server" "Kubernetes API"

        # Container-level relationships
        dsp -> grpcServer "PutExecution, PutArtifacts, PutEvents, etc." "gRPC/HTTP2 on 8080/TCP"
        kfUI -> grpcServer "GetLineageSubgraph, GetArtifactsByContext, etc." "gRPC/HTTP2 on 8080/TCP"
        grpcServer -> mysql "INSERT/UPDATE/SELECT metadata" "MySQL on 3306/TCP, Optional SSL"
        grpcServer -> postgresql "INSERT/UPDATE/SELECT metadata" "PostgreSQL on 5432/TCP, Optional SSL"
        protoDefs -> grpcServer "Defines API interface"
        protoDefs -> pythonClient "Generates client stubs"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
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
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
