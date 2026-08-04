workspace {
    model {
        datascientist = person "Data Scientist" "Requests fairness, drift, and identity metrics for deployed ML models"
        sre = person "SRE / Platform Admin" "Monitors service health and metrics"

        trustyai = softwareSystem "TrustyAI Explainability Service" "Quarkus-based Java service providing model fairness, bias tracking, drift detection, and explainability for ML models on OpenShift AI" {
            restConsumer = container "REST Consumer Endpoint" "Receives ModelMesh inference partial payloads at /consumer/kserve/v2" "Quarkus REST"
            cloudEventConsumer = container "CloudEvent Consumer" "Receives KServe inference request/response CloudEvents via Knative Funqy" "Quarkus Funqy"
            mmReconciler = container "ModelMesh Payload Reconciler" "Matches input/output partial payloads by ID into complete inference records" "Java"
            ksReconciler = container "KServe Payload Reconciler" "Pairs CloudEvent request/response into complete inference records" "Java"
            metricsEndpoints = container "Metrics API" "Computes fairness (SPD, DIR), drift, and identity metrics from stored inference data" "Quarkus REST"
            storageLayer = container "Storage Layer" "Persists inference records to PVC or MariaDB via Hibernate ORM" "Java / Hibernate"
            prometheusExporter = container "Prometheus Exporter" "Publishes computed metrics at /q/metrics for Prometheus scraping" "Quarkus Micrometer"
            initContainer = container "Init Container" "Creates model-serving-config ConfigMap to register payload processor endpoint" "ose-cli"
        }

        kserveModelMesh = softwareSystem "KServe / ModelMesh" "Model serving infrastructure that sends inference payloads to TrustyAI" "Internal RHOAI"
        knative = softwareSystem "Knative Eventing" "Delivers CloudEvents from KServe inference servers" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Scrapes and stores metrics from TrustyAI" "Internal RHOAI"
        openshiftRoute = softwareSystem "OpenShift Route" "Exposes TrustyAI externally without TLS termination" "Platform"
        pvcStorage = softwareSystem "PVC Storage" "Persistent volume for inference data at /inputs" "Platform"
        mariadb = softwareSystem "MariaDB" "Optional relational database for inference data persistence" "External"

        # Relationships
        datascientist -> trustyai "Requests fairness/drift/identity metrics" "HTTP REST"
        datascientist -> openshiftRoute "Accesses TrustyAI API" "HTTP"
        openshiftRoute -> trustyai "Routes traffic to trustyai-service" "HTTP 80→8080"

        kserveModelMesh -> trustyai "Sends inference partial payloads" "HTTP POST /consumer/kserve/v2"
        knative -> trustyai "Delivers inference CloudEvents" "CloudEvents/HTTP"
        trustyai -> prometheus "Exposes metrics for scraping" "HTTP GET /q/metrics"
        sre -> prometheus "Views TrustyAI metrics" "Prometheus/Grafana"

        trustyai -> pvcStorage "Persists inference records" "Filesystem I/O"
        trustyai -> mariadb "Persists inference records (optional)" "JDBC / Hibernate ORM"

        # Internal relationships
        restConsumer -> mmReconciler "Forwards partial payloads"
        cloudEventConsumer -> ksReconciler "Forwards CloudEvent data"
        mmReconciler -> storageLayer "Writes merged records"
        ksReconciler -> storageLayer "Writes merged records"
        metricsEndpoints -> storageLayer "Reads inference data"
        metricsEndpoints -> prometheusExporter "Publishes computed metrics"
        initContainer -> kserveModelMesh "Registers payload processor via ConfigMap"
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
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #f5a623
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
