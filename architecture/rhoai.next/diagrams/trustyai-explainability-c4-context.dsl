workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, monitors fairness and drift metrics"
        mlEngineer = person "ML Engineer" "Deploys models, configures explainability and monitoring"

        trustyai = softwareSystem "TrustyAI Explainability" "AI explainability, fairness metrics (SPD, DIR), and data drift detection service for ML models" {
            service = container "explainability-service" "Quarkus 3.8.5 REST microservice exposing 50+ HTTP endpoints for metrics, explanations, and data management" "Java 17 / Quarkus"
            core = container "explainability-core" "Core XAI algorithms: SHAP, LIME, Counterfactual, PDP; fairness metrics: DIR, SPD; drift detection: KS, MMD, Meanshift" "Java Library"
            connectors = container "explainability-connectors" "KServe V1/V2 HTTP and gRPC prediction provider clients with protobuf stubs" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow IPC serialization for Java-Python data interoperability" "Java Library"
        }

        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform that routes inference requests" "Internal RHOAI"
        kserve = softwareSystem "KServe Model Servers" "KServe V1/V2 compatible model serving endpoints" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting platform" "Internal Platform"
        grafana = softwareSystem "Grafana / Dashboard" "Visualization of fairness and drift metrics" "Internal Platform"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Operator managing TrustyAI service instances per namespace via CRDs" "Internal RHOAI"
        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for persistent inference data storage" "External / Optional"
        minio = softwareSystem "MinIO" "S3-compatible object storage for inference data" "External / Optional"
        odhDashboard = softwareSystem "ODH Dashboard" "OpenShift Data Hub user interface" "Internal RHOAI"

        # Relationships
        dataScientist -> trustyai "Requests fairness metrics, drift detection, explanations" "REST API / HTTP"
        mlEngineer -> trustyaiOperator "Configures TrustyAI instances" "kubectl / CRDs"

        modelMesh -> trustyai "Sends inference payloads for data capture" "HTTP POST /consumer/kserve/v2 / 80/TCP"
        trustyai -> kserve "Queries models for predictions during explanation generation" "gRPC V2 / HTTP"
        prometheus -> trustyai "Scrapes fairness and drift metrics" "HTTP GET /q/metrics / Bearer Token"
        grafana -> prometheus "Queries metrics for dashboard visualization" "PromQL"
        trustyaiOperator -> trustyai "Creates and manages service instances, injects auth proxy" "Kubernetes API"
        trustyai -> mariadb "Persists inference data (DATABASE mode)" "JDBC / 3306/TCP"
        trustyai -> minio "Persists inference data (MINIO mode)" "S3 API / HTTPS 9000/TCP"
        odhDashboard -> trustyai "Displays TrustyAI metrics and status" "REST API / HTTP"

        # Internal container relationships
        service -> core "Uses algorithms for metric computation and explanations"
        service -> connectors "Uses for model inference calls"
        service -> arrow "Uses for Java-Python data exchange"
        connectors -> kserve "gRPC/HTTP calls to model servers"
    }

    views {
        systemContext trustyai "SystemContext" {
            include *
            autoLayout
            description "TrustyAI Explainability in the RHOAI ecosystem"
        }

        container trustyai "Containers" {
            include *
            autoLayout
            description "Internal modules of TrustyAI Explainability"
        }

        styles {
            element "Software System" {
                background #438dd5
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
            element "External / Optional" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
