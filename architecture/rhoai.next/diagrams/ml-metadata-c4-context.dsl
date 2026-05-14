workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines that generate metadata"
        mlEngineer = person "ML Engineer" "Queries lineage and artifact provenance"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server that records and retrieves metadata (artifacts, executions, contexts, lineage) for ML workflows" {
            grpcServer = container "metadata_store_server" "C++ gRPC service exposing MetadataStoreService API (46 RPCs) for metadata CRUD and lineage queries" "C++ / gRPC / HTTP2"
            protoAPI = container "Protocol Buffer Definitions" "Defines data model (Artifact, Execution, Context, Event) and gRPC service interface" "Protocol Buffers"
            pythonClient = container "ml-metadata Python Library" "Python client for interacting with the gRPC server or in-process metadata store" "Python / PyPI"
        }

        dsp = softwareSystem "Data Science Pipelines (DSP)" "Pipeline orchestrator that records pipeline run metadata, artifact provenance, and lineage" "Internal RHOAI"
        pipelinesUI = softwareSystem "Kubeflow Pipelines UI" "Web UI that reads artifact and lineage data for visualization" "Internal RHOAI"
        platformOperator = softwareSystem "Platform Operator" "rhods-operator / opendatahub-operator — deploys and configures MLMD server" "Internal RHOAI"

        mysql = softwareSystem "MySQL / MariaDB" "Relational database for persistent metadata storage (production)" "External"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database for persistent metadata storage" "External"
        certManager = softwareSystem "cert-manager" "Provisions TLS certificates for optional gRPC TLS/mTLS" "External"

        # Relationships
        datascientist -> dsp "Submits ML pipelines"
        mlEngineer -> pipelinesUI "Queries lineage and artifacts"

        dsp -> mlmd "Records pipeline metadata, artifacts, executions, events, lineage" "gRPC/8080"
        pipelinesUI -> mlmd "Reads artifact and lineage data" "gRPC/8080"

        mlmd -> mysql "Persists metadata" "MySQL/3306"
        mlmd -> postgresql "Persists metadata (alternative)" "PostgreSQL/5432"
        platformOperator -> mlmd "Deploys and configures"
        certManager -> mlmd "Provisions TLS certificates" "kubernetes.io/tls"

        # Container-level relationships
        dsp -> grpcServer "PutArtifacts, PutExecutions, PutEvents, PutContexts, PutExecution" "gRPC/8080"
        pipelinesUI -> grpcServer "GetLineageSubgraph, GetArtifactsByContext" "gRPC/8080"
        pythonClient -> grpcServer "MetadataStoreService RPCs" "gRPC/8080"
        grpcServer -> mysql "SQL queries (metadata CRUD)" "MySQL/3306"
        grpcServer -> postgresql "SQL queries (metadata CRUD)" "PostgreSQL/5432"
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
