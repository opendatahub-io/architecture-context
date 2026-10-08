workspace {
    model {
        dataScientist = person "Data Scientist" "Requests fairness metrics and drift analysis for deployed ML models"
        platformAdmin = person "Platform Admin" "Monitors AI trustworthiness metrics via dashboards"

        trustyai = softwareSystem "TrustyAI Explainability" "Fairness metrics, drift detection, and explainable AI for ML models on OpenShift" {
            core = container "explainability-core" "Fairness metrics (SPD, DIR), drift detection (KS Test, Fourier MMD, Meanshift), XAI (LIME, SHAP, Counterfactual)" "Java 17 Library"
            connectors = container "explainability-connectors" "KServe v1 HTTP and v2 gRPC client adapters for model inference" "Java 17 Library"
            arrow = container "explainability-arrow" "Apache Arrow bridge for data exchange with TrustyAI Python" "Java 17 Library"
            service = container "explainability-service" "Quarkus REST API: payload ingestion, metric scheduling, Prometheus export" "Java 17 / Quarkus 3.8.5" {
                tags "Primary"
            }
            initContainer = container "config-map-overrider" "Init container that injects model-serving-config ConfigMap via oc CLI" "Shell / oc CLI"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Internal Platform"
        modelMesh = softwareSystem "ModelMesh / KServe" "Model serving platform forwarding inference payloads" "Internal Platform"
        operator = softwareSystem "TrustyAI Service Operator" "Deploys and manages TrustyAI instances per namespace" "Internal Platform"
        openshiftRoute = softwareSystem "OpenShift Route" "Exposes service externally" "Internal Platform"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for ConfigMap management" "Internal Platform"

        mariadb = softwareSystem "MariaDB / MySQL" "Optional relational storage backend" "External"
        minio = softwareSystem "MinIO" "Optional S3-compatible object storage" "External"
        kserveModels = softwareSystem "KServe v1/v2 Model Servers" "ML model inference endpoints" "External"

        # Relationships
        dataScientist -> trustyai "Requests fairness/drift metrics via REST API" "HTTP/80"
        platformAdmin -> prometheus "Monitors trustyai_spd and trustyai_dir gauges"

        prometheus -> trustyai "Scrapes /q/metrics" "HTTP/80, Bearer SA token"
        modelMesh -> trustyai "Forwards inference payloads to /consumer/kserve/v2" "HTTP/80"
        operator -> trustyai "Deploys per data science project namespace" "CRD lifecycle"

        trustyai -> kserveModels "Queries model inference for explainability" "gRPC + HTTP"
        trustyai -> mariadb "Stores inference data (optional)" "JDBC/3306"
        trustyai -> minio "Stores inference data (optional)" "HTTP(S)"
        trustyai -> openshiftAPI "Creates model-serving-config ConfigMap" "HTTPS/443"

        openshiftRoute -> trustyai "Routes external traffic" "HTTP/80"

        # Internal container relationships
        service -> core "Uses fairness metrics and drift algorithms"
        service -> connectors "Uses KServe client adapters"
        initContainer -> openshiftAPI "oc apply ConfigMap" "HTTPS/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
