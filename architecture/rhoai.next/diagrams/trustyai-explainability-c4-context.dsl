workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, monitors fairness/drift, requests explanations"
        mlEngineer = person "ML Engineer" "Deploys models, configures monitoring, reviews metrics"

        trustyai = softwareSystem "TrustyAI Explainability" "AI model explainability, fairness metrics, and data drift detection service for OpenShift AI" {
            core = container "explainability-core" "Core AI explainability algorithms: LIME, SHAP, Counterfactual (OptaPlanner), PDP, Aggregated LIME" "Java 17 Library"
            connectors = container "explainability-connectors" "KServe v1/v2 HTTP and gRPC connectors for model inference with protobuf definitions" "Java 17 Library"
            arrow = container "explainability-arrow" "Apache Arrow columnar data format support for efficient data interchange" "Java 17 Library"
            service = container "explainability-service" "Quarkus REST API service: fairness metrics, drift detection, data management, and explainability (ODH only)" "Quarkus 3.8.5 / Java 17" {
                consumerEndpoint = component "Consumer Endpoint" "Receives KServe v2 inference payloads from ModelMesh" "JAX-RS REST"
                cloudEventConsumer = component "CloudEvent Consumer" "Receives Knative CloudEvents from KServe InferenceServices" "Quarkus Funqy"
                fairnessEndpoints = component "Fairness Metric Endpoints" "SPD, DIR fairness metric computation and scheduling" "JAX-RS REST"
                driftEndpoints = component "Drift Metric Endpoints" "KSTest, FourierMMD, Meanshift drift detection" "JAX-RS REST"
                explainerEndpoints = component "Explainer Endpoints" "LIME, SHAP, Counterfactual, TSSaliency, PDP (ODH only)" "JAX-RS REST"
                reconciler = component "Payload Reconciler" "Matches inference request/response pairs before persistence" "CDI Bean"
                storageLayer = component "Storage Layer" "Pluggable storage: PVC, Hibernate (MariaDB), MinIO, Memory" "CDI + LookupIfProperty"
                prometheusScheduler = component "Prometheus Scheduler" "Periodically computes registered metrics, publishes to Micrometer" "Quarkus Scheduler"
            }
        }

        kserveModelMesh = softwareSystem "KServe / ModelMesh" "Model serving infrastructure providing inference endpoints" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "External"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Deploys and manages TrustyAI service instances per namespace" "Internal RHOAI"
        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for observation data persistence" "External"
        minio = softwareSystem "MinIO" "S3-compatible object storage for observation data" "External"
        pvc = softwareSystem "PersistentVolumeClaim" "Kubernetes volume for file-based observation storage" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for TLS" "External"
        dashboard = softwareSystem "ODH Dashboard" "OpenShift AI web console for model management" "Internal RHOAI"

        # User interactions
        dataScientist -> trustyai "Requests fairness metrics, drift analysis, explanations" "REST/HTTP"
        mlEngineer -> trustyai "Configures monitoring, uploads data, reviews metrics" "REST/HTTP"

        # System interactions
        kserveModelMesh -> trustyai "Sends inference payloads (HTTP POST, CloudEvents)" "HTTP/8080"
        trustyai -> kserveModelMesh "Invokes model inference for explainability" "HTTP/8080, gRPC"
        prometheus -> trustyai "Scrapes /q/metrics for trustyai_* gauges" "HTTP/8080 Bearer Token"
        trustyaiOperator -> trustyai "Manages lifecycle, deploys per namespace" "Kubernetes API"
        trustyai -> mariadb "Persists observation data (DATABASE mode)" "JDBC/3306"
        trustyai -> minio "Persists observation data (MINIO mode)" "HTTP S3 API"
        trustyai -> pvc "Persists observation data (PVC mode)" "Filesystem"
        certManager -> trustyai "Provisions TLS certificates for HTTPS/4443" "Kubernetes Secret"
        dashboard -> trustyai "Displays fairness/drift metrics via API" "REST/HTTP"

        # Internal container interactions
        service -> core "Uses explainability algorithms"
        service -> connectors "Uses KServe prediction providers"
        service -> arrow "Uses Arrow data format"
        connectors -> core "Implements PredictionProvider interface"
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
                background #438dd5
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
