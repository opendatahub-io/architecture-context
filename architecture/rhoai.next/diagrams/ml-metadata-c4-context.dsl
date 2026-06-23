workspace {
    model {
        datascientist = person "Data Scientist" "Runs ML pipelines that produce metadata"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and MLMD deployment"

        mlmd = softwareSystem "ML Metadata (MLMD)" "gRPC server that records and retrieves metadata associated with ML workflows — artifacts, executions, contexts, and lineage relationships" {
            server = container "metadata_store_server" "Main gRPC server binary exposing MetadataStoreService API" "C++ gRPC Service" {
                serviceImpl = component "MetadataStoreServiceImpl" "Handles all gRPC RPCs, creates new DB connection per call" "C++ Class"
                metadataStore = component "metadata_store (core)" "Core metadata store logic — CRUD, transactions, optimistic concurrency control" "C++ Library"
                queryEngine = component "query_engine" "SQL query construction and ZetaSQL filter parsing for flexible metadata queries" "C++ Library"
            }
            pythonLib = container "ml_metadata Python Library" "Client library for interacting with MLMD via Python" "Python/PyPI"
        }

        dsp = softwareSystem "Data Science Pipelines (DSP)" "Primary consumer — orchestrates ML pipeline runs and records metadata" "Internal RHOAI"
        tfx = softwareSystem "TFX / Kubeflow Pipelines" "Legacy pipeline system integration" "External"

        mysql = softwareSystem "MySQL / MariaDB" "Relational database for persistent metadata storage (production)" "External"
        postgresql = softwareSystem "PostgreSQL" "Alternative relational database for persistent metadata storage" "External"

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Upstream proxy for access control in RHOAI deployments" "Internal RHOAI"

        # Relationships
        datascientist -> dsp "Submits ML pipeline runs"
        dsp -> mlmd "Records pipeline metadata (artifacts, executions, events, contexts)" "gRPC/HTTP2 port 8080"
        tfx -> mlmd "Records lineage metadata (legacy)" "gRPC/HTTP2 port 8080"

        mlmd -> mysql "Persists all metadata entities" "MySQL wire protocol port 3306, Optional SSL"
        mlmd -> postgresql "Persists all metadata entities (alternative)" "PostgreSQL wire protocol, Optional SSL"

        kubeRbacProxy -> mlmd "Proxies authenticated requests" "gRPC/HTTP2"

        # Internal relationships
        serviceImpl -> metadataStore "Delegates operations"
        metadataStore -> queryEngine "Parses filter expressions"
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

        component server "Components" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
