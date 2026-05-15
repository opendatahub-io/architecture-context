workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys ML models and monitors fairness/drift metrics"
        mlEngineer = person "ML Engineer" "Configures model serving and explainability"
        securityAuditor = person "Security Auditor" "Reviews model fairness compliance and bias reports"

        trustyai = softwareSystem "TrustyAI Explainability" "AI fairness metrics, drift detection, and explainable AI service for ML models" {
            service = container "explainability-service" "Quarkus REST service exposing fairness, drift, data management, and Prometheus metric APIs" "Java 17 / Quarkus 3.8.5"
            core = container "explainability-core" "Core XAI algorithms: LIME, SHAP, Counterfactual, PDP, fairness (SPD, DIR), drift (KS, FourierMMD, Meanshift)" "Java Library"
            connectors = container "explainability-connectors" "KServe v1/v2 HTTP and gRPC prediction providers for model inference" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow-based data exchange for Java-Python interoperability" "Java Library"

            service -> core "Uses algorithms for metric computation and explanations"
            service -> connectors "Uses for model inference calls"
            service -> arrow "Uses for data format conversion"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Deploys and manages TrustyAI service instances per namespace" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform with inference logging" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving with payload logging" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Internal Platform"
        knativeEventing = softwareSystem "Knative Eventing" "Event-driven inference payload delivery via CloudEvents" "Internal Platform"

        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for inference data persistence" "External"
        minio = softwareSystem "MinIO / S3" "S3-compatible object storage for inference data" "External"
        pvc = softwareSystem "Kubernetes PVC" "Persistent volume for flat-file inference data storage" "Internal Platform"

        # Relationships
        trustyaiOperator -> trustyai "Creates Deployment, Service, PVC, ConfigMap; manages lifecycle" "Kubernetes API"
        dataScientist -> trustyai "Schedules fairness/drift metrics, uploads data, views explanations" "REST API / 8080"
        mlEngineer -> trustyai "Configures metric thresholds and model metadata" "REST API / 8080"
        securityAuditor -> prometheus "Reviews fairness dashboards (trustyai_ metrics)" "PromQL"

        modelMesh -> trustyai "Sends inference payloads" "HTTP/8080 POST /consumer/kserve/v2"
        kserve -> trustyai "Sends inference request/response events" "CloudEvents HTTP/8080"
        prometheus -> trustyai "Scrapes fairness and drift metrics" "HTTP/8080 GET /q/metrics"

        trustyai -> kserve "Sends prediction requests for explanations" "gRPC (plaintext) / HTTP"
        trustyai -> mariadb "Stores inference data" "JDBC/3306"
        trustyai -> minio "Stores inference data" "HTTP or HTTPS"
        trustyai -> pvc "Reads/writes inference data as flat files" "Local filesystem"

        knativeEventing -> trustyai "Delivers KServe inference events" "CloudEvents"
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
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90d9
                color #ffffff
            }
        }
    }
}
