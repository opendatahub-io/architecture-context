workspace {
    model {
        dataScientist = person "Data Scientist" "Runs pipelines and views artifact lineage in the DSP UI"

        mlmd = softwareSystem "ML Metadata (odh-mlmd-grpc-server)" "Stateless gRPC service recording ML lineage metadata (artifacts, executions, contexts, events)" {
            server = container "metadata_store_server" "Serves ml_metadata.MetadataStoreService on 8080/TCP; plaintext and unauthenticated by default" "C++ gRPC (Bazel), BoringSSL"
            store = container "MetadataStoreServiceImpl / MetadataStore" "Put/Get RPCs, schema init and migration" "C++ library"
            sources = container "RDBMS Metadata Sources" "MySQL/MariaDB, PostgreSQL, SQLite / in-memory fake backends" "C++ library"
            pyClient = container "ml_metadata Python client" "pybind11 + gRPC client library (not shipped in this release)" "Python" "NotShipped"
        }

        dspo = softwareSystem "Data Science Pipelines Operator" "Deploys the MLMD image per DSPA and supplies DB flags (inferred)" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "KFP v2 driver/launcher, API server; records and queries lineage (inferred)" "Internal RHOAI"
        envoy = softwareSystem "metadata-envoy / DSP UI" "gRPC-Web to gRPC proxy for lineage visualization (inferred)" "Internal RHOAI"
        mysql = softwareSystem "MySQL / MariaDB" "Primary metadata persistence (DSPA MariaDB or external)" "External"
        postgres = softwareSystem "PostgreSQL" "Alternative metadata persistence (no TLS available)" "External"
        konflux = softwareSystem "Konflux / konflux-central" "Builds multi-arch odh-mlmd-grpc-server-rhel9 image" "Internal RHOAI"

        dataScientist -> envoy "Views lineage" "HTTPS"
        dspo -> server "Deploys and configures" "Kubernetes"
        dsp -> server "Records executions and artifacts" "gRPC/8080, plaintext by default"
        envoy -> server "Queries lineage graphs" "gRPC/8080, plaintext by default"
        server -> store "Dispatches RPCs"
        store -> sources "Reads/writes metadata"
        sources -> mysql "Persists metadata" "MySQL wire/3306, optional TLS"
        sources -> postgres "Persists metadata (alternative)" "PostgreSQL wire/5432, no TLS"
        pyClient -> server "Connects (optional)" "gRPC"
        konflux -> mlmd "Builds image" "Tekton"
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
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "NotShipped" {
                background #e8e8e8
                border dashed
            }
        }
    }
}
