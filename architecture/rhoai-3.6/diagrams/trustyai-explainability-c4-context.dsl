workspace {
    model {
        datascientist = person "Data Scientist" "Monitors model fairness and drift, requests explainability"
        mlops = person "MLOps Engineer" "Configures model monitoring and alerting"

        trustyai = softwareSystem "TrustyAI Explainability" "Fairness metrics, drift detection, and model explainability for ML models on OpenShift AI" {
            service = container "explainability-service" "Quarkus REST service: fairness metrics, drift detection, inference payload consumption, Prometheus metrics" "Java 17 / Quarkus 3.20"
            core = container "explainability-core" "Core algorithmic library: SPD, DIR, LIME, SHAP, Counterfactual, KS Test, Fourier MMD" "Java Library"
            connectors = container "explainability-connectors" "KServe v1/v2 HTTP and gRPC client connectors for model inference" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow bridge for Java-Python data exchange" "Java Library"
        }

        modelmesh = softwareSystem "ModelMesh" "Multi-model serving runtime" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Internal RHOAI"
        minio = softwareSystem "MinIO" "Object storage for inference data" "External"
        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for inference data" "External"
        inferenceServers = softwareSystem "Inference Servers" "KServe / ModelMesh model serving endpoints" "Internal RHOAI"

        # User interactions
        datascientist -> trustyai "Requests fairness metrics and drift reports via REST API"
        mlops -> prometheus "Monitors TrustyAI metrics dashboards and alerts"

        # Inbound flows
        modelmesh -> service "Sends inference payload pairs" "HTTP/80"
        kserve -> service "Sends inference CloudEvents" "HTTP/80"
        prometheus -> service "Scrapes /q/metrics" "HTTP/80 (4s interval)"

        # Internal flows
        service -> core "Invokes fairness, drift, explainability algorithms" "In-process"
        service -> connectors "Uses for model inference calls" "In-process"

        # Outbound flows
        connectors -> inferenceServers "Calls model inference endpoints" "gRPC / HTTP"
        service -> minio "Stores/retrieves inference data" "HTTP/HTTPS"
        service -> mariadb "Stores/retrieves inference data" "JDBC/3306"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
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
        }
    }
}
