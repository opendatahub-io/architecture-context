workspace {
    model {
        datascientist = person "Data Scientist" "Configures fairness metrics, drift detection, and explainability for ML models"
        mlops = person "MLOps Engineer" "Deploys and monitors ML model serving infrastructure"

        trustyaiService = softwareSystem "TrustyAI Service" "AI model explainability, fairness metrics, and data drift detection service for RHOAI" {
            fastapi = container "FastAPI Application" "Python FastAPI application with 87 HTTP endpoints for metrics, explainers, and data consumption" "Python / FastAPI"
            hypercorn = container "Hypercorn Server" "HTTP/2-capable ASGI server binding HTTP on loopback and optional HTTPS on 4443" "Python / Hypercorn"
            prometheusScheduler = container "Prometheus Scheduler" "Background asyncio task computing fairness and drift metrics on configurable interval (default 30s)" "Python / asyncio"
            storageBackend = container "Storage Backend" "Pluggable persistence layer supporting HDF5/PVC (default) or MariaDB" "Python"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar proxy providing OpenShift RBAC authentication via SubjectAccessReview" "Sidecar"
        modelServing = softwareSystem "ModelMesh / KServe" "Model serving infrastructure sending inference payloads for monitoring" "Internal RHOAI"
        mariadb = softwareSystem "MariaDB" "Optional relational database for persistent observation storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting system" "External"
        pvcStorage = softwareSystem "PVC Storage" "Kubernetes Persistent Volume Claim for HDF5 file storage" "Infrastructure"

        # Relationships
        datascientist -> trustyaiService "Configures metrics and requests explainability via REST API"
        mlops -> trustyaiService "Monitors model fairness and drift via Prometheus dashboards"

        kubeRbacProxy -> fastapi "Forwards authenticated HTTP requests to 127.0.0.1:8080"
        modelServing -> kubeRbacProxy "POST /consumer/kserve/v2 (KServe v2 inference payloads)"
        datascientist -> kubeRbacProxy "REST API calls (metrics, explainers, info)"

        hypercorn -> fastapi "Serves ASGI application"
        fastapi -> storageBackend "Reads/writes inference observations"
        prometheusScheduler -> storageBackend "Reads observations for metric computation"
        prometheusScheduler -> fastapi "Publishes computed metrics as Prometheus gauges"

        storageBackend -> pvcStorage "Writes HDF5 files (default mode)"
        storageBackend -> mariadb "SQL queries via MariaDB connector (optional, TCP/3306, optional TLS)"

        prometheus -> kubeRbacProxy "GET /q/metrics (scrapes Prometheus metrics)"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Sidecar" {
                background #f5a623
                color #000000
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
