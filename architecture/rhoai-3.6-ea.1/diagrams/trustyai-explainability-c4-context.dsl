workspace {
    model {
        datascientist = person "Data Scientist" "Requests fairness and drift metrics for deployed ML models"
        platformAdmin = person "Platform Admin" "Deploys and manages TrustyAI service alongside model serving"

        trustyai = softwareSystem "TrustyAI Explainability Service" "Quarkus-based Java service providing model fairness monitoring, data drift detection, and explainability for ML models on RHOAI" {
            initContainer = container "Init Container" "Creates model-serving-config ConfigMap to configure ModelMesh payload forwarding" "Shell/oc CLI"
            quarkusApp = container "Quarkus Application" "Hosts REST endpoints for fairness metrics, drift detection, payload ingestion, and Prometheus metrics export" "Java/Quarkus 3.8"
            pvcStorage = container "PVC Storage" "Stores inference input/output data at /inputs for subsequent analysis" "PersistentVolumeClaim" "Database"
        }

        kserveModelMesh = softwareSystem "KServe/ModelMesh" "Model serving infrastructure that forwards inference payloads to TrustyAI" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring platform" "Internal RHOAI"
        mariadb = softwareSystem "MariaDB/MySQL" "Optional relational database for inference data persistence (disabled by default)" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external HTTP access via Route" "Platform"

        # User interactions
        datascientist -> trustyai "Requests fairness/drift metrics via REST API" "HTTP/80"
        platformAdmin -> trustyai "Deploys and configures TrustyAI service"

        # System interactions
        kserveModelMesh -> quarkusApp "Forwards inference input/output payloads" "HTTP POST /consumer/kserve/v2 on port 8080"
        prometheus -> quarkusApp "Scrapes metrics endpoint" "HTTP GET /q/metrics on port 8080"
        quarkusApp -> pvcStorage "Reads/writes inference data" "Filesystem /inputs"
        quarkusApp -> mariadb "Persists data via JDBC (optional, disabled by default)" "JDBC"
        initContainer -> kserveModelMesh "Configures payload forwarding via ConfigMap" "oc apply"

        openshiftRouter -> trustyai "Routes external HTTP traffic" "HTTP port 80 -> 8080"
        datascientist -> openshiftRouter "Accesses TrustyAI endpoints" "HTTP (no TLS)"
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
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #d79b00
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
        }
    }
}
