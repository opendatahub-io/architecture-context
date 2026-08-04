workspace {
    model {
        dataScientist = person "Data Scientist" "Requests fairness metrics, explainability results, and drift analysis for deployed ML models"
        mlEngineer = person "ML Engineer" "Deploys and monitors inference services with TrustyAI observability"

        trustyaiService = softwareSystem "TrustyAI Service" "Python FastAPI application providing AI model explainability, fairness metrics, and drift detection for RHOAI" {
            hypercorn = container "Hypercorn ASGI Server" "Serves the FastAPI application with HTTP (loopback) and optional HTTPS listeners" "Python/Hypercorn"
            fastapiApp = container "FastAPI Application" "87 HTTP endpoints for inference ingestion, fairness, drift, explainability, and metrics" "Python/FastAPI"
            consumerEndpoint = container "Inference Consumer" "Receives KServe v2 inference payloads, reconciles input/output pairs by inference ID" "Python"
            metricsCalculator = container "Metrics Calculator" "Background asyncio task computing fairness, drift, and batch-mean metrics on a configurable interval (default 30s)" "Python/asyncio"
            storageInterface = container "Storage Interface" "Pluggable storage abstraction supporting PVC/HDF5 and MariaDB backends" "Python"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Sidecar authenticating requests via Kubernetes RBAC before forwarding to loopback-bound service" "Infrastructure"
        kserve = softwareSystem "KServe / ModelMesh" "Inference platform sending prediction payloads to TrustyAI for monitoring" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection system scraping /q/metrics for fairness and drift metrics" "Infrastructure"
        mariadb = softwareSystem "MariaDB" "Optional relational database backend for inference data storage" "External"
        pvc = softwareSystem "PersistentVolumeClaim" "Default HDF5 file-based storage for inference data" "Infrastructure"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for RBAC validation and service discovery" "Infrastructure"

        # User interactions
        dataScientist -> trustyaiService "Requests fairness/drift metrics and model explanations" "HTTPS/8443 via kube-rbac-proxy"
        mlEngineer -> trustyaiService "Monitors model behavior and configures metric schedules" "HTTPS/8443 via kube-rbac-proxy"

        # External system interactions
        kserve -> trustyaiService "Sends inference payloads to /consumer/kserve/v2" "HTTP/8080 (via proxy)"
        trustyaiService -> mariadb "Stores/retrieves inference data" "MySQL/3306 (optional TLS)"
        trustyaiService -> pvc "Reads/writes HDF5 inference data files" "Filesystem I/O"
        prometheus -> trustyaiService "Scrapes /q/metrics for Prometheus-format metrics" "HTTPS/8443 via kube-rbac-proxy"
        kubeRbacProxy -> kubernetesAPI "Validates ServiceAccount tokens via SubjectAccessReview" "HTTPS/443"
        kubeRbacProxy -> trustyaiService "Forwards authenticated requests to loopback" "HTTP/8080 (127.0.0.1)"

        # Internal container interactions
        hypercorn -> fastapiApp "Serves ASGI application"
        fastapiApp -> consumerEndpoint "Routes /consumer/* requests"
        fastapiApp -> storageInterface "Data access for all endpoints"
        consumerEndpoint -> storageInterface "Stores reconciled inference pairs"
        metricsCalculator -> storageInterface "Reads inference data for metric calculation"
        storageInterface -> pvc "HDF5 file operations (default mode)"
        storageInterface -> mariadb "SQL operations (MariaDB mode)"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
