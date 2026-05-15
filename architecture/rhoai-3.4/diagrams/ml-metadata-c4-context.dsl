workspace {
    model {
        pipelineEngineer = person "Pipeline Engineer" "Builds and runs ML pipelines using Kubeflow Pipelines SDK"
        dataScientist = person "Data Scientist" "Views pipeline run history, artifact lineage, and experiment results"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC metadata store for recording and retrieving ML pipeline metadata: artifacts, executions, contexts, events, and lineage" {
            grpcServer = container "metadata_store_server" "Stateless C++ gRPC server implementing MetadataStoreService API (~50 RPC methods)" "C++ / gRPC / BoringSSL" "Server"
            pythonClient = container "ml_metadata (Python)" "Python client library providing gRPC client and direct DB access modes" "Python / pybind11" "Library"
            protoDefinitions = container "Proto Definitions" "Protobuf data model: Artifact, Execution, Context, Event types and MetadataStoreService API" "Protocol Buffers" "Schema"
        }

        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and configures the MLMD server as part of the DSP stack" "Internal RHOAI"
        dspBackend = softwareSystem "Data Science Pipelines Backend" "Pipeline orchestration backend that records pipeline run metadata" "Internal RHOAI"
        dspUI = softwareSystem "Data Science Pipelines UI" "Web dashboard for viewing pipeline runs, artifacts, and lineage" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Relational database for persistent metadata storage (primary backend in RHOAI)" "External"
        pipelineRunner = softwareSystem "Pipeline Runner (Argo/Tekton)" "Executes pipeline steps which record metadata via Python SDK" "Internal RHOAI"

        # Relationships
        pipelineEngineer -> dspUI "Views pipeline runs and lineage"
        pipelineEngineer -> pythonClient "Records metadata from pipeline code"

        dataScientist -> dspUI "Explores experiment history and artifact lineage"

        dspOperator -> grpcServer "Deploys and configures" "Kubernetes API"
        dspBackend -> grpcServer "Records/queries pipeline metadata" "gRPC/8080"
        dspUI -> dspBackend "Queries metadata via backend" "REST API"
        pipelineRunner -> grpcServer "Records step metadata via SDK" "gRPC/8080"
        pythonClient -> grpcServer "Client library calls" "gRPC/8080"

        grpcServer -> postgresql "Stores/retrieves all metadata" "TCP/5432 Optional SSL"

        protoDefinitions -> grpcServer "Defines API contract"
        protoDefinitions -> pythonClient "Defines data model"
    }

    views {
        systemContext mlmd "SystemContext" {
            include *
            autoLayout
            description "ML Metadata system context showing clients, deployer, and database backend"
        }

        container mlmd "Containers" {
            include *
            autoLayout
            description "ML Metadata internal components: gRPC server, Python client, proto definitions"
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Server" {
                shape Hexagon
                background #4a90e2
                color #ffffff
            }
            element "Library" {
                shape Component
                background #85bbf0
                color #000000
            }
            element "Schema" {
                shape Folder
                background #6c5ce7
                color #ffffff
            }
        }
    }
}
