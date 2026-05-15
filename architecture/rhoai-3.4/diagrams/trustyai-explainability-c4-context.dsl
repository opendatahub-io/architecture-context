workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and monitors fairness/drift metrics"
        mlEngineer = person "ML Engineer" "Deploys models and configures TrustyAI monitoring"

        trustyai = softwareSystem "TrustyAI Explainability" "Responsible AI microservice providing fairness metrics, drift detection, and model explainability for KServe/ModelMesh models" {
            core = container "explainability-core" "Core AI algorithms: LIME, SHAP, Counterfactual, PDP, fairness metrics (SPD, DIR), drift detection (KS, Fourier MMD, Meanshift), NLP metrics" "Java 17 Library"
            connectors = container "explainability-connectors" "KServe v1/v2 HTTP and gRPC client connectors with protobuf stubs" "Java 17 Library"
            arrow = container "explainability-arrow" "Apache Arrow columnar data serialization and PredictionProvider interface" "Java 17 Library"
            service = container "explainability-service" "REST microservice exposing fairness, drift, explainability, and data management endpoints with Prometheus metrics" "Quarkus 3.8.5" "HTTP:8080, HTTPS:4443"
            initContainer = container "Init Container" "Creates model-serving-config ConfigMap to register TrustyAI as ModelMesh payload processor" "ose-cli"
            storage = container "Storage Backend" "Stores inference data and ground truth" "PVC (default) / MariaDB / MySQL / Memory"
        }

        kserveModelMesh = softwareSystem "KServe / ModelMesh" "ML model serving infrastructure with multi-protocol inference support" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Operator" "Manages TrustyAIService CR lifecycle and deploys TrustyAI service instances" "Internal RHOAI"
        knativeEventing = softwareSystem "Knative Eventing" "Event-driven messaging for CloudEvent-based inference data ingestion" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting system" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "Platform"
        mariadb = softwareSystem "MariaDB / MySQL" "Optional relational database for inference data storage" "External"
        minio = softwareSystem "MinIO" "Optional S3-compatible object storage" "External"

        # Relationships - Users
        dataScientist -> trustyai "Queries fairness metrics and drift detection results" "REST API / HTTP"
        mlEngineer -> trustyaiOperator "Creates TrustyAIService CR" "kubectl"
        trustyaiOperator -> trustyai "Deploys and manages" "Kubernetes Operator"

        # Relationships - Data Ingestion
        kserveModelMesh -> service "Forwards inference payloads" "HTTP/8080 POST /consumer/kserve/v2"
        knativeEventing -> service "Delivers inference CloudEvents" "HTTP/8080 CloudEvents"

        # Relationships - Model Inference (for explainability)
        connectors -> kserveModelMesh "Sends inference requests for perturbation-based explanations" "gRPC/8033, HTTP/80"

        # Relationships - Internal
        service -> core "Uses algorithms for computation"
        service -> connectors "Uses for model inference calls"
        service -> arrow "Uses for data serialization"
        service -> storage "Reads/writes inference data"

        # Relationships - Init
        initContainer -> kubernetesAPI "Creates model-serving-config ConfigMap" "HTTPS/443 SA Token"

        # Relationships - Monitoring
        prometheus -> service "Scrapes fairness and drift metrics" "HTTP/8080 GET /q/metrics Bearer Token"

        # Relationships - Optional Storage
        service -> mariadb "Stores inference data (optional)" "JDBC/3306"
        service -> minio "Stores data (optional)" "HTTP/HTTPS"
    }

    views {
        systemContext trustyai "SystemContext" {
            include *
            autoLayout
            description "TrustyAI Explainability in the RHOAI ecosystem"
        }

        container trustyai "Containers" {
            include *
            autoLayout
            description "Internal structure of TrustyAI Explainability"
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
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
