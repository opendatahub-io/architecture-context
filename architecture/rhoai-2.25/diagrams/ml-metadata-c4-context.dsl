workspace {
    model {
        dspController = person "DSP Pipeline Controller" "Orchestrates ML pipeline runs and records metadata"
        dataScientist = person "Data Scientist" "Views pipeline lineage and metadata via DSP UI/SDK"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC service for recording, retrieving, and querying ML workflow metadata (artifacts, executions, contexts, lineage)" {
            grpcServer = container "metadata_store_server" "Standalone gRPC server exposing MetadataStoreService API" "C++ gRPC Server" {
                serviceImpl = component "MetadataStoreServiceImpl" "Handles all gRPC RPCs with per-RPC database connections" "C++"
            }
            pythonClient = container "ml_metadata (Python)" "Python SDK with gRPC client and direct DB access modes" "Python Library"
            pybindModule = container "pywrap/metadata_store_extension" "Native Python extension for direct DB connections" "C++ pybind11"
            goBindings = container "Go SWIG Bindings" "Go language bindings for metadata store access" "Go SWIG"
        }

        mysql = softwareSystem "MySQL / MariaDB" "Primary persistent metadata storage backend in RHOAI" "External Database"
        postgresql = softwareSystem "PostgreSQL" "Alternative persistent metadata storage backend" "External Database"
        dspOperator = softwareSystem "data-science-pipelines-operator" "Deploys and configures MLMD as part of DSP stack" "Internal RHOAI"
        dspUI = softwareSystem "DSP UI / Pipeline SDK" "Pipeline visualization and provenance tracking" "Internal RHOAI"

        # Relationships
        dspController -> mlmd "Records pipeline artifacts, executions, events, lineage" "gRPC/HTTP2 8080/TCP"
        dataScientist -> dspUI "Views pipeline lineage and metadata"
        dspUI -> mlmd "Queries metadata and lineage graphs" "gRPC/HTTP2 8080/TCP"
        mlmd -> mysql "Stores/retrieves all metadata" "MySQL protocol 3306/TCP"
        mlmd -> postgresql "Stores/retrieves all metadata (alternative)" "PostgreSQL protocol 5432/TCP"
        dspOperator -> mlmd "Deploys and configures" "Kubernetes API"

        # Container-level relationships
        dspController -> grpcServer "PutExecution, PutArtifacts, PutEvents" "gRPC/HTTP2 8080/TCP"
        dspUI -> grpcServer "GetLineageSubgraph, GetArtifactsByContext" "gRPC/HTTP2 8080/TCP"
        grpcServer -> mysql "INSERT/SELECT metadata" "MySQL 3306/TCP Optional TLS"
        grpcServer -> postgresql "INSERT/SELECT metadata" "PostgreSQL 5432/TCP Optional TLS"
        pythonClient -> grpcServer "gRPC client mode" "gRPC/HTTP2 8080/TCP"
        pythonClient -> pybindModule "Direct DB mode" "In-process"
        pybindModule -> mysql "Direct connection" "MySQL 3306/TCP"
        pybindModule -> postgresql "Direct connection" "PostgreSQL 5432/TCP"
    }

    views {
        systemContext mlmd "SystemContext" {
            include *
            autoLayout
            description "ML Metadata system context showing clients and storage backends"
        }

        container mlmd "Containers" {
            include *
            autoLayout
            description "ML Metadata internal containers: gRPC server, client libraries"
        }

        component grpcServer "Components" {
            include *
            autoLayout
            description "MLMD gRPC server internal components"
        }

        styles {
            element "External Database" {
                background #f5a623
                shape Cylinder
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Software System" {
                background #4a90e2
            }
            element "Container" {
                background #4a90e2
            }
            element "Component" {
                background #4a90e2
            }
            element "Person" {
                background #08427b
                shape Person
            }
        }
    }
}
