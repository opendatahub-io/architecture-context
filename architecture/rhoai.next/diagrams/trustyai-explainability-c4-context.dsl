workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and monitors fairness/bias"
        platformAdmin = person "Platform Admin" "Deploys and configures RHOAI platform"

        trustyai = softwareSystem "TrustyAI Explainability" "Provides model fairness monitoring, data drift detection, and explainability for ML models" {
            service = container "explainability-service" "Quarkus REST API for metrics, explainability, and inference data management" "Java 17 / Quarkus 3.8.5"
            core = container "explainability-core" "Core XAI algorithms: LIME, SHAP, counterfactual, drift, fairness" "Java Library"
            connectors = container "explainability-connectors" "KServe v1/v2 HTTP and v2 gRPC protocol adapters" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow data format conversion" "Java Library"
            initContainer = container "config-map-overrider" "Registers TrustyAI consumer endpoint in model-serving-config ConfigMap" "Shell Script (ose-cli)" "Init Container"
            pvcStorage = container "PVC Storage" "Default CSV file storage at /inputs" "Kubernetes PVC" "Storage"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Model serving platform providing inference endpoints" "Internal RHOAI"
        kserveServers = softwareSystem "KServe Inference Servers" "Runtime inference servers hosting ML models" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Operator that deploys and manages TrustyAI instances" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Platform"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform" "Internal RHOAI"
        minio = softwareSystem "MinIO / S3 Storage" "S3-compatible object storage for inference data" "External (Optional)"
        database = softwareSystem "MariaDB / MySQL" "Relational database for inference data" "External (Optional)"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "Platform"

        # User interactions
        dataScientist -> dashboard "Views fairness metrics and model info"
        dataScientist -> trustyai "Requests explanations and metrics" "HTTP/8080"
        platformAdmin -> trustyaiOperator "Deploys TrustyAI instances"

        # Dashboard interaction
        dashboard -> trustyai "Queries metrics and model info" "HTTP/8080"

        # Inference payload ingestion
        kserve -> trustyai "Sends inference payloads" "HTTP CloudEvents/8080"

        # Outbound: explainability calls
        trustyai -> kserveServers "Calls models for explanations" "HTTP v1/v2, gRPC v2"

        # Operator management
        trustyaiOperator -> trustyai "Deploys, configures, injects kube-rbac-proxy" "Kubernetes API"

        # Monitoring
        prometheus -> trustyai "Scrapes fairness/drift metrics" "HTTP/8080 (ServiceMonitor)"

        # Storage backends
        trustyai -> minio "Stores/retrieves inference data" "S3 API (HTTPS)"
        trustyai -> database "Stores/retrieves inference data" "JDBC/3306"

        # Init container
        trustyai -> k8sApi "Registers payload processor URL" "HTTPS/443"

        # Internal container relationships
        service -> core "Uses algorithms"
        service -> connectors "Uses protocol adapters"
        service -> arrow "Uses data format conversion"
        service -> pvcStorage "Reads/writes CSV data"
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
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External (Optional)" {
                background #f5a623
                color #ffffff
            }
            element "Platform" {
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
            element "Storage" {
                background #f5a623
                color #ffffff
                shape Cylinder
            }
            element "Init Container" {
                background #b85450
                color #ffffff
            }
        }
    }
}
