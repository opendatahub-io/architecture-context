workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, monitors fairness and drift metrics via ODH Dashboard"
        platformAdmin = person "Platform Admin" "Deploys and configures TrustyAI instances per namespace"

        trustyai = softwareSystem "TrustyAI Explainability" "Quarkus-based service providing model fairness monitoring, data drift detection, and explainability for ML models on OpenShift AI" {
            service = container "explainability-service" "REST API for fairness metrics, drift detection, explainability, and inference data ingestion" "Java 17 Quarkus"
            core = container "explainability-core" "Core algorithms: LIME, SHAP, counterfactual, fairness (SPD, DIR), drift (KS, MMD, Meanshift)" "Java Library"
            connectors = container "explainability-connectors" "KServe v1 REST and v2 gRPC client connectors with protobuf definitions" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow serialization for efficient batch data exchange" "Java Library"
        }

        kserve = softwareSystem "KServe / ModelMesh" "ML model serving platform (inference endpoints)" "Internal RHOAI"
        knativeEventing = softwareSystem "Knative Eventing" "CloudEvent routing for inference payloads" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Deploys and manages TrustyAI instances, configures TLS and storage" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "Internal Platform"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for OpenShift AI platform" "Internal RHOAI"
        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for inference data storage" "External"
        minio = softwareSystem "MinIO" "S3-compatible object storage for inference data" "External"
        pvc = softwareSystem "PersistentVolumeClaim" "Kubernetes persistent storage for file-based data" "Infrastructure"

        # User relationships
        dataScientist -> dashboard "Views fairness/drift metrics" "HTTPS"
        dashboard -> trustyai "Queries metrics and model metadata" "HTTP/8080"
        platformAdmin -> trustyaiOperator "Configures TrustyAIService CR" "kubectl"

        # Inbound data flows
        kserve -> knativeEventing "Emits inference CloudEvents" "CloudEvent"
        knativeEventing -> trustyai "Routes inference req/resp payloads" "HTTP/8080 CloudEvent"
        kserve -> trustyai "ModelMesh sends inference payloads" "HTTP/8080 REST"

        # Internal container relationships
        service -> core "Uses algorithms for metric computation" "Java method call"
        service -> connectors "Uses gRPC client for model queries" "Java method call"
        service -> arrow "Uses for batch data serialization" "Java method call"

        # Outbound flows
        trustyai -> kserve "Queries models for predictions (explainability)" "gRPC KServe v2"
        trustyai -> mariadb "Stores/retrieves inference data" "JDBC/3306"
        trustyai -> minio "Stores/retrieves inference data" "HTTP S3 API/9000"
        trustyai -> pvc "Reads/writes inference data files" "Filesystem I/O"

        # Monitoring
        prometheus -> trustyai "Scrapes trustyai_* metrics" "HTTP GET/8080 Bearer Token"

        # Operator
        trustyaiOperator -> trustyai "Deploys, manages TLS, configures storage" "Kubernetes API"
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
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
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
            element "Infrastructure" {
                background #d6b656
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
