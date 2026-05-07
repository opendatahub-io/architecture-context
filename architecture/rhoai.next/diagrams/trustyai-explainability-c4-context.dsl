workspace {
    model {
        datascientist = person "Data Scientist" "Creates ML models, monitors fairness and drift metrics"
        mlops = person "MLOps Engineer" "Manages model serving infrastructure and monitoring"

        trustyai = softwareSystem "TrustyAI Explainability" "AI model explainability, fairness metrics, and data drift detection service" {
            coreLib = container "explainability-core" "LIME, SHAP, Counterfactual, PDP explainability algorithms" "Java 17 Library"
            connectorsLib = container "explainability-connectors" "KServe v1/v2 HTTP and gRPC connectors for model inference" "Java 17 Library"
            arrowLib = container "explainability-arrow" "Apache Arrow columnar data format support" "Java 17 Library"
            service = container "explainability-service" "REST API for fairness metrics, drift detection, data management" "Quarkus 3.8.5" {
                fairnessEndpoints = component "Fairness Endpoints" "SPD, DIR metric computation" "RESTEasy Reactive"
                driftEndpoints = component "Drift Endpoints" "KS Test, FourierMMD, Meanshift detection" "RESTEasy Reactive"
                consumerEndpoint = component "Consumer Endpoint" "/consumer/kserve/v2 payload ingestion" "RESTEasy Reactive"
                cloudEventConsumer = component "CloudEvent Consumer" "Knative CloudEvents ingestion" "Quarkus Funqy"
                payloadReconciler = component "Payload Reconciler" "Matches request/response payloads" "CDI Bean"
                prometheusScheduler = component "Prometheus Scheduler" "Periodic metric computation (5s)" "Quarkus Scheduler"
                storageLayer = component "Storage Layer" "Pluggable: PVC, Hibernate, MinIO, Memory" "CDI @LookupIfProperty"
            }
        }

        kserveModelMesh = softwareSystem "KServe / ModelMesh" "Model serving infrastructure for ML models" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "External"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Deploys and manages TrustyAI instances per namespace" "Internal RHOAI"
        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for observation data persistence" "External"
        minio = softwareSystem "MinIO" "S3-compatible object storage for observation data" "External"
        pvc = softwareSystem "PersistentVolumeClaim" "Filesystem storage for observation data (default)" "External"
        openshiftRoute = softwareSystem "OpenShift Route" "Ingress for external access to service endpoints" "External"

        # User interactions
        datascientist -> trustyai "Requests fairness/drift metrics, uploads data" "HTTP/8080"
        mlops -> trustyai "Monitors metrics, configures service" "HTTP/8080"

        # System interactions
        kserveModelMesh -> trustyai "Sends inference payloads for observation tracking" "HTTP/8080, gRPC"
        trustyai -> kserveModelMesh "Invokes models for explainability (ODH only)" "HTTP/8080, gRPC/plaintext"
        prometheus -> trustyai "Scrapes /q/metrics for trustyai_spd, trustyai_dir" "HTTP/8080"
        trustyaiOperator -> trustyai "Deploys and manages lifecycle" "Kubernetes API"
        trustyai -> mariadb "Persists observation data (DATABASE mode)" "JDBC/3306"
        trustyai -> minio "Persists observation data (MINIO mode)" "S3 HTTP API"
        trustyai -> pvc "Persists observation data (PVC mode, default)" "Filesystem"
        openshiftRoute -> trustyai "Routes external traffic" "HTTP/80 -> 8080"

        # Internal container relationships
        service -> coreLib "Uses explainability algorithms"
        service -> connectorsLib "Uses KServe connectors for model inference"
        service -> arrowLib "Uses Arrow format for data interchange"
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

        component service "Components" {
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
