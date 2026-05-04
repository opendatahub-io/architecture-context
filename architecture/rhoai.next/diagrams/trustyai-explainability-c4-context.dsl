workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, monitors fairness and drift metrics"
        mlEngineer = person "ML Engineer" "Deploys models, configures explainability and monitoring"

        trustyai = softwareSystem "TrustyAI Explainability" "AI model explainability, fairness metrics, and data drift detection for ML models on OpenShift AI" {
            coreLibrary = container "explainability-core" "Core AI explainability algorithms: LIME, SHAP, Counterfactual, PDP" "Java Library"
            connectorsLibrary = container "explainability-connectors" "KServe v1/v2 HTTP and gRPC connectors for model inference" "Java Library"
            arrowLibrary = container "explainability-arrow" "Apache Arrow columnar data format support" "Java Library"
            service = container "explainability-service" "REST API for fairness metrics, drift detection, explainability, and data management" "Quarkus 3.8.5 Service" {
                fairnessEndpoints = component "Fairness Endpoints" "SPD, DIR fairness metric computation" "JAX-RS Resource"
                driftEndpoints = component "Drift Endpoints" "KSTest, FourierMMD, Meanshift drift detection" "JAX-RS Resource"
                explainerEndpoints = component "Explainer Endpoints" "LIME, SHAP, Counterfactual, TSSaliency, PDP (ODH only)" "JAX-RS Resource"
                consumerEndpoint = component "Payload Consumer" "Ingests KServe v2 inference payloads" "JAX-RS Resource"
                cloudEventConsumer = component "CloudEvent Consumer" "Receives Knative CloudEvents for inference data" "Quarkus Funqy"
                payloadReconciler = component "Payload Reconciler" "Matches request/response pairs before persistence" "CDI Bean"
                prometheusScheduler = component "Prometheus Scheduler" "Periodic metric computation and Micrometer gauge publishing" "Quarkus Scheduler"
                storageLayer = component "Storage Layer" "Pluggable backends: PVC, Hibernate (MariaDB), MinIO, Memory" "CDI LookupIfProperty"
            }
        }

        kserveModelMesh = softwareSystem "KServe / ModelMesh" "Model serving infrastructure for ML inference" "External"
        kserveInferenceService = softwareSystem "KServe InferenceService" "Emits inference CloudEvents via Knative triggers" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "External"
        trustyaiOperator = softwareSystem "trustyai-service-operator" "Deploys and manages TrustyAI service instances per namespace" "Internal RHOAI"
        mariaDB = softwareSystem "MariaDB / MySQL" "Relational database for observation data persistence" "External"
        minIO = softwareSystem "MinIO" "S3-compatible object storage for observation data" "External"
        pvc = softwareSystem "PersistentVolumeClaim" "Kubernetes persistent storage for observation data" "External"

        # User interactions
        dataScientist -> trustyai "Requests fairness/drift metrics and explainability" "REST HTTP/8080"
        mlEngineer -> trustyai "Configures metric schedules, uploads data" "REST HTTP/8080"

        # Internal container relationships
        service -> coreLibrary "Uses explainability algorithms"
        service -> connectorsLibrary "Uses KServe connectors for model inference"
        service -> arrowLibrary "Uses Arrow format for data interchange"

        # Component relationships
        consumerEndpoint -> payloadReconciler "Forwards partial payloads"
        cloudEventConsumer -> payloadReconciler "Forwards CloudEvent payloads"
        payloadReconciler -> storageLayer "Persists matched observations"
        fairnessEndpoints -> storageLayer "Reads observation data"
        driftEndpoints -> storageLayer "Reads observation data"
        explainerEndpoints -> coreLibrary "Invokes LIME/SHAP/CF/PDP"
        prometheusScheduler -> storageLayer "Reads data for metric computation"

        # External integrations
        kserveModelMesh -> trustyai "Pushes inference payloads" "HTTP POST /consumer/kserve/v2 8080/TCP"
        kserveInferenceService -> trustyai "Emits inference CloudEvents" "HTTP CloudEvents 8080/TCP"
        trustyai -> kserveModelMesh "Invokes model inference for explainability" "HTTP 8080/TCP, gRPC"
        prometheus -> trustyai "Scrapes fairness and drift metrics" "HTTP GET /q/metrics 8080/TCP"
        trustyai -> mariaDB "Persists observation data (DATABASE mode)" "JDBC/3306"
        trustyai -> minIO "Persists observation data (MINIO mode)" "HTTP S3 API"
        trustyai -> pvc "Persists observation data (PVC mode)" "Filesystem /inputs"
        trustyaiOperator -> trustyai "Deploys and manages lifecycle" "Kubernetes API"
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

        component service "ServiceComponents" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
