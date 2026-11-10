workspace {
    model {
        user = person "Data Scientist / ODH Dashboard user" "Registers fairness and drift metric requests and views model bias"

        trustyai = softwareSystem "TrustyAI Service" "Python FastAPI/Hypercorn service that ingests inference payloads, stores them and publishes fairness/drift metrics to Prometheus" {
            mainApp = container "Main app" "REST API: metric registration/compute, metadata, data upload, /q/metrics. 127.0.0.1:8081 HTTP and 0.0.0.0:4443 HTTPS" "Python FastAPI on Hypercorn"
            healthApp = container "health_app" "Kubelet probes and KServe/ModelMesh ingest on 0.0.0.0:8080 HTTP (no auth)" "Python FastAPI on Hypercorn"
            scheduler = container "Prometheus scheduler" "Recomputes registered metrics every 30s and updates gauges" "asyncio background task"
            storage = container "Storage layer" "Pluggable persistence: PVC HDF5, MariaDB, PostgreSQL, SQLite" "h5py / SQLAlchemy / mariadb / psycopg"
            migrate = container "trustyai-migrate" "One-shot migration of legacy Java-service data to canonical SQL schema" "Python CLI"
            proxy = container "kube-rbac-proxy" "Sidecar providing authenticated access to 127.0.0.1:8081 (provisioned by operator)" "Sidecar"
        }

        operator = softwareSystem "trustyai-service-operator" "Deploys the service, sidecar, Services, Route, TLS certs, DB secrets, ServiceMonitor" "Internal RHOAI"
        kserve = softwareSystem "KServe" "InferenceService logger pushes CloudEvents" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "Payload processor pushes request/response parts" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "UI for bias/drift metric configuration" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / User Workload Monitoring" "Scrapes trustyai_* gauges" "Internal RHOAI"
        mariadb = softwareSystem "MariaDB" "Optional database storage" "External"
        postgres = softwareSystem "PostgreSQL" "Optional database storage" "External"
        pvc = softwareSystem "PVC" "HDF5 file storage" "External"

        user -> dashboard "Uses"
        dashboard -> proxy "REST via OpenShift Route" "HTTPS/443 Bearer token"
        user -> proxy "REST via OpenShift Route" "HTTPS/443 Bearer token"
        proxy -> mainApp "Proxies authorized requests" "HTTP/8081 loopback"
        kserve -> healthApp "POST / CloudEvents" "HTTP/8080 no auth"
        modelmesh -> healthApp "POST /consumer/kserve/v2" "HTTP/8080 no auth"
        prometheus -> mainApp "Scrapes /q/metrics" "HTTPS/4443"
        operator -> trustyai "Deploys and configures via env vars and mounts"
        mainApp -> scheduler "Registers metric requests"
        scheduler -> storage "Reads inference data"
        healthApp -> storage "Persists joined rows"
        mainApp -> storage "Data upload, metadata"
        storage -> mariadb "SQL" "MariaDB/3306 TLS if CA mounted"
        storage -> postgres "SQL" "PostgreSQL/5432 verify-full if CA mounted"
        storage -> pvc "HDF5 file I/O"
        migrate -> mariadb "Reads legacy tables / writes canonical schema" "3306 TLS if CA"
        migrate -> postgres "Writes canonical schema" "5432 TLS if CA"
        migrate -> pvc "Reads legacy HDF5/CSV"
    }

    views {
        systemContext trustyai "SystemContext" {
            include *
            autoLayout
        }

        container trustyai "Containers" {
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
            element "Container" {
                background #4a90e2
            }
        }
    }
}
