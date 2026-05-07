workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, monitors fairness and drift, requests explanations"
        platformAdmin = person "Platform Admin" "Deploys and configures TrustyAI via TrustyAI Operator"

        trustyai = softwareSystem "TrustyAI Explainability" "Quarkus-based REST service providing AI model fairness metrics, explainability algorithms, and data drift detection" {
            service = container "explainability-service" "Main deployable Quarkus REST service with storage, scheduling, and Prometheus integration" "Java 17 / Quarkus 3.8.5"
            core = container "explainability-core" "Core XAI algorithms: LIME, SHAP, Counterfactual; fairness metrics (SPD, DIR); drift metrics (KS Test, MMD, Meanshift)" "Java Library"
            connectors = container "explainability-connectors" "KServe V2 gRPC inference protocol integration via protobuf; payload parsing" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow IPC format support for Java-Python data exchange" "Java Library"

            service -> core "Uses algorithms and data structures"
            service -> connectors "Uses gRPC client and payload parsers"
        }

        trustyaiOperator = softwareSystem "TrustyAI Operator" "Deploys and configures TrustyAI service instances, injects auth proxy sidecars" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving infrastructure providing V2 Inference Protocol endpoints" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform sending inference payloads to TrustyAI" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection system scraping trustyai_* gauges via ServiceMonitor" "Internal RHOAI"
        dashboard = softwareSystem "Open Data Hub Dashboard" "Web UI for data science workflows, integrates TrustyAI for bias/fairness visualization" "Internal RHOAI"
        pvcStorage = softwareSystem "PVC Storage" "Persistent Volume Claim for flat-file CSV inference data storage" "Infrastructure"
        minioStorage = softwareSystem "MinIO" "S3-compatible object storage for inference data (optional backend)" "External"
        mariadb = softwareSystem "MariaDB/MySQL" "Relational database for inference data storage via Hibernate (optional backend)" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for internal HTTPS on port 4443" "Infrastructure"

        dataScientist -> trustyai "Requests fairness metrics, drift analysis, and explainability results" "REST API / HTTPS"
        platformAdmin -> trustyaiOperator "Creates TrustyAIService CRDs" "kubectl / OC CLI"
        trustyaiOperator -> trustyai "Deploys, configures, injects auth proxy sidecar" "Kubernetes API"

        modelMesh -> trustyai "Sends partial inference payloads for reconciliation" "HTTP POST /consumer/kserve/v2"
        kserve -> trustyai "Sends inference request/response payloads" "Knative CloudEvents / HTTP"
        trustyai -> kserve "Invokes models during explainability computations" "gRPC V2 Inference Protocol"
        prometheus -> trustyai "Scrapes fairness/drift gauges every 4s" "HTTP GET /q/metrics"
        dashboard -> trustyai "Consumes bias/fairness data for UI" "REST API / HTTP"

        trustyai -> pvcStorage "Reads/writes inference data" "Filesystem I/O"
        trustyai -> minioStorage "Reads/writes inference data" "S3 API / HTTP(S)"
        trustyai -> mariadb "Reads/writes inference data" "JDBC"
        certManager -> trustyai "Provisions TLS certificates" "Kubernetes Secrets"
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
                background #438DD5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
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
            element "Infrastructure" {
                background #d4a017
                color #ffffff
            }
        }
    }
}
