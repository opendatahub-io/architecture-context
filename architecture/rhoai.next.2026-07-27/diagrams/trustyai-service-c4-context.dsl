workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models and monitors fairness, drift, and explainability"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and monitors model health"

        trustyaiService = softwareSystem "TrustyAI Service" "Python FastAPI service providing AI model fairness metrics, drift detection, explainability, and inference data management" {
            fastapi = container "FastAPI Application" "Main ASGI application serving 87 HTTP endpoints under Uvicorn/Hypercorn" "Python / FastAPI"
            consumerEndpoint = container "Consumer Endpoint" "Ingests KServe v2 and ModelMesh inference payloads, reconciles input/output pairs" "Python / FastAPI Router"
            metricsEngine = container "Metrics Engine" "Computes fairness (SPD, DIR), drift (KS, Jensen-Shannon, Fourier MMD, compare means, mean shift), batch mean, and identity metrics" "Python / scikit-learn / scipy"
            prometheusScheduler = container "Prometheus Scheduler" "Schedules periodic metric computation and publishes results to Prometheus format" "Python / prometheus-client"
            storageInterface = container "Storage Interface" "Abstraction layer over PVC (h5py/HDF5) and MariaDB backends for observation persistence" "Python"
        }

        kserve = softwareSystem "KServe v2" "Standardized model serving with inference protocol v2" "External"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving platform for inference workloads" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External"
        pvcStorage = softwareSystem "PVC Storage" "Persistent Volume Claim with HDF5 file storage via h5py" "External"
        mariadb = softwareSystem "MariaDB" "Optional relational database backend for observation storage" "External"

        # Relationships
        dataScientist -> trustyaiService "Queries fairness/drift metrics, uploads data, requests explanations" "HTTP/HTTPS"
        platformAdmin -> trustyaiService "Monitors model health, configures metric schedules" "HTTP/HTTPS"

        kserve -> trustyaiService "Sends inference payloads via CloudEvents" "HTTP POST / (ce-id header)"
        modelMesh -> trustyaiService "Sends partial input/output payloads" "HTTP POST /consumer/kserve/v2"
        prometheus -> trustyaiService "Scrapes metrics endpoint" "HTTP GET /q/metrics"

        trustyaiService -> pvcStorage "Reads/writes observation data as HDF5 files" "h5py filesystem"
        trustyaiService -> mariadb "Reads/writes observation data (optional)" "MariaDB protocol"

        # Internal container relationships
        fastapi -> consumerEndpoint "Routes ingestion requests"
        fastapi -> metricsEngine "Routes metric computation requests"
        consumerEndpoint -> storageInterface "Persists reconciled observation pairs"
        metricsEngine -> storageInterface "Reads historical observations for computation"
        metricsEngine -> prometheusScheduler "Registers scheduled metrics"
        storageInterface -> pvcStorage "h5py read/write"
        storageInterface -> mariadb "SQL read/write"
    }

    views {
        systemContext trustyaiService "SystemContext" {
            include *
            autoLayout
            description "TrustyAI Service in the context of RHOAI platform components"
        }

        container trustyaiService "Containers" {
            include *
            autoLayout
            description "Internal container architecture of TrustyAI Service"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #999999
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
