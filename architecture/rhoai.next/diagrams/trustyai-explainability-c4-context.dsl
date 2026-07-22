workspace {
    model {
        dataScientist = person "Data Scientist" "Configures fairness metrics and drift detection for deployed ML models"
        mlEngineer = person "ML Engineer" "Deploys models and monitors model behavior via TrustyAI"

        trustyai = softwareSystem "TrustyAI Explainability" "Responsible AI service providing fairness metrics, data drift detection, and explainability algorithms for ML models" {
            service = container "explainability-service" "Quarkus REST service providing fairness, drift, and explainability APIs with Prometheus metrics export" "Java 17 / Quarkus 3.8.5"
            core = container "explainability-core" "Core AI algorithms: SPD, DIR, LIME, SHAP, Counterfactual, KS test, Meanshift, FourierMMD" "Java Library"
            connectors = container "explainability-connectors" "KServe V2 gRPC client stubs for model inference protocol" "Java Library / gRPC 1.75.0"
            arrow = container "explainability-arrow" "Apache Arrow IPC module for Java-Python interop" "Java Library"
            prometheusScheduler = container "Prometheus Scheduler" "Recurring metric computation engine publishing Prometheus gauges" "Quarkus Scheduler"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages TrustyAIService CRD lifecycle, deploys TrustyAI instances with auth sidecars" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform with inference logging via CloudEvents" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving with payload processor for inference data forwarding" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting system" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing AI/ML workloads" "Internal RHOAI"

        mariadb = softwareSystem "MariaDB" "Relational database for inference data storage" "External (Optional)"
        minio = softwareSystem "MinIO" "S3-compatible object storage backend" "External (Optional)"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"

        # Relationships - External
        dataScientist -> trustyai "Configures fairness/drift metrics via REST API"
        mlEngineer -> trustyai "Monitors model behavior, uploads ground truth data"

        # Relationships - Inbound
        modelMesh -> trustyai "Sends inference payloads" "HTTP POST /consumer/kserve/v2 (8080/TCP)"
        kserve -> trustyai "Sends inference CloudEvents" "HTTP CloudEvent (8080/TCP)"
        prometheus -> trustyai "Scrapes metrics" "HTTP GET /q/metrics (8080/TCP)"
        trustyaiOperator -> trustyai "Deploys and manages instances" "Kubernetes API"

        # Relationships - Outbound
        trustyai -> kserve "Inference requests for explainability" "gRPC V2 Predict Protocol"
        trustyai -> modelMesh "Inference requests for explainability" "gRPC V2 Predict Protocol"
        trustyai -> mariadb "Stores inference data" "JDBC/3306"
        trustyai -> minio "Stores inference data" "HTTP(S)"
        trustyai -> k8sAPI "Creates ConfigMaps (init container)" "HTTPS/443"

        # Internal container relationships
        service -> core "Uses algorithms"
        service -> connectors "Uses gRPC client"
        service -> prometheusScheduler "Schedules metric computation"
        connectors -> kserve "gRPC inference calls" "gRPC/V2 Predict"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "External (Optional)" {
                background #999999
            }
            element "Infrastructure" {
                background #666666
            }
        }
    }
}
