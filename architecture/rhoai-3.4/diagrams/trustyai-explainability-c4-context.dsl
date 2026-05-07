workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models, configures fairness/drift monitoring"
        platformAdmin = person "Platform Admin" "Deploys and configures RHOAI platform components"

        trustyai = softwareSystem "TrustyAI Explainability" "Quarkus-based service providing AI fairness metrics, drift detection, and explainability for ML models on RHOAI" {
            service = container "explainability-service" "REST API for fairness metrics, drift detection, inference data management. Quarkus 3.8.5 on Java 17." "Quarkus REST Service" {
                fairnessEndpoints = component "Fairness Endpoints" "SPD, DIR metric computation and scheduling" "/metrics/group/fairness/*"
                driftEndpoints = component "Drift Endpoints" "KS Test, ApproxKS, FourierMMD, Meanshift" "/metrics/drift/*"
                explainerEndpoints = component "Explainer Endpoints" "LIME, SHAP, CF, TSSaliency, PDP (disabled in RHOAI)" "/explainers/*"
                consumerEndpoints = component "Consumer Endpoints" "Inference payload ingestion from ModelMesh and KServe" "/consumer/kserve/v2"
                cloudEventConsumer = component "CloudEvent Consumer" "Knative Funqy trigger for KServe inference events" "Funqy CloudEvents"
                prometheusScheduler = component "Prometheus Scheduler" "Scheduled metric computation and Micrometer gauge publication" "Quarkus Scheduler"
                dataSource = component "Data Source" "Strategy pattern: CSV (PVC/MinIO/Memory) or Hibernate (MariaDB/MySQL)" "Storage Abstraction"
                payloadReconcilers = component "Payload Reconcilers" "Match partial request/response payloads by inference ID" "CDI Beans"
            }

            core = container "explainability-core" "Core XAI algorithms: LIME, SHAP, Counterfactual, fairness metrics, drift detectors" "Java Library"
            connectors = container "explainability-connectors" "KServe v1/v2 HTTP and gRPC client adapters" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow IPC bridge for Java-Python data exchange" "Java Library"
        }

        trustyaiOperator = softwareSystem "TrustyAI Operator" "Deploys and configures TrustyAI service instances per namespace" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Inference serving platform with Knative eventing" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model inference serving" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "External"
        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for inference data persistence" "External"
        minio = softwareSystem "MinIO / S3" "S3-compatible object storage for inference data" "External"
        pvc = softwareSystem "Persistent Volume (PVC)" "Default file-based storage at /inputs" "Infrastructure"

        # Relationships - Users
        dataScientist -> trustyai "Configures fairness/drift monitoring, reviews metrics" "REST API / Dashboard"
        platformAdmin -> trustyaiOperator "Deploys TrustyAI instances" "kubectl / ArgoCD"

        # Relationships - Operator
        trustyaiOperator -> trustyai "Deploys, configures, injects kube-rbac-proxy sidecar" "Kubernetes API"

        # Relationships - Inbound
        modelMesh -> service "Sends inference payloads" "HTTP/8080 POST /consumer/kserve/v2"
        kserve -> service "Sends inference events" "HTTP/8080 CloudEvents (Knative)"

        # Relationships - Outbound
        service -> kserve "Calls model inference for explainers" "gRPC KServe v2 (plaintext)"
        service -> modelMesh "Calls model inference for explainers" "gRPC KServe v2 (plaintext)"

        # Relationships - Storage
        service -> mariadb "Persists inference data (DATABASE mode)" "JDBC/3306 plaintext"
        service -> minio "Persists inference data (MINIO mode)" "HTTPS/443 access key auth"
        service -> pvc "Persists inference data (PVC mode, default)" "Filesystem I/O /inputs"

        # Relationships - Monitoring
        prometheus -> service "Scrapes metrics" "HTTP/8080 GET /q/metrics (Bearer Token)"
        service -> prometheus "Publishes trustyai_* gauges" "Micrometer / Prometheus Registry"

        # Internal relationships
        service -> core "Uses fairness, drift, XAI algorithms" "Java Library"
        service -> connectors "Uses KServe v1/v2 adapters" "Java Library"
        connectors -> core "Uses data structures" "Java Library"
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
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #d4a574
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
