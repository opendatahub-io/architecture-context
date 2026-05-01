workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and monitors fairness/drift metrics"
        mlEngineer = person "ML Engineer" "Deploys models and configures inference pipelines"

        trustyai = softwareSystem "TrustyAI Explainability" "Quarkus-based REST service providing AI explainability (SHAP, LIME, CF), fairness metrics (SPD, DIR), and drift detection (KS, MMD, Meanshift)" {
            service = container "explainability-service" "Primary REST service exposing 50+ HTTP endpoints for metrics, explanations, and data management" "Quarkus 3.8.5 / Java 17"
            core = container "explainability-core" "Core XAI algorithms, fairness metrics, drift detection, and data models" "Java Library"
            connectors = container "explainability-connectors" "KServe V1/V2 HTTP and gRPC prediction provider clients" "Java Library + Protobuf"
            arrow = container "explainability-arrow" "Apache Arrow IPC serialization for Java-Python data exchange" "Java Library"
            authProxy = container "Auth Proxy Sidecar" "Authenticates incoming requests before forwarding to service" "kube-rbac-proxy / oauth-proxy"
        }

        modelMesh = softwareSystem "ModelMesh Serving" "Serves ML models and routes inference payloads to consumers" "Internal RHOAI"
        kserveModels = softwareSystem "KServe Model Servers" "KServe V1/V2 compatible model inference servers" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        grafana = softwareSystem "Grafana / Dashboard" "Visualization of fairness and drift metrics" "Internal Platform"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI service lifecycle via CRDs" "Internal RHOAI"

        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for inference data persistence" "External (optional)"
        minio = softwareSystem "MinIO" "S3-compatible object storage for inference data" "External (optional)"

        # User interactions
        dataScientist -> trustyai "Requests fairness metrics, drift reports, and explanations" "REST/HTTP 80/TCP"
        mlEngineer -> trustyaiOperator "Configures TrustyAI instance per namespace" "kubectl / CRD"

        # Internal container interactions
        service -> core "Uses algorithms and data models"
        service -> connectors "Calls model servers for inference"
        service -> arrow "Serializes data for Python interop"
        authProxy -> service "Forwards authenticated requests" "HTTP/8080 plaintext"

        # External system interactions
        modelMesh -> trustyai "Sends inference payloads" "HTTP POST /consumer/kserve/v2 80/TCP"
        trustyai -> kserveModels "Queries models for predictions during explanations" "gRPC/HTTP2 plaintext"
        prometheus -> trustyai "Scrapes fairness and drift metrics" "HTTP GET /q/metrics 80/TCP Bearer"
        grafana -> prometheus "Visualizes metrics" "PromQL"
        trustyaiOperator -> trustyai "Creates and manages deployment lifecycle"
        trustyai -> mariadb "Persists inference data (DATABASE mode)" "JDBC/3306 plaintext"
        trustyai -> minio "Persists inference data (MINIO mode)" "S3 API/9000 HTTPS TLS"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
