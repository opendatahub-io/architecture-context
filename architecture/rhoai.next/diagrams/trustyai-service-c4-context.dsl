workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, configures drift/fairness monitoring, reviews explanations"
        platformAdmin = person "Platform Admin" "Deploys and configures TrustyAI Service via operator"

        trustyaiService = softwareSystem "TrustyAI Service" "Python REST API for Responsible AI workflows: drift detection, fairness monitoring, and model explainability" {
            mainApp = container "Main App (API Server)" "FastAPI + Hypercorn on 8081/HTTP (loopback) and 4443/HTTPS. Serves drift, fairness, explainability, info, and metrics endpoints." "Python / FastAPI"
            healthApp = container "Health App (Consumer Server)" "FastAPI + Hypercorn on 8080/HTTP (all interfaces). Health probes and inference data ingestion." "Python / FastAPI"
            scheduler = container "Prometheus Scheduler" "Asyncio background task computing registered metrics every 30s and publishing as Prometheus gauges." "Python / asyncio"
            pvcStorage = container "PVC Storage" "HDF5-based storage for inference data on PersistentVolumeClaims." "h5py" "Database"
            mariadbStorage = container "MariaDB Storage" "Optional database-backed storage with TLS and PVC-to-DB migration." "mariadb connector" "Database"
            featureFlags = container "Feature Flag Registry" "Controls endpoint registration at startup via TRUSTYAI_ENABLE_* env vars." "Python Module"
            tlsConfig = container "PolicyAwareConfig" "Subclasses Hypercorn Config to honor system crypto policy for FIPS compliance." "Python Module"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar authenticating API requests via OAuth Bearer tokens" "External"
        trustyaiOperator = softwareSystem "TrustyAI Operator" "Deploys and configures TrustyAI Service instances per namespace" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Inference service platform sending CloudEvents to TrustyAI" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Model serving sending KServe v2 payloads via agent" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Scrapes computed drift and fairness metrics" "External"
        mariadb = softwareSystem "MariaDB" "Optional external database for inference data storage" "External"

        # Relationships
        dataScientist -> kubeRbacProxy "Requests metrics/explanations via" "HTTPS / OAuth Bearer"
        kubeRbacProxy -> mainApp "Forwards authenticated requests to" "HTTP/8081 (loopback)"
        kserve -> healthApp "Sends inference CloudEvents to" "HTTP/8080"
        modelMesh -> healthApp "Sends KServe v2 payloads to" "HTTP/8080"
        prometheus -> kubeRbacProxy "Scrapes /q/metrics via" "HTTP"
        platformAdmin -> trustyaiOperator "Configures TrustyAI via" "TrustyAIService CR"
        trustyaiOperator -> trustyaiService "Deploys and manages" "Kubernetes API"

        healthApp -> pvcStorage "Stores inference data in" "File I/O"
        healthApp -> mariadbStorage "Stores inference data in" "SQL"
        mainApp -> pvcStorage "Reads inference data from" "File I/O"
        mainApp -> mariadbStorage "Reads inference data from" "SQL"
        scheduler -> pvcStorage "Reads data for metric computation" "File I/O"
        scheduler -> mariadbStorage "Reads data for metric computation" "SQL"
        scheduler -> mainApp "Publishes Prometheus gauges to" "In-memory"
        mariadbStorage -> mariadb "Connects to" "MySQL/3306 TLS optional"
        featureFlags -> mainApp "Gates endpoint registration" "Startup config"
        tlsConfig -> mainApp "Configures TLS" "System crypto policy"
    }

    views {
        systemContext trustyaiService "SystemContext" {
            include *
            autoLayout
        }

        container trustyaiService "Containers" {
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
            element "Database" {
                shape Cylinder
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
