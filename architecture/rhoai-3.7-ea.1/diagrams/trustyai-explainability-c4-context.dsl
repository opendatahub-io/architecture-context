workspace "TrustyAI Explainability" "C4 model for the TrustyAI Java explainability service (RHOAI 3.7-ea.1)" {
    model {
        user = person "Data Scientist / ML Engineer" "Configures bias and drift monitoring for deployed models"

        trustyai = softwareSystem "TrustyAI Explainability Service" "Ingests inference payloads; computes fairness, drift and explainability metrics; publishes them to Prometheus" {
            service = container "trustyai-service" "Quarkus REST service: payload consumers, metrics API, scheduler, Prometheus publisher, explainers (ODH profile only)" "Java 17 / Quarkus 3.20.6.2"
            core = container "explainability-core" "LIME, SHAP, counterfactuals, PDP, TSSaliency; SPD, DIR, Meanshift, KS-test, Fourier MMD" "Java library"
            connectors = container "explainability-connectors" "KServe v1/v2 HTTP and v2 gRPC PredictionProvider clients" "Java library"
            arrow = container "explainability-arrow" "Apache Arrow bridge to the TrustyAI Python library" "Java library"
            storage = container "Storage" "MEMORY / PVC CSV / MINIO / DATABASE backends" "Hibernate ORM / flat file"
            rbacProxy = container "kube-rbac-proxy sidecars" "8443 user API (Bearer/SAR); 4443 internal proxy with ingestion paths unauthenticated" "Operator-injected sidecar" "Sidecar"
        }

        operator = softwareSystem "trustyai-service-operator" "Reconciles TrustyAIService CRs; injects sidecars, TLS and DB config" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "Payload processor pushes partial inference payloads" "Internal RHOAI"
        kserve = softwareSystem "KServe" "InferenceService logger sends CloudEvents; model servers answer explainer gRPC calls" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Bias/fairness metric configuration UI" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / User Workload Monitoring" "Scrapes trustyai_* gauges" "Internal RHOAI"
        pyService = softwareSystem "trustyai-service (Python)" "odh-trustyai-service-py; replaces this image in the 3.7 bundle" "Internal RHOAI"
        database = softwareSystem "MariaDB / MySQL" "Persistent storage for DATABASE format" "External"
        minio = softwareSystem "MinIO / S3" "Object storage for MINIO format" "External"
        k8s = softwareSystem "Kubernetes API" "ConfigMap writes by legacy init container" "External"

        user -> dashboard "Configures monitoring"
        user -> rbacProxy "Registers metric requests" "HTTPS/443→8443, Bearer"
        dashboard -> rbacProxy "Metric configuration" "HTTPS/443→8443, Bearer"
        modelmesh -> rbacProxy "POST /consumer/kserve/v2" "HTTPS/443→4443, no auth"
        kserve -> rbacProxy "CloudEvents inference request/response" "HTTPS/443→4443, no auth"
        rbacProxy -> service "Forwards requests" "HTTP/8080 localhost"
        prometheus -> service "Scrapes /q/metrics" "HTTP/8080"
        service -> core "Computes metrics and explanations"
        service -> connectors "Builds prediction providers"
        service -> storage "Persists and reads dataframes"
        connectors -> kserve "ModelInfer (explainers, ODH profile only)" "gRPC plaintext, user-specified port"
        storage -> database "JDBC" "3306/TCP, TLS verify-ca optional"
        storage -> minio "S3 API" "HTTP/HTTPS"
        operator -> trustyai "Deploys per namespace (historical; 3.7 deploys Python image)"
        trustyai -> k8s "oc apply model-serving-config (legacy init container)" "HTTPS/443"
        pyService -> trustyai "Supersedes in RHOAI 3.7-ea.1"
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
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #9cc3f0
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
