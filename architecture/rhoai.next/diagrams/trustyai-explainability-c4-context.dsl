workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, monitors fairness and drift"
        platformAdmin = person "Platform Admin" "Manages OpenShift AI platform and monitoring infrastructure"

        trustyai = softwareSystem "TrustyAI Explainability" "AI fairness metrics, model explainability, and data drift detection service" {
            service = container "explainability-service" "Quarkus REST service providing fairness, drift, and explainability endpoints" "Java 17 / Quarkus 3.8.5"
            core = container "explainability-core" "Core XAI algorithms: SPD, DIR, LIME, SHAP, CF, KS, MMD, Meanshift" "Java Library"
            connectors = container "explainability-connectors" "KServe v1/v2 HTTP and gRPC inference protocol connectors" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow bridge for Python interoperability" "Java Library"
            reconciler = container "PayloadReconciler" "Matches partial inference payloads (input+output) by ID" "Internal Component"
            scheduler = container "PrometheusScheduler" "Cron-triggered metric computation and gauge updates" "Internal Component"
        }

        kserve = softwareSystem "KServe" "Model serving platform with InferenceService lifecycle management" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving with shared inference infrastructure" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Operator" "Manages per-namespace TrustyAI service instances" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "Internal Platform"
        dashboard = softwareSystem "OpenShift AI Dashboard" "Web UI for model management and monitoring" "Internal RHOAI"
        kubeflow = softwareSystem "Kubeflow Event Broker" "CloudEvent distribution for serverless inference logging" "Internal Platform"

        pvc = softwareSystem "PVC Storage" "Kubernetes PersistentVolumeClaim for CSV data storage" "Infrastructure"
        minio = softwareSystem "MinIO / S3" "S3-compatible object storage (optional backend)" "External"
        database = softwareSystem "MariaDB / MySQL" "Relational database (optional backend)" "External"

        # User interactions
        dataScientist -> trustyai "Queries fairness metrics, requests explanations" "REST HTTP/8080"
        dataScientist -> dashboard "Views model monitoring dashboards"
        platformAdmin -> prometheus "Configures alerts on trustyai_* metrics"

        # Inbound data flows
        kserve -> trustyai "Sends inference payloads via payload processor webhook" "HTTP/8080"
        modelmesh -> trustyai "Sends partial inference payloads (Protobuf)" "HTTP/8080"
        kubeflow -> trustyai "Sends inference CloudEvents" "HTTP/8080"

        # Outbound inference
        trustyai -> kserve "Makes inference calls for explanation generation" "gRPC/8033 or HTTP"

        # Monitoring
        prometheus -> trustyai "Scrapes trustyai_* Prometheus gauges" "HTTP/8080 Bearer Token"
        dashboard -> trustyai "Queries fairness/drift status" "HTTP/8080"

        # Operator management
        trustyaiOperator -> trustyai "Deploys and manages service instances" "CRD reconciliation"

        # Storage
        trustyai -> pvc "Reads/writes inference data (CSV)" "Filesystem I/O"
        trustyai -> minio "Reads/writes inference data (optional)" "HTTP/9000 or HTTPS/443"
        trustyai -> database "Reads/writes inference data (optional)" "JDBC/3306"

        # Internal container relationships
        service -> core "Uses for metric computation and explanations"
        service -> connectors "Uses for KServe inference protocol"
        service -> reconciler "Delegates payload matching"
        service -> scheduler "Delegates scheduled metric computation"
        core -> connectors "Uses for model inference during explanations"
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #333333
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
