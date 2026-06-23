workspace {
    model {
        dataScientist = person "Data Scientist" "Configures fairness metrics and monitors model bias/drift"
        platformAdmin = person "Platform Admin" "Deploys and manages TrustyAI service instances"

        trustyai = softwareSystem "TrustyAI Explainability" "Quarkus-based REST service providing AI fairness metrics, bias tracking, model drift detection, and explainability algorithms" {
            service = container "explainability-service" "Main Quarkus REST service exposing fairness, drift, and explainability APIs" "Java 17 / Quarkus 3.8.5"
            core = container "explainability-core" "XAI algorithm library: LIME, SHAP, CF, TSSaliency, PDP, SPD, DIR, Meanshift, FourierMMD" "Java Library"
            connectors = container "explainability-connectors" "KServe v1/v2 protocol support (HTTP + gRPC), protobuf definitions" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow vector interop for TrustyAI-Python data exchange" "Java Library"

            service -> core "Uses algorithms" "Java API"
            service -> connectors "Uses protocol adapters" "Java API"
            service -> arrow "Uses data interchange" "Java API"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Model serving platform providing inference endpoints" "External Platform"
        kserveLogger = softwareSystem "KServe InferenceLogger" "Sends inference payloads as CloudEvents via Knative eventing" "External Platform"
        modelMesh = softwareSystem "ModelMesh Serving" "Sends inference payloads for reconciliation" "External Platform"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Scrapes and stores metric gauges" "External Platform"
        operator = softwareSystem "TrustyAI Service Operator" "Deploys and manages TrustyAI instances, TLS certs, kube-rbac-proxy sidecars" "Internal RHOAI"
        dashboard = softwareSystem "OpenShift AI Dashboard" "Web UI for bias and drift visualization" "Internal RHOAI"

        pvc = softwareSystem "PVC Storage" "PersistentVolumeClaim for CSV data persistence (default)" "Infrastructure"
        minio = softwareSystem "MinIO" "S3-compatible object storage for data persistence" "Infrastructure"
        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for data persistence" "Infrastructure"

        # User interactions
        dataScientist -> trustyai "Configures fairness metrics, queries bias/drift results" "REST/HTTP 80/TCP"
        platformAdmin -> operator "Deploys TrustyAI instances" "Kubernetes API"
        dashboard -> trustyai "Queries fairness and drift metrics for visualization" "REST/HTTP 80/TCP"

        # Inbound data flows
        modelMesh -> trustyai "Sends inference payloads (Base64 protobuf)" "HTTP/80 POST /consumer/kserve/v2"
        kserveLogger -> trustyai "Sends inference payloads (CloudEvents)" "HTTP/80 Knative Events"
        prometheus -> trustyai "Scrapes metric gauges" "HTTP/80 GET /q/metrics"

        # Outbound data flows
        trustyai -> kserve "Sends inference requests for explainability" "gRPC/HTTP plaintext"
        trustyai -> pvc "Persists inference data (CSV)" "Filesystem I/O"
        trustyai -> minio "Persists inference data (S3)" "HTTP S3 API"
        trustyai -> mariadb "Persists inference data (JDBC)" "JDBC/3306"

        # Operator management
        operator -> trustyai "Deploys, configures, manages TLS & auth proxy" "Kubernetes API"
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
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #000000
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
