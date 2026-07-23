workspace {
    model {
        datascientist = person "Data Scientist" "Creates ML models, monitors fairness metrics, and reviews explainability results"
        platformadmin = person "Platform Admin" "Deploys and manages TrustyAI instances via the operator"

        trustyai = softwareSystem "TrustyAI Explainability" "Responsible AI component providing fairness metrics, drift detection, and explainability for ML models on RHOAI" {
            service = container "explainability-service" "Quarkus REST service providing fairness metrics, drift detection, data ingestion, and explainability APIs" "Java 17 / Quarkus 3.8.5"
            core = container "explainability-core" "XAI algorithm library: LIME, SHAP, Counterfactual (OptaPlanner), drift detection (KS-Test, Meanshift, Fourier MMD), fairness metrics (SPD, DIR)" "Java Library"
            connectors = container "explainability-connectors" "KServe V2 inference protocol connectors via gRPC and HTTP" "Java Library"
            arrow = container "explainability-arrow" "Apache Arrow data interchange for Python interoperability" "Java Library"

            service -> core "Uses algorithms" "In-process"
            service -> connectors "Calls model servers" "In-process"
            service -> arrow "Data interchange" "In-process"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI lifecycle: deploys instances, provisions TLS, creates ConfigMaps" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML model serving platform providing InferenceService resources" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform sending inference payloads to TrustyAI" "Internal RHOAI"
        knative = softwareSystem "Knative Eventing" "CloudEvent delivery for KServe inference events" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing data science projects, viewing fairness metrics" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting platform" "Internal RHOAI"

        minio = softwareSystem "MinIO / S3 Storage" "S3-compatible object storage for inference data" "External"
        mariadb = softwareSystem "MariaDB / MySQL" "Relational database for inference data storage" "External"
        k8sapi = softwareSystem "Kubernetes API Server" "Cluster API for ConfigMap management" "Infrastructure"

        # User interactions
        datascientist -> dashboard "Views fairness metrics, schedules bias monitoring" "HTTPS"
        datascientist -> trustyai "Requests fairness metrics, uploads ground truth data" "REST/HTTP 8080"
        platformadmin -> trustyaiOperator "Deploys TrustyAI instances" "kubectl/oc"

        # Inbound data flows
        modelmesh -> trustyai "Sends inference input/output payloads" "REST/HTTP 8080"
        knative -> trustyai "Delivers KServe inference CloudEvents" "HTTP CloudEvent 8080"
        prometheus -> trustyai "Scrapes /q/metrics for trustyai_spd, trustyai_dir gauges" "HTTP 8080"
        dashboard -> trustyai "Calls TrustyAI APIs for metrics display" "REST/HTTP 8080"

        # Outbound data flows
        trustyai -> kserve "Calls model servers for explainability (gRPC V2, disabled in RHOAI)" "gRPC plaintext"
        trustyai -> minio "Stores/retrieves inference data" "HTTP/HTTPS 443/9000"
        trustyai -> mariadb "Stores/retrieves inference data (Hibernate ORM)" "JDBC 3306"
        trustyai -> k8sapi "Creates/reads ConfigMaps (model-serving-config, trustyai-config)" "HTTPS 6443"

        # Operator management
        trustyaiOperator -> trustyai "Creates Deployments, Services, ConfigMaps, TLS Secrets per namespace" "Kubernetes API"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
