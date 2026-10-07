workspace {
    model {
        datascientist = person "Data Scientist" "Requests fairness and drift metrics for deployed ML models"
        platformadmin = person "Platform Admin" "Monitors AI fairness compliance via dashboards"

        trustyai = softwareSystem "TrustyAI Explainability" "Quarkus-based fairness metrics, drift detection, and model explainability service for OpenShift AI" {
            service = container "explainability-service" "REST API for fairness metrics, drift detection, payload ingestion, and Prometheus metric publishing" "Quarkus 3.20.6.2 (Java 17)"
            core = container "explainability-core" "Core library with fairness metrics (SPD, DIR), drift metrics (KS, MMD), and explainers (LIME, SHAP, CF)" "Java Library"
            connectors = container "explainability-connectors" "KServe v2 gRPC and HTTP client connectors for model inference predictions" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow IPC integration for Java-Python data exchange" "Java Library"

            service -> core "Uses fairness/drift/explainer algorithms"
            service -> connectors "Invokes model predictions via KServe v2"
            service -> arrow "Arrow data exchange (optional)"
        }

        modelmesh = softwareSystem "ModelMesh" "Multi-model serving platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Internal Platform"
        operator = softwareSystem "TrustyAI Service Operator" "Deploys and manages TrustyAI instances per namespace" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "OpenShift AI web console" "Internal RHOAI"

        pvc = softwareSystem "PVC Storage" "Persistent Volume for CSV flat-file inference data" "Infrastructure"
        minio = softwareSystem "MinIO" "S3-compatible object storage" "External (Optional)"
        mariadb = softwareSystem "MariaDB/MySQL" "Relational database for inference data" "External (Optional)"
        k8sapi = softwareSystem "Kubernetes API" "Cluster API server" "Infrastructure"

        # Inbound relationships
        modelmesh -> trustyai "Sends inference payloads" "HTTP/8080 POST /consumer/kserve/v2"
        kserve -> trustyai "Sends inference CloudEvents" "HTTP/8080 Knative Eventing"
        prometheus -> trustyai "Scrapes metrics" "HTTP/8080 GET /q/metrics (Bearer SA token)"
        datascientist -> trustyai "Requests fairness/drift metrics" "HTTP/8080"
        platformadmin -> dashboard "Monitors AI fairness"
        dashboard -> trustyai "Queries metrics" "HTTP/8080"

        # Outbound relationships
        trustyai -> kserve "Invokes model predictions for explainers" "gRPC (plaintext)"
        trustyai -> modelmesh "Invokes model predictions for explainers" "gRPC/HTTP (plaintext)"
        trustyai -> pvc "Stores/reads inference data" "Filesystem (CSV)"
        trustyai -> minio "Stores/reads inference data" "HTTP (Access/Secret Key)"
        trustyai -> mariadb "Stores/reads inference data" "JDBC/3306 (Username/Password)"
        trustyai -> k8sapi "Init container creates ConfigMap" "HTTPS/6443 (SA token)"

        # Lifecycle
        operator -> trustyai "Deploys and configures per namespace"
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
                color #ffffff
            }
            element "External (Optional)" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
