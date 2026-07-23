workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and monitors fairness/bias metrics"
        platformAdmin = person "Platform Admin" "Manages OpenShift AI platform and model serving"

        trustyai = softwareSystem "TrustyAI Explainability" "AI fairness metrics, bias tracking, drift detection, and explainability for models served via KServe/ModelMesh" {
            service = container "explainability-service" "Quarkus REST service for fairness metrics, drift detection, and inference data consumption" "Java 17, Quarkus 3.8.5"
            core = container "explainability-core" "Core library: LIME, SHAP, Counterfactual, PDP explainers, fairness/drift/NLP metrics" "Java Library"
            connectors = container "explainability-connectors" "KServe V1 HTTP, V2 HTTP, and V2 gRPC connectors for inference server integration" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow IPC integration for Python interoperability" "Java Library"

            service -> core "Uses algorithms and metrics" "Java method calls"
            service -> connectors "Queries inference servers" "Java method calls"
            service -> arrow "Data exchange" "Arrow IPC"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Model serving platform providing inference endpoints" "External"
        kserveInference = softwareSystem "KServe Inference Servers" "Individual model inference servers" "External"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Deploys and manages TrustyAI Service instances per namespace" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        database = softwareSystem "Database (MariaDB/MySQL/PostgreSQL)" "Optional relational database for inference data persistence" "External"
        minio = softwareSystem "MinIO" "Optional S3-compatible object storage for inference data" "External"
        pvc = softwareSystem "PersistentVolumeClaim" "Default file-based storage at /inputs mount" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar enforcing Kubernetes RBAC for authentication and authorization" "Internal RHOAI"

        # Relationships
        dataScientist -> trustyai "Requests fairness metrics, drift detection, explainability" "HTTP/80"
        platformAdmin -> trustyaiOperator "Configures TrustyAI deployments"

        kserve -> trustyai "Sends inference payloads" "HTTP/8080, REST + CloudEvents"
        trustyai -> kserveInference "Queries models for explainability analysis" "gRPC plaintext, HTTP"
        trustyai -> prometheus "Publishes trustyai_spd, trustyai_dir, drift metrics" "HTTP/80 (scraped)"
        trustyai -> k8sAPI "Creates model-serving-config ConfigMap" "HTTPS/443"
        trustyai -> database "Persists inference data (optional DATABASE mode)" "JDBC/3306"
        trustyai -> minio "Persists inference data (optional MINIO mode)" "HTTP/HTTPS"
        trustyai -> pvc "Persists inference data (default PVC mode)" "Filesystem I/O"
        trustyaiOperator -> trustyai "Deploys and manages instances per namespace"
        kubeRBACProxy -> trustyai "Proxies authenticated requests" "HTTP/8080 (pod-internal)"

        prometheus -> trustyai "Scrapes metrics" "HTTP/80, Bearer Token"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
